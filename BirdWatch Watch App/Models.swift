//
//  Models.swift
//  BirdWatch
//
//  Created by Ryan Brunk on 5/19/26.
//

import Foundation
import SwiftData

@Model
final class Bird {
    @Attribute(.unique) var alphaCode: String
    var commonName: String
    var scientificName: String
    var ebirdCode: String
    
    init(alphaCode: String, commonName: String, scientificName: String, ebirdCode: String) {
        self.alphaCode = alphaCode
        self.commonName = commonName
        self.scientificName = scientificName
        self.ebirdCode = ebirdCode
    }
}

@Model
final class Sighting {
    var count: Int
    var timestamp: Date
    
    // Relationships
    var bird: Bird?
    var checklist: Checklist?
    
    init(count: Int = 1, timestamp: Date = Date(), bird: Bird) {
        self.count = count
        self.timestamp = timestamp
        self.bird = bird
    }
}

enum ProtocolType: String, CaseIterable, Identifiable {
    case stationary = "Stationary"
    case traveling = "Traveling"
    case incidental = "Incidental"
    
    var id: String { rawValue }
}

@Model
final class Checklist {
    var startTime: Date
    var endTime: Date?
    
    var protocolTypeRaw: String = ProtocolType.stationary.rawValue
    var observersCount: Int = 1
    var isCompleteChecklist: Bool = true
    
    // Cascade delete means if we delete a checklist, all its sightings are deleted too
    @Relationship(deleteRule: .cascade, inverse: \Sighting.checklist)
    var sightings: [Sighting] = []
    
    init(startTime: Date = Date(), protocolTypeRaw: String = ProtocolType.stationary.rawValue, observersCount: Int = 1, isCompleteChecklist: Bool = true) {
        self.startTime = startTime
        self.protocolTypeRaw = protocolTypeRaw
        self.observersCount = observersCount
        self.isCompleteChecklist = isCompleteChecklist
    }
}

@MainActor
class DatabaseHelper {
    static func preloadTaxonomyData(modelContext: ModelContext) {
        // 1. Check if we already have birds in the database to prevent duplicate work
        let fetchDescriptor = FetchDescriptor<Bird>()
        let existingBirdCount = (try? modelContext.fetchCount(fetchDescriptor)) ?? 0
        
        if existingBirdCount > 0 {
            print("Taxonomy already loaded. Found \(existingBirdCount) species.")
            return
        }
        
        print("First launch detected. Loading aba_birds.csv into SwiftData...")
        
        // 2. Locate the CSV in the app bundle
        guard let url = Bundle.main.url(forResource: "aba_birds", withExtension: "csv") else {
            print("❌ Could not find aba_birds.csv in bundle. Did you check 'Add to targets'?")
            return
        }
        
        // 3. Parse the CSV and insert into SwiftData
        do {
            let data = try String(contentsOf: url, encoding: .utf8)
            let rows = data.components(separatedBy: .newlines)
            
            // Skip the first row (headers) and iterate through the rest
            var insertCount = 0
            for row in rows.dropFirst() {
                if row.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { continue }
                
                let columns = row.components(separatedBy: ",")
                if columns.count >= 4 {
                    let bird = Bird(
                        alphaCode: columns[0].trimmingCharacters(in: .whitespaces),
                        commonName: columns[1].trimmingCharacters(in: .whitespaces),
                        scientificName: columns[2].trimmingCharacters(in: .whitespaces),
                        ebirdCode: columns[3].trimmingCharacters(in: .whitespaces)
                    )
                    modelContext.insert(bird)
                    insertCount += 1
                }
            }
            
            // 4. Save the context to write to disk
            try modelContext.save()
            print("✅ Successfully preloaded \(insertCount) birds into the local database!")
            
        } catch {
            print("❌ Error reading CSV file: \(error)")
        }
    }
}

// MARK: - Checklist Extensions for Statistics & Export
extension Checklist {
    var totalSpeciesCount: Int {
        sightings.count
    }
    
    var totalBirdCount: Int {
        sightings.reduce(0) { $0 + $1.count }
    }
    
    var durationInMinutes: Int {
        let end = endTime ?? Date()
        let interval = end.timeIntervalSince(startTime)
        return max(1, Int(interval / 60))
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: startTime)
    }
    
    var formattedTimeRange: String {
        let timeFormatter = DateFormatter()
        timeFormatter.dateStyle = .none
        timeFormatter.timeStyle = .short
        
        let start = timeFormatter.string(from: startTime)
        if let end = endTime {
            let endStr = timeFormatter.string(from: end)
            return "\(start) - \(endStr)"
        } else {
            return "\(start) - Active"
        }
    }
    
    var formattedDuration: String {
        let duration = durationInMinutes
        if duration < 60 {
            return "\(duration)m"
        } else {
            let hours = duration / 60
            let mins = duration % 60
            return mins > 0 ? "\(hours)h \(mins)m" : "\(hours)h"
        }
    }
    
    func generateCSVString() -> String {
        var csv = "Common Name,Scientific Name,Count,State/Province,Country,Date,Start Time,Protocol,Number of Observers,Duration,All observations reported,Distance Covered,Area Covered,Checklist Comments\n"
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd/yyyy"
        let dateString = dateFormatter.string(from: startTime)
        
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "hh:mm a"
        let timeString = timeFormatter.string(from: startTime)
        
        let duration = durationInMinutes
        let protocolFormatted = ProtocolType(rawValue: protocolTypeRaw)?.rawValue ?? "Stationary"
        let allReported = isCompleteChecklist ? "Y" : "N"
        
        for sighting in sightings {
            let commonName = sighting.bird?.commonName ?? "Unknown Species"
            let scientificName = sighting.bird?.scientificName ?? ""
            let count = sighting.count
            
            // Clean up commas in names by wrapping them in double quotes
            let escapedCommon = commonName.contains(",") ? "\"\(commonName)\"" : commonName
            let escapedScientific = scientificName.contains(",") ? "\"\(scientificName)\"" : scientificName
            
            csv += "\(escapedCommon),\(escapedScientific),\(count),,,\(dateString),\(timeString),\(protocolFormatted),\(observersCount),\(duration),\(allReported),,,\n"
        }
        
        return csv
    }
}

