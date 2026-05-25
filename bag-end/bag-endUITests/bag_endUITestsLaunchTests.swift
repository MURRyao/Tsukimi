//
//  bag_endUITestsLaunchTests.swift
//  bag-endUITests
//
//  Created by dmitry on 23.05.2026.
//

import XCTest

final class bag_endUITestsLaunchTests: XCTestCase {

    override class var runsForEachTargetApplicationUIConfiguration: Bool {
        true
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testLaunch() throws {
        throw XCTSkip("Tsukimi is an LSUIElement menu-bar utility; launch screenshots need a custom menu-bar harness.")
    }
}
