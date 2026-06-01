//
//  BirdWatch_Watch_AppUITests.swift
//  BirdWatch Watch AppUITests
//
//  Created by Ryan Brunk on 5/19/26.
//

import XCTest

final class BirdWatch_Watch_AppUITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    @MainActor
    func testActiveChecklistViewLayout() throws {
        let app = XCUIApplication()
        app.launchArguments.append("--mock-data")
        app.launch()
        
        // 1. Verify pinned Add Bird button exists at launch
        let addBirdButton = app.buttons["Add Bird"]
        XCTAssertTrue(addBirdButton.waitForExistence(timeout: 5), "Pinned 'Add Bird' button should exist")
        
        // 2. Verify that the Sighting row displays the Common Name (e.g., 'Black-capped Chickadee')
        // AND the Alpha Code (e.g., 'BCCH')
        let commonNameText = app.staticTexts["Black-capped Chickadee"]
        XCTAssertTrue(commonNameText.exists, "Common name should be visible")
        
        let alphaCodeText = app.staticTexts["BCCH"]
        XCTAssertTrue(alphaCodeText.exists, "Alpha Code 'BCCH' should be visible in the Sighting rows")
        
        // 3. Verify that the 'End Checklist' button exists
        let endChecklistButton = app.buttons["End Checklist"]
        XCTAssertTrue(endChecklistButton.exists, "'End Checklist' button should exist at the bottom")
    }

    @MainActor
    func testActiveChecklistViewEmptyState() throws {
        let app = XCUIApplication()
        app.launchArguments.append("--empty-checklist")
        app.launch()
        
        // Now in empty ActiveChecklistView directly
        // 1. Pinned Add Bird should exist
        let addBirdButton = app.buttons["Add Bird"]
        XCTAssertTrue(addBirdButton.waitForExistence(timeout: 5))
        
        // 2. Add First Bird should NOT exist (removed)
        let addFirstBirdButton = app.buttons["Add First Bird"]
        XCTAssertFalse(addFirstBirdButton.exists, "'Add First Bird' button should be removed from empty state")
        
        // 3. Discard Checklist should exist
        let discardButton = app.buttons["Discard Checklist"]
        XCTAssertTrue(discardButton.exists, "'Discard Checklist' button should be preserved in empty state")
    }
    
    @MainActor
    func testActiveChecklistDiscardFlow() throws {
        let app = XCUIApplication()
        app.launchArguments.append("--mock-data")
        app.launch()
        
        // 1. Tap "End Checklist" button (visible on short mock checklist, no swipe needed)
        let endChecklistButton = app.buttons["End Checklist"]
        XCTAssertTrue(endChecklistButton.waitForExistence(timeout: 5))
        endChecklistButton.tap()
        
        // Wait for first dialog to present
        Thread.sleep(forTimeInterval: 1.0)
        
        // 2. In confirmation dialog, check that "Discard Checklist" exists, scroll sheet, and tap it
        let discardChecklistButton = app.buttons["Discard Checklist"]
        XCTAssertTrue(discardChecklistButton.waitForExistence(timeout: 5))
        app.swipeUp()
        
        // Wait for swipe animation to finish
        Thread.sleep(forTimeInterval: 0.5)
        
        discardChecklistButton.tap()
        
        // Wait for first dialog to dismiss and second to present
        Thread.sleep(forTimeInterval: 1.0)
        
        // 3. In second dialog, check that "Discard & Delete" exists and tap it
        let discardDeleteButton = app.buttons["Discard & Delete"]
        XCTAssertTrue(discardDeleteButton.waitForExistence(timeout: 5))
        discardDeleteButton.tap()
        
        // Wait for second dialog to dismiss and dashboard to load
        Thread.sleep(forTimeInterval: 1.0)
        
        // 4. Verify we returned to the Home Dashboard (Start Checklist button exists)
        let startChecklistButton = app.staticTexts["Start Checklist"]
        XCTAssertTrue(startChecklistButton.waitForExistence(timeout: 5))
    }
}

