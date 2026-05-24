import Testing
import Foundation
import SwiftData
@testable import BirdWatch_Watch_App

struct EBirdCSVFormatterTests {
    @MainActor
    @Test func testBasicCSVStructure() async throws {
        // Given
        let schema = Schema([Checklist.self, Sighting.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        
        let checklist = Checklist(
            startTime: Date(timeIntervalSince1970: 1716472800), // May 23, 2026 10:00:00 UTC
            protocolType: .stationary,
            observersCount: 1,
            isCompleteChecklist: true
        )
        container.mainContext.insert(checklist)
        
        let sighting = Sighting(alphaCode: "BCCH", tally: 3)
        sighting.checklist = checklist
        container.mainContext.insert(sighting)
        
        let registry = TaxonRegistry()
        registry.load()
        
        // When
        let csv = EBirdCSVFormatter.format(checklist, registry: registry)
        
        // Then
        let lines = csv.components(separatedBy: "\n")
        #expect(lines.count == 1) // Single row, no header, no trailing newline
        
        let fields = lines[0].components(separatedBy: ",")
        #expect(fields.count == 19)
        #expect(fields[0] == "Black-capped Chickadee")
        #expect(fields[1] == "")
        #expect(fields[2] == "")
        #expect(fields[3] == "3")
        #expect(fields[4] == "")
        #expect(fields[5] == "My Location")
        #expect(fields[12] == "stationary")
        #expect(fields[13] == "1")
        #expect(fields[15] == "Y")
    }
    
    @MainActor
    @Test func testProtocolMapping() async throws {
        let schema = Schema([Checklist.self, Sighting.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        
        let registry = TaxonRegistry()
        registry.load()
        
        for type in ProtocolType.allCases {
            let checklist = Checklist(startTime: Date(), protocolType: type, observersCount: 1, isCompleteChecklist: true)
            container.mainContext.insert(checklist)
            
            let sighting = Sighting(alphaCode: "BCCH", tally: 1)
            sighting.checklist = checklist
            container.mainContext.insert(sighting)
            
            let csv = EBirdCSVFormatter.format(checklist, registry: registry)
            let fields = csv.components(separatedBy: ",")
            #expect(fields[12] == type.rawValue.lowercased())
        }
    }
    
    @MainActor
    @Test func testCSVFieldEscaping() throws {
        // Direct internal function test
        let escaped1 = EBirdCSVFormatter.escapeCSVField("Plain Name")
        #expect(escaped1 == "Plain Name")
        
        let escaped2 = EBirdCSVFormatter.escapeCSVField("Gull, Herring")
        #expect(escaped2 == "\"Gull, Herring\"")
        
        let escaped3 = EBirdCSVFormatter.escapeCSVField("Bird \"Special\"")
        #expect(escaped3 == "\"Bird \"\"Special\"\"\"")
    }
    
    @MainActor
    @Test func testCSVWithLocationAndDistance() async throws {
        let schema = Schema([Checklist.self, Sighting.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        
        let checklist = Checklist(
            startTime: Date(timeIntervalSince1970: 1716472800),
            protocolType: .traveling,
            observersCount: 2,
            isCompleteChecklist: true,
            trackLocation: true
        )
        checklist.latitude = 37.7749
        checklist.longitude = -122.4194
        checklist.distanceMiles = 1.25
        container.mainContext.insert(checklist)
        
        let sighting = Sighting(alphaCode: "BCCH", tally: 2)
        sighting.checklist = checklist
        container.mainContext.insert(sighting)
        
        let registry = TaxonRegistry()
        registry.load()
        
        let csv = EBirdCSVFormatter.format(checklist, registry: registry)
        let lines = csv.components(separatedBy: "\n")
        let fields = lines[0].components(separatedBy: ",")
        
        #expect(fields.count == 19)
        #expect(fields[5] == "My Location")
        #expect(fields[6] == "37.7749")
        #expect(fields[7] == "-122.4194")
        #expect(fields[12] == "traveling")
        #expect(fields[13] == "2")
        #expect(fields[16] == "1.25")
    }
    
    @MainActor
    @Test func testAutoProtocolClassification() async throws {
        let schema = Schema([Checklist.self, Sighting.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        
        let session1 = ChecklistSession(modelContext: container.mainContext)
        session1.startNewSession(trackLocation: true)
        let list1 = session1.activeChecklist!
        list1.distanceMiles = 0.06
        session1.endSession()
        #expect(list1.protocolType == .traveling)
        
        let session2 = ChecklistSession(modelContext: container.mainContext)
        session2.startNewSession(trackLocation: true)
        let list2 = session2.activeChecklist!
        list2.distanceMiles = 0.04
        session2.endSession()
        #expect(list2.protocolType == .stationary)
        
        let session3 = ChecklistSession(modelContext: container.mainContext)
        session3.startNewSession(trackLocation: false)
        let list3 = session3.activeChecklist!
        list3.protocolType = .incidental
        session3.endSession()
        #expect(list3.protocolType == .incidental)
    }
}
