//
//  BirdWatch_Watch_AppTests.swift
//  BirdWatch Watch AppTests
//
//  Created by Ryan Brunk on 5/19/26.
//

import Testing
import SwiftData
import Foundation
import CoreLocation
@testable import BirdWatch_Watch_App

struct BirdWatch_Watch_AppTests {

    @MainActor
    @Test func testTaxonRegistryLoading() async throws {
        let registry = TaxonRegistry()
        #expect(registry.isLoaded == false)
        #expect(registry.sortedTaxons.isEmpty)
        
        registry.load()
        
        #expect(registry.isLoaded == true)
        #expect(registry.sortedTaxons.count > 0)
        
        // Ensure "BCCH" (Black-capped Chickadee) is correctly parsed
        let chickadee = registry.taxon(forAlphaCode: "BCCH")
        #expect(chickadee != nil)
        #expect(chickadee?.commonName == "Black-capped Chickadee")
    }
    
    @MainActor
    @Test func testChecklistSessionCoordinator() async throws {
        // Use an in-memory ModelContainer for isolated testing
        let schema = Schema([Checklist.self, Sighting.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        
        let session = ChecklistSession(modelContext: container.mainContext)
        #expect(session.activeChecklist == nil)
        
        // 1. Start session
        session.startNewSession()
        #expect(session.activeChecklist != nil)
        
        let checklist = session.activeChecklist!
        
        // 2. Add a Sighting
        let mockTaxon = Taxon(alphaCode: "BCCH", commonName: "Black-capped Chickadee", scientificName: "Poecile atricapillus", ebirdCode: "bkcchi")
        session.addSighting(for: mockTaxon)
        
        #expect(checklist.sightings.count == 1)
        #expect(checklist.sightings.first?.alphaCode == "BCCH")
        #expect(checklist.sightings.first?.tally == 1)
        
        // 3. Increment tally
        let sighting = checklist.sightings.first!
        session.incrementTally(for: sighting)
        #expect(sighting.tally == 2)
        
        // 4. End session
        session.endSession()
        #expect(session.activeChecklist == nil)
        #expect(checklist.endTime != nil)
    }
    
    @MainActor
    @Test func testChecklistSessionDiscard() async throws {
        // Use an in-memory ModelContainer for isolated testing
        let schema = Schema([Checklist.self, Sighting.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        
        let session = ChecklistSession(modelContext: container.mainContext)
        #expect(session.activeChecklist == nil)
        
        session.startNewSession()
        #expect(session.activeChecklist != nil)
        
        session.discardSession()
        #expect(session.activeChecklist == nil)
        
        let descriptor = FetchDescriptor<Checklist>()
        let lists = try container.mainContext.fetch(descriptor)
        #expect(lists.isEmpty)
    }
    
    @MainActor
    @Test func testLocationManagerGPSDriftFiltering() async throws {
        let manager = LocationManager()
        #expect(manager.startLocation == nil)
        #expect(manager.currentDistance == 0.0)
        
        // 1. Initial location (accurate)
        let loc1 = CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            altitude: 0,
            horizontalAccuracy: 10,
            verticalAccuracy: 10,
            course: 0,
            speed: 0,
            timestamp: Date()
        )
        manager.locationManager(CLLocationManager(), didUpdateLocations: [loc1])
        
        #expect(manager.startLocation?.latitude == 37.7749)
        #expect(manager.currentDistance == 0.0)
        
        // 2. Stationary drift update (distance > 15m but speed is low: 0.1 m/s)
        // Move ~16 meters north: 1 degree latitude is ~111,000 meters. 0.00015 degrees is ~16.6 meters.
        let loc2 = CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: 37.77505, longitude: -122.4194),
            altitude: 0,
            horizontalAccuracy: 10,
            verticalAccuracy: 10,
            course: 0,
            speed: 0.1, // low speed
            timestamp: Date()
        )
        manager.locationManager(CLLocationManager(), didUpdateLocations: [loc2])
        
        #expect(manager.currentDistance == 0.0) // Should be filtered out as stationary drift
        
        // 3. Inaccurate update (horizontalAccuracy is 30m, above 25m threshold)
        let loc3 = CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: 37.77505, longitude: -122.4194),
            altitude: 0,
            horizontalAccuracy: 30,
            verticalAccuracy: 10,
            course: 0,
            speed: 1.5,
            timestamp: Date()
        )
        manager.locationManager(CLLocationManager(), didUpdateLocations: [loc3])
        
        #expect(manager.currentDistance == 0.0) // Should be filtered out due to accuracy
        
        // 4. Valid walking update (distance > 15m, speed = 1.2 m/s, accuracy = 10m)
        let loc4 = CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: 37.77505, longitude: -122.4194),
            altitude: 0,
            horizontalAccuracy: 10,
            verticalAccuracy: 10,
            course: 0,
            speed: 1.2,
            timestamp: Date()
        )
        manager.locationManager(CLLocationManager(), didUpdateLocations: [loc4])
        
        #expect(manager.currentDistance > 0.0) // Should accumulate distance!
    }
    
    @MainActor
    @Test func testTaxonSearchRanking() async throws {
        let registry = TaxonRegistry()
        registry.load()
        #expect(registry.isLoaded == true)
        
        // Test 1: Exact alpha code match is the top result
        let resultsBCCH = registry.search(query: "BCCH")
        #expect(!resultsBCCH.isEmpty)
        #expect(resultsBCCH.first?.alphaCode == "BCCH")
        
        // Test 2: Prefix matches rank higher than non-prefix matches
        // e.g., search "chickadee" -> Boreal Chickadee, Black-capped Chickadee, etc.
        // Let's test searching for "boreal"
        let resultsBoreal = registry.search(query: "boreal")
        #expect(!resultsBoreal.isEmpty)
        #expect(resultsBoreal.first?.commonName.hasPrefix("Boreal") == true)
        
        // Test 3: No match query returns empty array
        let resultsNone = registry.search(query: "NonExistentBirdSpec")
        #expect(resultsNone.isEmpty)
    }

}
