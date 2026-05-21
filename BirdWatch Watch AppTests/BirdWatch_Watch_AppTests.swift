//
//  BirdWatch_Watch_AppTests.swift
//  BirdWatch Watch AppTests
//
//  Created by Ryan Brunk on 5/19/26.
//

import Testing
import SwiftData
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

}
