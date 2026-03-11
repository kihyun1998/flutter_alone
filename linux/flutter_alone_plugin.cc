#include "include/flutter_alone/flutter_alone_plugin.h"

#include <flutter_linux/flutter_linux.h>
#include <gtk/gtk.h>

#include <cstring>
#include <string>
#include <fstream>
#include <sstream>
#include <cstdlib>

#include <sys/file.h>
#include <sys/stat.h>
#include <signal.h>
#include <unistd.h>

#ifdef HAVE_X11
#include <X11/Xlib.h>
#include <X11/Xatom.h>
#include <gdk/gdkx.h>
#endif

#define FLUTTER_ALONE_PLUGIN(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST((obj), flutter_alone_plugin_get_type(), \
                              FlutterAlonePlugin))

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

static pid_t read_pid_from_file(const std::string& path) {
  std::ifstream file(path);
  if (!file.is_open()) return -1;
  pid_t pid = -1;
  file >> pid;
  return pid;
}

static bool is_process_running(pid_t pid) {
  if (pid <= 0) return false;
  return kill(pid, 0) == 0;
}

static bool write_pid_to_file(const std::string& path, pid_t pid) {
  std::ofstream file(path, std::ios::trunc);
  if (!file.is_open()) return false;
  file << pid;
  file.close();
  return true;
}

// ============================================================
// X11 window activation
// ============================================================

#ifdef HAVE_X11

static bool is_x11_session() {
  const char* session_type = getenv("XDG_SESSION_TYPE");
  if (session_type && strcmp(session_type, "x11") == 0) return true;

  // Also check if GDK is using X11 backend
  GdkDisplay* display = gdk_display_get_default();
  if (display && GDK_IS_X11_DISPLAY(display)) return true;

  return false;
}

static Window find_window_by_pid(Display* display, Window root, pid_t target_pid) {
  Atom pid_atom = XInternAtom(display, "_NET_WM_PID", True);
  if (pid_atom == None) return None;

  Atom actual_type;
  int actual_format;
  unsigned long nitems, bytes_after;
  unsigned char* prop_data = nullptr;

  // Get list of all top-level windows
  Atom client_list_atom = XInternAtom(display, "_NET_CLIENT_LIST", True);
  if (client_list_atom == None) return None;

  if (XGetWindowProperty(display, root, client_list_atom,
                         0, 1024, False, XA_WINDOW,
                         &actual_type, &actual_format,
                         &nitems, &bytes_after, &prop_data) != Success) {
    return None;
  }

  if (!prop_data) return None;

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
        pid_t window_pid = static_cast<pid_t>(*reinterpret_cast<unsigned long*>(pid_data));
        if (window_pid == target_pid) {
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

  // Send _NET_ACTIVE_WINDOW client message to activate the window
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
    event.xclient.data.l[0] = 2;  // Source: pager
    event.xclient.data.l[1] = CurrentTime;
    event.xclient.data.l[2] = 0;

    XSendEvent(display, root, False,
               SubstructureRedirectMask | SubstructureNotifyMask,
               &event);

    // Also raise and map the window
    XMapRaised(display, target);
    XFlush(display);
  }

  XCloseDisplay(display);
  return true;
}

#endif  // HAVE_X11

// ============================================================
// Wayland window activation (best-effort via gdbus)
// ============================================================

static bool activate_window_wayland(pid_t target_pid) {
  // On Wayland, direct window activation from another process is restricted.
  // Try using gdbus to call GNOME Shell or KDE's activation interface.
  // This is best-effort - if it fails, the dialog will still inform the user.

  // Try GNOME Shell's activation via wmctrl (works on XWayland)
  char cmd[256];
  snprintf(cmd, sizeof(cmd),
           "wmctrl -i -a $(wmctrl -l -p | awk '$3 == %d {print $1; exit}') 2>/dev/null",
           static_cast<int>(target_pid));

  int ret = system(cmd);
  if (ret == 0) return true;

  // Try xdotool as fallback (may work on XWayland)
  snprintf(cmd, sizeof(cmd),
           "xdotool search --pid %d --onlyvisible windowactivate 2>/dev/null",
           static_cast<int>(target_pid));

  ret = system(cmd);
  return (ret == 0);
}

// ============================================================
// Activate existing instance window
// ============================================================

static bool activate_existing_window(pid_t target_pid) {
#ifdef HAVE_X11
  if (is_x11_session()) {
    if (activate_window_x11(target_pid)) return true;
  }
#endif
  // Fallback: try Wayland methods (wmctrl/xdotool via XWayland)
  return activate_window_wayland(target_pid);
}

// ============================================================
// GTK message dialog
// ============================================================

static void show_message_dialog(const gchar* title, const gchar* message, gboolean show) {
  if (!show) return;

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
// Message utilities (same as Windows/macOS)
// ============================================================

static const gchar* get_title_for_type(const gchar* type, const gchar* custom_title) {
  if (strcmp(type, "ko") == 0) return "알림";
  if (strcmp(type, "en") == 0) return "Notice";
  if (strcmp(type, "custom") == 0 && custom_title && strlen(custom_title) > 0) return custom_title;
  return "Notice";
}

static const gchar* get_message_for_type(const gchar* type, const gchar* custom_message) {
  if (strcmp(type, "ko") == 0) return "이미 다른 계정에서 앱을 실행중입니다.";
  if (strcmp(type, "en") == 0) return "Application is already running in another account.";
  if (strcmp(type, "custom") == 0 && custom_message && strlen(custom_message) > 0) return custom_message;
  return "Application is already running in another account.";
}

// ============================================================
// Method call handler
// ============================================================

static void flutter_alone_plugin_handle_method_call(
    FlutterAlonePlugin* self,
    FlMethodCall* method_call) {
  g_autoptr(FlMethodResponse) response = nullptr;
  const gchar* method = fl_method_call_get_name(method_call);

  if (strcmp(method, "checkAndRun") == 0) {
    FlValue* args = fl_method_call_get_args(method_call);
    if (fl_value_get_type(args) != FL_VALUE_TYPE_MAP) {
      response = FL_METHOD_RESPONSE(fl_method_error_response_new(
          "INVALID_ARGUMENT", "Arguments are required", nullptr));
      fl_method_call_respond(method_call, response, nullptr);
      return;
    }

    // Get lockFileName
    FlValue* lock_file_value = fl_value_lookup_string(args, "lockFileName");
    if (!lock_file_value || fl_value_get_type(lock_file_value) == FL_VALUE_TYPE_NULL) {
      response = FL_METHOD_RESPONSE(fl_method_error_response_new(
          "INVALID_ARGUMENT", "lockFileName is required for Linux", nullptr));
      fl_method_call_respond(method_call, response, nullptr);
      return;
    }
    const gchar* lock_file_name = fl_value_get_string(lock_file_value);

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

    // Store lock file path for dispose
    g_free(self->lock_file_path);
    self->lock_file_path = g_strdup(lock_path.c_str());

    // Check if another instance is running
    pid_t existing_pid = read_pid_from_file(lock_path);
    pid_t current_pid = getpid();

    if (existing_pid > 0 && existing_pid != current_pid && is_process_running(existing_pid)) {
      // Another instance is running - try to activate its window
      bool activated = activate_existing_window(existing_pid);

      if (!activated) {
        // Could not activate window - show message dialog
        const gchar* title = get_title_for_type(type, custom_title);
        const gchar* message = get_message_for_type(type, custom_message);
        show_message_dialog(title, message, show_message_box);
      }

      g_autoptr(FlValue) result = fl_value_new_bool(FALSE);
      response = FL_METHOD_RESPONSE(fl_method_success_response_new(result));
      fl_method_call_respond(method_call, response, nullptr);
      return;
    }

    // No existing instance (or stale lock file) - write our PID
    bool written = write_pid_to_file(lock_path, current_pid);

    g_autoptr(FlValue) result = fl_value_new_bool(written ? TRUE : FALSE);
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(result));

  } else if (strcmp(method, "dispose") == 0) {
    // Clean up lock file
    if (self->lock_file_path) {
      unlink(self->lock_file_path);
      g_free(self->lock_file_path);
      self->lock_file_path = nullptr;
    }
    if (self->lock_fd > 0) {
      close(self->lock_fd);
      self->lock_fd = -1;
    }
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(nullptr));

  } else {
    response = FL_METHOD_RESPONSE(fl_method_not_implemented_response_new());
  }

  fl_method_call_respond(method_call, response, nullptr);
}

// ============================================================
// Plugin lifecycle
// ============================================================

static void flutter_alone_plugin_dispose(GObject* object) {
  FlutterAlonePlugin* self = FLUTTER_ALONE_PLUGIN(object);

  // Clean up lock file on dispose
  if (self->lock_file_path) {
    unlink(self->lock_file_path);
    g_free(self->lock_file_path);
    self->lock_file_path = nullptr;
  }
  if (self->lock_fd > 0) {
    close(self->lock_fd);
    self->lock_fd = -1;
  }

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
                            "flutter_alone",
                            FL_METHOD_CODEC(codec));
  fl_method_channel_set_method_call_handler(channel, method_call_cb,
                                            g_object_ref(plugin),
                                            g_object_unref);

  g_object_unref(plugin);
}
