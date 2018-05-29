import XCTest
@testable import Saber

final class SaberTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(Saber().text, "Hello, World!")
    }


    static var allTests = [
        ("testExample", testExample),
    ]
}
