import Testing
import Foundation
import SwiftData
import Compression
@testable import BirdWatch_Watch_App

struct ChecklistExporterTests {
    
    // Concrete simple mock for TaxonLookup to keep tests isolated
    final class MockTaxonLookup: TaxonLookup, Sendable {
        func taxon(forAlphaCode alphaCode: String) -> Taxon? {
            switch alphaCode.uppercased() {
            case "BCCH":
                return Taxon(alphaCode: "BCCH", commonName: "Black-capped Chickadee", scientificName: "Poecile atricapillus", ebirdCode: "bkcchi")
            case "AMRO":
                return Taxon(alphaCode: "AMRO", commonName: "American Robin", scientificName: "Turdus migratorius", ebirdCode: "amerob")
            case "GULL":
                return Taxon(alphaCode: "GULL", commonName: "Gull, Herring", scientificName: "Larus argentatus", ebirdCode: "hergul")
            default:
                return nil
            }
        }
    }
    
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
        
        let lookup = MockTaxonLookup()
        let exporter = ChecklistExporter(taxonLookup: lookup)
        
        // When
        let csv = try exporter.exportToCSV(checklist)
        
        // Then
        let lines = csv.components(separatedBy: "\n")
        #expect(lines.count == 1) // Single row, no header
        
        let fields = lines[0].components(separatedBy: ",")
        #expect(fields.count == 19)
        #expect(fields[0] == "Black-capped Chickadee")
        #expect(fields[1] == "")
        #expect(fields[2] == "")
        #expect(fields[3] == "3")
        #expect(fields[4] == "")
        #expect(fields[5] == "My Location")
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "M/d/yyyy"
        let expectedDate = dateFormatter.string(from: checklist.startTime)
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "H:mm"
        let expectedTime = timeFormatter.string(from: checklist.startTime)
        
        #expect(fields[8] == expectedDate)
        #expect(fields[9] == expectedTime)
        #expect(fields[12] == "stationary")
        #expect(fields[13] == "1")
        #expect(fields[15] == "Y")
    }
    
    @MainActor
    @Test func testCustomLocationNameExport() async throws {
        // Given
        let schema = Schema([Checklist.self, Sighting.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        
        let checklist = Checklist(
            startTime: Date(),
            protocolType: .stationary,
            trackLocation: true
        )
        checklist.latitude = 42.1234
        checklist.longitude = -71.5678
        checklist.customLocationName = "Home Sweet Home"
        container.mainContext.insert(checklist)
        
        let sighting = Sighting(alphaCode: "BCCH", tally: 2)
        sighting.checklist = checklist
        container.mainContext.insert(sighting)
        
        let lookup = MockTaxonLookup()
        let exporter = ChecklistExporter(taxonLookup: lookup)
        
        // When
        let csv = try exporter.exportToCSV(checklist)
        
        // Then
        let fields = parseCSVRow(csv)
        #expect(fields[5] == "Home Sweet Home")
        #expect(fields[6] == "42.1234")
        #expect(fields[7] == "-71.5678")
    }
    
    @MainActor
    @Test func testDefaultLocationFallback() async throws {
        // Given
        let schema = Schema([Checklist.self, Sighting.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        
        let checklist = Checklist(
            startTime: Date(),
            protocolType: .stationary,
            trackLocation: true
        )
        checklist.latitude = 42.123412
        checklist.longitude = -71.567815
        checklist.customLocationName = nil
        container.mainContext.insert(checklist)
        
        let sighting = Sighting(alphaCode: "BCCH", tally: 2)
        sighting.checklist = checklist
        container.mainContext.insert(sighting)
        
        let lookup = MockTaxonLookup()
        let exporter = ChecklistExporter(taxonLookup: lookup)
        
        // When
        let csv = try exporter.exportToCSV(checklist)
        
        // Then
        let fields = parseCSVRow(csv)
        #expect(fields[5] == "My Location (42.1234, -71.5678)")
        #expect(fields[6] == "42.123412")
        #expect(fields[7] == "-71.567815")
    }
    
    @MainActor
    @Test func testProtocolMappingAndLocation() async throws {
        // Given
        let schema = Schema([Checklist.self, Sighting.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        
        let lookup = MockTaxonLookup()
        let exporter = ChecklistExporter(taxonLookup: lookup)
        
        // Test Stationary, Traveling, Incidental
        for type in ProtocolType.allCases {
            let checklist = Checklist(startTime: Date(), protocolType: type, observersCount: 2, isCompleteChecklist: false, trackLocation: true)
            checklist.latitude = 42.1234
            checklist.longitude = -71.5678
            checklist.distanceMiles = 1.45
            container.mainContext.insert(checklist)
            
            let sighting = Sighting(alphaCode: "AMRO", tally: 5)
            sighting.checklist = checklist
            container.mainContext.insert(sighting)
            
            let csv = try exporter.exportToCSV(checklist)
            let fields = parseCSVRow(csv)
            
            #expect(fields[5] == "My Location (42.1234, -71.5678)")
            #expect(fields[6] == "42.1234")
            #expect(fields[7] == "-71.5678")
            #expect(fields[12] == type.rawValue.lowercased())
            #expect(fields[13] == "2")
            #expect(fields[15] == "N")
            
            if type == .traveling {
                #expect(fields[16] == "1.45")
            } else {
                #expect(fields[16] == "")
            }
        }
    }
    
    @MainActor
    @Test func testCSVFieldEscaping() async throws {
        // Given
        let schema = Schema([Checklist.self, Sighting.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        
        let checklist = Checklist(startTime: Date(), protocolType: .stationary)
        container.mainContext.insert(checklist)
        
        let sighting = Sighting(alphaCode: "GULL", tally: 1)
        sighting.checklist = checklist
        container.mainContext.insert(sighting)
        
        let lookup = MockTaxonLookup()
        let exporter = ChecklistExporter(taxonLookup: lookup)
        
        // When
        let csv = try exporter.exportToCSV(checklist)
        
        // Then
        #expect(csv.contains("\"Gull, Herring\""))
    }
    
    @MainActor
    @Test func testEmptyChecklistValidation() async throws {
        // Given
        let schema = Schema([Checklist.self, Sighting.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        
        let checklist = Checklist(startTime: Date(), protocolType: .stationary)
        container.mainContext.insert(checklist)
        
        let lookup = MockTaxonLookup()
        let exporter = ChecklistExporter(taxonLookup: lookup)
        
        // When / Then
        #expect(throws: ChecklistExportError.emptySightings) {
            try exporter.exportToCSV(checklist)
        }
        
        #expect(throws: ChecklistExportError.emptySightings) {
            try exporter.exportAsQRURL(checklist)
        }
    }
    
    @MainActor
    @Test func testQRExportRoundTrip() async throws {
        // Given
        let schema = Schema([Checklist.self, Sighting.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        
        let checklist = Checklist(
            startTime: Date(timeIntervalSince1970: 1716472800),
            protocolType: .stationary,
            observersCount: 1,
            isCompleteChecklist: true
        )
        checklist.endTime = Date(timeIntervalSince1970: 1716472800 + 3600) // 1 hour duration (fixed)
        container.mainContext.insert(checklist)
        
        let sighting = Sighting(alphaCode: "BCCH", tally: 2)
        sighting.checklist = checklist
        container.mainContext.insert(sighting)
        
        let lookup = MockTaxonLookup()
        let customBaseURL = URL(string: "https://example.com/decoder/")!
        let exporter = ChecklistExporter(taxonLookup: lookup, configuration: ChecklistExporter.Configuration(baseURL: customBaseURL))
        
        // When
        let qrURL = try exporter.exportAsQRURL(checklist)
        
        // Then
        #expect(qrURL.host == "example.com")
        #expect(qrURL.path == "/decoder" || qrURL.path == "/decoder/")
        #expect(qrURL.fragment != nil)
        
        guard let fragment = qrURL.fragment else {
            Issue.record("qrURL fragment was nil")
            return
        }
        
        // Retrieve and decode Base45 from fragment
        let base45Str = fragment.removingPercentEncoding ?? fragment
        let compressedData = try Base45.decode(base45Str)
        
        // Decompress raw deflate
        let decompressedData = try (compressedData as NSData).decompressed(using: .zlib) as Data
        guard let decompressedString = String(data: decompressedData, encoding: .utf8) else {
            Issue.record("Failed to decode decompressed data as UTF8 string")
            return
        }
        
        let expectedCSV = try exporter.exportToCSV(checklist)
        if decompressedString != expectedCSV {
            let debugMsg = "EXPECTED:\n[\(expectedCSV)]\n\nGOT:\n[\(decompressedString)]\n"
            try? debugMsg.write(toFile: "/Users/ryanbrunk/Personal/Birds/BirdWatch/test_debug.txt", atomically: true, encoding: .utf8)
        }
        #expect(decompressedString == expectedCSV)
    }
    
    private func parseCSVRow(_ row: String) -> [String] {
        var result: [String] = []
        var currentToken = ""
        var insideQuotes = false
        for char in row {
            if char == "\"" {
                insideQuotes.toggle()
            } else if char == "," && !insideQuotes {
                result.append(currentToken)
                currentToken = ""
            } else {
                currentToken.append(char)
            }
        }
        result.append(currentToken)
        return result
    }
}

