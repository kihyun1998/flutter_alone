import Cocoa
import FlutterMacOS
import XCTest

@testable import flutter_alone

// Unit tests for the pure DuplicateMessage string table. This replaces the
// default template test, which called a getPlatformVersion method the plugin
// never implemented. The NSAlert presentation itself is UI and not unit-tested;
// only the (type, custom) -> (title, body) selection is.
class RunnerTests: XCTestCase {

  func testKoreanStrings() {
    XCTAssertEqual(DuplicateMessage.title(type: "ko", custom: ""), "알림")
    XCTAssertEqual(
      DuplicateMessage.body(type: "ko", custom: ""),
      "이미 다른 계정에서 앱을 실행중입니다.")
  }

  func testEnglishStrings() {
    XCTAssertEqual(DuplicateMessage.title(type: "en", custom: ""), "Notice")
    XCTAssertEqual(
      DuplicateMessage.body(type: "en", custom: ""),
      "Application is already running in another account.")
  }

  func testCustomStringsAreUsedWhenProvided() {
    XCTAssertEqual(
      DuplicateMessage.title(type: "custom", custom: "My Title"), "My Title")
    XCTAssertEqual(
      DuplicateMessage.body(type: "custom", custom: "My Message"), "My Message")
  }

  func testCustomFallsBackToEnglishWhenEmpty() {
    XCTAssertEqual(DuplicateMessage.title(type: "custom", custom: ""), "Notice")
    XCTAssertEqual(
      DuplicateMessage.body(type: "custom", custom: ""),
      "Application is already running in another account.")
  }

  func testUnknownTypeFallsBackToEnglish() {
    XCTAssertEqual(DuplicateMessage.title(type: "zz", custom: ""), "Notice")
    XCTAssertEqual(
      DuplicateMessage.body(type: "zz", custom: ""),
      "Application is already running in another account.")
  }
}
