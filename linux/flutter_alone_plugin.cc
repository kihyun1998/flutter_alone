#include "include/flutter_alone/flutter_alone_plugin.h"

#include <flutter_linux/flutter_linux.h>
#include <gtk/gtk.h>

#include <cstring>
#include <string>
#include <fstream>
#include <sstream>
#include <cstdlib>
#include <cerrno>

#include <sys/file.h>
#include <sys/stat.h>
#include <sys/wait.h>
#include <signal.h>
#include <unistd.h>
#include <fcntl.h>
#include <spawn.h>

#ifdef HAVE_X11
#include <X11/Xlib.h>
#include <X11/Xatom.h>
#include <gdk/gdkx.h>
#endif

#define FLUTTER_ALONE_PLUGIN(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST((obj), flutter_alone_plugin_get_type(), \
                              FlutterAlonePlugin))

static constexpr char kChannelName[] = "flutter_alone";
static constexpr char kMethodCheckAndRun[] = "checkAndRun";
static constexpr char kMethodDispose[] = "dispose";

struct _FlutterAlonePlugin {
  GObject parent_instance;
  gchar* lock_file_path;
  int lock_fd;
};

G_DEFINE_TYPE(FlutterAlonePlugin, flutter_alone_plugin, g_object_get_type())

// ============================================================
// Lock file helpers
// ============================================================

static std::string get_lock_file_path(const gchar* lock_file_name) {
  const gchar* tmp_dir = g_get_tmp_dir();
  return std::string(tmp_dir) + "/" + lock_file_name;
}

// Read PID from an already-opened file descriptor (avoids re-open TOCTOU)
static pid_t read_pid_from_fd(int fd) {
  char buf[32];
  if (lseek(fd, 0, SEEK_SET) != 0) return -1;
  ssize_t n = read(fd, buf, sizeof(buf) - 1);
  if (n <= 0) return -1;
  buf[n] = '\0';
  char* end = nullptr;
  long pid = strtol(buf, &end, 10);
  if (end == buf || pid <= 0) return -1;
  return static_cast<pid_t>(pid);
}

static bool is_process_running(pid_t pid) {
  if (pid <= 0) return false;
  if (kill(pid, 0) == 0) return true;
  // errno == EPERM means the process exists but we lack permission (cross-user)
  if (errno == EPERM) return true;
  return false;
}

// Verify process identity by checking /proc/<pid>/exe
static bool is_same_executable(pid_t pid) {
  char self_path[PATH_MAX];
  char target_path[PATH_MAX];

  ssize_t self_len = readlink("/proc/self/exe", self_path, sizeof(self_path) - 1);
  if (self_len < 0) return false;
  self_path[self_len] = '\0';

  // "/proc/<max-pid>/exe" fits well within 64 chars
  char proc_path[64];
  snprintf(proc_path, sizeof(proc_path), "/proc/%d/exe", static_cast<int>(pid));
  ssize_t target_len = readlink(proc_path, target_path, sizeof(target_path) - 1);
  if (target_len < 0) return false;
  target_path[target_len] = '\0';

  return strcmp(self_path, target_path) == 0;
}

// Overwrites fd content with the decimal PID.
// fd must be open for write and advisory-locked by the caller.
static bool write_pid_to_fd(int fd, pid_t pid) {
  if (ftruncate(fd, 0) != 0) return false;
  if (lseek(fd, 0, SEEK_SET) != 0) return false;

  std::string pid_str = std::to_string(pid);
  ssize_t written = write(fd, pid_str.c_str(), pid_str.length());
  if (written < 0 || static_cast<size_t>(written) != pid_str.length()) return false;

  fdatasync(fd);
  return true;
}

// ============================================================
// X11 window activation
// ============================================================

#ifdef HAVE_X11

static bool is_x11_session() {
  const char* session_type = getenv("XDG_SESSION_TYPE");
  if (session_type && strcmp(session_type, "x11") == 0) return true;

  GdkDisplay* display = gdk_display_get_default();
  if (display && GDK_IS_X11_DISPLAY(display)) return true;

  return false;
}

static constexpr long kMaxClientListItems = 4096;

static Window find_window_by_pid(Display* display, Window root, pid_t target_pid) {
  Atom pid_atom = XInternAtom(display, "_NET_WM_PID", True);
  if (pid_atom == None) return None;

  Atom actual_type;
  int actual_format;
  unsigned long nitems, bytes_after;
  unsigned char* prop_data = nullptr;

  Atom client_list_atom = XInternAtom(display, "_NET_CLIENT_LIST", True);
  if (client_list_atom == None) return None;

  if (XGetWindowProperty(display, root, client_list_atom,
                         0, kMaxClientListItems, False, XA_WINDOW,
                         &actual_type, &actual_format,
                         &nitems, &bytes_after, &prop_data) != Success) {
    return None;
  }

  if (!prop_data) return None;

  if (bytes_after > 0) {
    g_warning("flutter_alone: _NET_CLIENT_LIST truncated, %lu bytes remaining", bytes_after);
  }

  Window* windows = reinterpret_cast<Window*>(prop_data);
  Window found = None;

  for (unsigned long i = 0; i < nitems; i++) {
    unsigned char* pid_data = nullptr;
    Atom pid_actual_type;
    int pid_actual_format;
    unsigned long pid_nitems, pid_bytes_after;

    if (XGetWindowProperty(display, windows[i], pid_atom,
                           0, 1, False, XA_CARDINAL,
                           &pid_actual_type, &pid_actual_format,
                           &pid_nitems, &pid_bytes_after, &pid_data) == Success) {
      if (pid_data && pid_nitems > 0) {
        uint32_t window_pid = 0;
        memcpy(&window_pid, pid_data, sizeof(uint32_t));
        if (static_cast<pid_t>(window_pid) == target_pid) {
          found = windows[i];
          XFree(pid_data);
          break;
        }
        XFree(pid_data);
      }
    }
  }

  XFree(prop_data);
  return found;
}

static bool activate_window_x11(pid_t target_pid) {
  Display* display = XOpenDisplay(nullptr);
  if (!display) return false;

  Window root = DefaultRootWindow(display);
  Window target = find_window_by_pid(display, root, target_pid);

  if (target == None) {
    XCloseDisplay(display);
    return false;
  }

  Atom active_atom = XInternAtom(display, "_NET_ACTIVE_WINDOW", True);
  if (active_atom != None) {
    XEvent event;
    memset(&event, 0, sizeof(event));
    event.xclient.type = ClientMessage;
    event.xclient.serial = 0;
    event.xclient.send_event = True;
    event.xclient.display = display;
    event.xclient.window = target;
    event.xclient.message_type = active_atom;
    event.xclient.format = 32;
    // Source indication: 2 = pager (EWMH spec _NET_ACTIVE_WINDOW)
    event.xclient.data.l[0] = 2;
    event.xclient.data.l[1] = CurrentTime;
    event.xclient.data.l[2] = 0;

    XSendEvent(display, root, False,
               SubstructureRedirectMask | SubstructureNotifyMask,
               &event);

    XMapRaised(display, target);
    XFlush(display);
  }

  XCloseDisplay(display);
  return true;
}

#endif  // HAVE_X11

// ============================================================
// Wayland window activation (best-effort via xdotool on XWayland)
// Uses posix_spawn instead of system() to avoid shell injection.
// ============================================================

extern char **environ;

static bool run_command(const char* prog, char* const argv[]) {
  pid_t child_pid;
  int status;

  posix_spawn_file_actions_t actions;
  posix_spawn_file_actions_init(&actions);

  if (posix_spawn_file_actions_addopen(&actions, STDOUT_FILENO, "/dev/null", O_WRONLY, 0) != 0 ||
      posix_spawn_file_actions_addopen(&actions, STDERR_FILENO, "/dev/null", O_WRONLY, 0) != 0) {
    posix_spawn_file_actions_destroy(&actions);
    return false;
  }

  int ret = posix_spawnp(&child_pid, prog, &actions, nullptr, argv, environ);
  posix_spawn_file_actions_destroy(&actions);

  if (ret != 0) return false;

  waitpid(child_pid, &status, 0);
  return WIFEXITED(status) && WEXITSTATUS(status) == 0;
}

static bool activate_window_wayland(pid_t target_pid) {
  std::string pid_str = std::to_string(static_cast<int>(target_pid));

  // Do NOT pass --onlyvisible: a tray-minimized / hidden main window must still
  // be reachable so it can be activated (xdotool's windowactivate maps it back).
  // --limit 1 avoids activating multiple helper windows belonging to the same PID.
  char* argv[] = {
    const_cast<char*>("xdotool"),
    const_cast<char*>("search"),
    const_cast<char*>("--pid"),
    const_cast<char*>(pid_str.c_str()),
    const_cast<char*>("--limit"),
    const_cast<char*>("1"),
    const_cast<char*>("windowactivate"),
    nullptr
  };
  return run_command("xdotool", argv);
}

static bool activate_existing_window(pid_t target_pid) {
#ifdef HAVE_X11
  if (is_x11_session()) {
    if (activate_window_x11(target_pid)) return true;
  }
#endif
  return activate_window_wayland(target_pid);
}

// ============================================================
// GTK message dialog
// ============================================================

// Intentionally synchronous: the dialog blocks before the app exits.
static void show_message_dialog(const gchar* title, const gchar* message, gboolean should_show) {
  if (!should_show) return;

  GtkWidget* dialog = gtk_message_dialog_new(
      nullptr,
      GTK_DIALOG_MODAL,
      GTK_MESSAGE_INFO,
      GTK_BUTTONS_OK,
      "%s", message);

  gtk_window_set_title(GTK_WINDOW(dialog), title);
  gtk_dialog_run(GTK_DIALOG(dialog));
  gtk_widget_destroy(dialog);
}

// ============================================================
// Message utilities
// ============================================================

static const gchar* get_localized_string(const gchar* locale_key,
                                          const gchar* ko_str,
                                          const gchar* en_str,
                                          const gchar* custom_str) {
  if (strcmp(locale_key, "ko") == 0) return ko_str;
  if (strcmp(locale_key, "en") == 0) return en_str;
  if (strcmp(locale_key, "custom") == 0 && custom_str && strlen(custom_str) > 0) return custom_str;
  return en_str;
}

static const gchar* get_title_for_type(const gchar* type, const gchar* custom_title) {
  return get_localized_string(type, "\xEC\x95\x8C\xEB\xA6\xBC", "Notice", custom_title);
}

static const gchar* get_message_for_type(const gchar* type, const gchar* custom_message) {
  return get_localized_string(type,
      "\xEC\x9D\xB4\xEB\xAF\xB8 \xEB\x8B\xA4\xEB\xA5\xB8 \xEA\xB3\x84\xEC\xA0\x95\xEC\x97\x90\xEC\x84\x9C \xEC\x95\xB1\xEC\x9D\x84 \xEC\x8B\xA4\xED\x96\x89\xEC\xA4\x91\xEC\x9E\x85\xEB\x8B\x88\xEB\x8B\xA4.",
      "Application is already running in another account.",
      custom_message);
}

// Show "already running" notification dialog
static void notify_already_running(const gchar* type, const gchar* custom_title,
                                    const gchar* custom_message, gboolean show_message_box) {
  const gchar* title = get_title_for_type(type, custom_title);
  const gchar* message = get_message_for_type(type, custom_message);
  show_message_dialog(title, message, show_message_box);
}

// ============================================================
// Lock cleanup helper (shared between dispose handler and GObject dispose)
// ============================================================

static void release_lock(FlutterAlonePlugin* self) {
  if (self->lock_fd >= 0) {
    if (flock(self->lock_fd, LOCK_UN) != 0) {
      g_warning("flutter_alone: flock LOCK_UN failed: errno %d", errno);
    }
    close(self->lock_fd);
    self->lock_fd = -1;
  }
  if (self->lock_file_path) {
    if (unlink(self->lock_file_path) != 0 && errno != ENOENT) {
      g_warning("flutter_alone: unlink failed for %s: errno %d", self->lock_file_path, errno);
    }
    g_free(self->lock_file_path);
    self->lock_file_path = nullptr;
  }
}

// ============================================================
// Method call handler
// ============================================================

static void handle_check_and_run(FlutterAlonePlugin* self, FlValue* args, FlMethodCall* method_call) {
  g_autoptr(FlMethodResponse) response = nullptr;

  // Get lockFileName
  FlValue* lock_file_value = fl_value_lookup_string(args, "lockFileName");
  if (!lock_file_value || fl_value_get_type(lock_file_value) == FL_VALUE_TYPE_NULL) {
    response = FL_METHOD_RESPONSE(fl_method_error_response_new(
        "INVALID_ARGUMENT", "lockFileName is required for Linux", nullptr));
    fl_method_call_respond(method_call, response, nullptr);
    return;
  }
  const gchar* lock_file_name = fl_value_get_string(lock_file_value);

  // Validate lockFileName: no path separators, not empty, not "." or ".."
  if (strchr(lock_file_name, '/') != nullptr ||
      strlen(lock_file_name) == 0 ||
      strcmp(lock_file_name, ".") == 0 ||
      strcmp(lock_file_name, "..") == 0) {
    response = FL_METHOD_RESPONSE(fl_method_error_response_new(
        "INVALID_ARGUMENT", "lockFileName must be a simple filename without path separators", nullptr));
    fl_method_call_respond(method_call, response, nullptr);
    return;
  }

  // Get message config
  FlValue* type_value = fl_value_lookup_string(args, "type");
  const gchar* type = type_value ? fl_value_get_string(type_value) : "en";

  FlValue* show_msg_value = fl_value_lookup_string(args, "showMessageBox");
  gboolean show_message_box = show_msg_value ? fl_value_get_bool(show_msg_value) : TRUE;

  FlValue* custom_title_value = fl_value_lookup_string(args, "customTitle");
  const gchar* custom_title = (custom_title_value && fl_value_get_type(custom_title_value) != FL_VALUE_TYPE_NULL)
      ? fl_value_get_string(custom_title_value) : "";

  FlValue* custom_message_value = fl_value_lookup_string(args, "customMessage");
  const gchar* custom_message = (custom_message_value && fl_value_get_type(custom_message_value) != FL_VALUE_TYPE_NULL)
      ? fl_value_get_string(custom_message_value) : "";

  // Build lock file path
  std::string lock_path = get_lock_file_path(lock_file_name);

  g_free(self->lock_file_path);
  self->lock_file_path = g_strdup(lock_path.c_str());

  // Open lock file with O_NOFOLLOW to prevent symlink attacks
  int fd = open(lock_path.c_str(), O_CREAT | O_RDWR | O_NOFOLLOW, 0644);
  if (fd < 0) {
    response = FL_METHOD_RESPONSE(fl_method_error_response_new(
        "IO_ERROR", "Failed to open lock file", nullptr));
    fl_method_call_respond(method_call, response, nullptr);
    return;
  }

  // Try to acquire exclusive advisory lock (non-blocking)
  if (flock(fd, LOCK_EX | LOCK_NB) != 0) {
    // Read PID from the already-opened fd to avoid re-open TOCTOU
    pid_t existing_pid = read_pid_from_fd(fd);
    close(fd);

    if (existing_pid > 0 && is_process_running(existing_pid) && is_same_executable(existing_pid)) {
      bool activated = activate_existing_window(existing_pid);
      if (!activated) {
        notify_already_running(type, custom_title, custom_message, show_message_box);
      }
    } else {
      notify_already_running(type, custom_title, custom_message, show_message_box);
    }

    g_autoptr(FlValue) result = fl_value_new_bool(FALSE);
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(result));
    fl_method_call_respond(method_call, response, nullptr);
    return;
  }

  // We hold the lock. Write our PID.
  pid_t current_pid = getpid();
  if (!write_pid_to_fd(fd, current_pid)) {
    flock(fd, LOCK_UN);
    close(fd);
    response = FL_METHOD_RESPONSE(fl_method_error_response_new(
        "IO_ERROR", "Failed to write PID to lock file", nullptr));
    fl_method_call_respond(method_call, response, nullptr);
    return;
  }

  // Keep fd open for the lifetime of the plugin
  self->lock_fd = fd;

  g_autoptr(FlValue) result = fl_value_new_bool(TRUE);
  response = FL_METHOD_RESPONSE(fl_method_success_response_new(result));
  fl_method_call_respond(method_call, response, nullptr);
}

static void flutter_alone_plugin_handle_method_call(
    FlutterAlonePlugin* self,
    FlMethodCall* method_call) {
  const gchar* method = fl_method_call_get_name(method_call);

  if (strcmp(method, kMethodCheckAndRun) == 0) {
    FlValue* args = fl_method_call_get_args(method_call);
    if (fl_value_get_type(args) != FL_VALUE_TYPE_MAP) {
      g_autoptr(FlMethodResponse) response = FL_METHOD_RESPONSE(fl_method_error_response_new(
          "INVALID_ARGUMENT", "Arguments are required", nullptr));
      fl_method_call_respond(method_call, response, nullptr);
      return;
    }
    handle_check_and_run(self, args, method_call);

  } else if (strcmp(method, kMethodDispose) == 0) {
    release_lock(self);
    g_autoptr(FlMethodResponse) response = FL_METHOD_RESPONSE(fl_method_success_response_new(nullptr));
    fl_method_call_respond(method_call, response, nullptr);

  } else {
    g_autoptr(FlMethodResponse) response = FL_METHOD_RESPONSE(fl_method_not_implemented_response_new());
    fl_method_call_respond(method_call, response, nullptr);
  }
}

// ============================================================
// Plugin lifecycle
// ============================================================

static void flutter_alone_plugin_dispose(GObject* object) {
  FlutterAlonePlugin* self = FLUTTER_ALONE_PLUGIN(object);
  release_lock(self);
  G_OBJECT_CLASS(flutter_alone_plugin_parent_class)->dispose(object);
}

static void flutter_alone_plugin_class_init(FlutterAlonePluginClass* klass) {
  G_OBJECT_CLASS(klass)->dispose = flutter_alone_plugin_dispose;
}

static void flutter_alone_plugin_init(FlutterAlonePlugin* self) {
  self->lock_file_path = nullptr;
  self->lock_fd = -1;
}

static void method_call_cb(FlMethodChannel* channel, FlMethodCall* method_call,
                           gpointer user_data) {
  FlutterAlonePlugin* plugin = FLUTTER_ALONE_PLUGIN(user_data);
  flutter_alone_plugin_handle_method_call(plugin, method_call);
}

void flutter_alone_plugin_register_with_registrar(FlPluginRegistrar* registrar) {
  FlutterAlonePlugin* plugin = FLUTTER_ALONE_PLUGIN(
      g_object_new(flutter_alone_plugin_get_type(), nullptr));

  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  g_autoptr(FlMethodChannel) channel =
      fl_method_channel_new(fl_plugin_registrar_get_messenger(registrar),
                            kChannelName,
                            FL_METHOD_CODEC(codec));
  fl_method_channel_set_method_call_handler(channel, method_call_cb,
                                            g_object_ref(plugin),
                                            g_object_unref);

  g_object_unref(plugin);
}
