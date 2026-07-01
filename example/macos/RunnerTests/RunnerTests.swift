import Cocoa
import FlutterMacOS
import XCTest

@testable import flutter_alone

// The dialog string table moved to Dart (single source of truth), so there is no
// pure Swift string logic left to unit-test. These tests instead pin the
// plugin's argument-handling contract on its public handle(_:result:) entry
// point, which is exercisable without touching the filesystem.
class RunnerTests: XCTestCase {

  private func invoke(_ method: String, arguments: Any?) -> Any? {
    let plugin = FlutterAlonePlugin()
    let call = FlutterMethodCall(methodName: method, arguments: arguments)
    var captured: Any?
    let done = expectation(description: "result delivered")
    plugin.handle(call) { result in
      captured = result
      done.fulfill()
    }
    waitForExpectations(timeout: 1)
    return captured
  }

  func testCheckAndRunWithoutLockFileNameReturnsError() {
    let result = invoke("checkAndRun", arguments: [String: Any]())
    XCTAssertTrue(result is FlutterError)
  }

  func testCheckAndRunWithNonMapArgumentsReturnsError() {
    let result = invoke("checkAndRun", arguments: nil)
    XCTAssertTrue(result is FlutterError)
  }
}
