import Foundation

// Pure, UI-free selection of the "already running" dialog text.
//
// Mirrors the Windows (message_utils.cpp) and Linux (get_localized_string)
// string tables so the three desktop platforms stay in sync. Kept free of
// Cocoa and Flutter so it can be unit-tested without a UI session.
enum DuplicateMessage {
  // English defaults, shared by the "en" and empty-custom fallbacks.
  static let defaultTitle = "Notice"
  static let defaultBody = "Application is already running in another account."

  /// Dialog title for the given message [type] ("ko" / "en" / "custom").
  static func title(type: String, custom: String) -> String {
    switch type {
    case "ko":
      return "알림"
    case "custom":
      return custom.isEmpty ? defaultTitle : custom
    default:
      return defaultTitle
    }
  }

  /// Dialog body for the given message [type] ("ko" / "en" / "custom").
  static func body(type: String, custom: String) -> String {
    switch type {
    case "ko":
      return "이미 다른 계정에서 앱을 실행중입니다."
    case "custom":
      return custom.isEmpty ? defaultBody : custom
    default:
      return defaultBody
    }
  }
}
