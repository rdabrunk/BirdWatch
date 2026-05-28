//
//  ProfileTests.swift
//  BirdWatch Watch AppTests
//

import Testing
import SwiftData
import Foundation
@testable import BirdWatch_Watch_App

struct ProfileTests {
    
    @Test func testArrayRawRepresentable() async throws {
        // GIVEN
        let profiles = ["Home", "Central Park", "Magee Marsh"]
        
        // WHEN
        let encoded = profiles.rawValue
        
        // THEN
        #expect(!encoded.isEmpty)
        
        // WHEN
        let decoded = [String](rawValue: encoded)
        
        // THEN
        #expect(decoded == profiles)
        
        // Test corrupt JSON string decodes to nil
        let corruptDecoded = [String](rawValue: "{invalid-json}")
        #expect(corruptDecoded == nil)
    }
    
    @MainActor
    @Test func testChecklistDisplayLocationName() async throws {
        let schema = Schema([Checklist.self, Sighting.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        
        // 1. GIVEN no custom location and no coordinates
        let checklist1 = Checklist(startTime: Date())
        container.mainContext.insert(checklist1)
        #expect(checklist1.displayLocationName == "My Location")
        
        // 2. GIVEN no custom location and coordinates available
        let checklist2 = Checklist(startTime: Date(), trackLocation: true)
        checklist2.latitude = 37.774912
        checklist2.longitude = -122.419415
        container.mainContext.insert(checklist2)
        #expect(checklist2.displayLocationName == "37.7749, -122.4194")
        
        // 3. GIVEN a custom location name
        let checklist3 = Checklist(startTime: Date())
        checklist3.customLocationName = "Home Sweet Home"
        container.mainContext.insert(checklist3)
        #expect(checklist3.displayLocationName == "Home Sweet Home")
    }
}
