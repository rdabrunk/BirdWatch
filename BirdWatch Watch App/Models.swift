import Foundation
import SwiftData

// MARK: - Taxonomy

public struct Taxon: Identifiable, Equatable, Hashable, Codable, Sendable {
    public var id: String { alphaCode }
    public let alphaCode: String
    public let commonName: String
    public let scientificName: String
    public let ebirdCode: String
    
    public init(alphaCode: String, commonName: String, scientificName: String, ebirdCode: String) {
        self.alphaCode = alphaCode.uppercased()
        self.commonName = commonName
        self.scientificName = scientificName
        self.ebirdCode = ebirdCode
    }
}

// MARK: - Core Database Models

@Model
public final class Sighting {
    public var alphaCode: String = ""
    public var tally: Int = 1
    public var timestamp: Date = Date()
    
    public var checklist: Checklist?
    
    public init(alphaCode: String, tally: Int = 1, timestamp: Date = Date()) {
        self.alphaCode = alphaCode.uppercased()
        self.tally = tally
        self.timestamp = timestamp
    }
}

public enum ProtocolType: String, CaseIterable, Identifiable, Codable, Sendable {
    case stationary = "Stationary"
    case traveling = "Traveling"
    case incidental = "Incidental"
    
    public var id: String { rawValue }
}

@Model
public final class Checklist {
    public var startTime: Date
    public var endTime: Date?
    
    public var protocolTypeRaw: String = ProtocolType.stationary.rawValue
    public var observersCount: Int = 1
    public var isCompleteChecklist: Bool = true
    
    @Relationship(deleteRule: .cascade, inverse: \Sighting.checklist)
    public var sightings: [Sighting] = []
    
    public var protocolType: ProtocolType {
        get { ProtocolType(rawValue: protocolTypeRaw) ?? .stationary }
        set { protocolTypeRaw = newValue.rawValue }
    }
    
    public init(startTime: Date = Date(), protocolType: ProtocolType = .stationary, observersCount: Int = 1, isCompleteChecklist: Bool = true) {
        self.startTime = startTime
        self.protocolTypeRaw = protocolType.rawValue
        self.observersCount = observersCount
        self.isCompleteChecklist = isCompleteChecklist
    }
}

// MARK: - TaxonRegistry

@MainActor
public final class TaxonRegistry: ObservableObject {
    @Published public private(set) var taxonsByAlpha: [String: Taxon] = [:]
    @Published public private(set) var sortedTaxons: [Taxon] = []
    public private(set) var isLoaded = false
    
    public init() {}
    
    public func load() {
        guard !isLoaded else { return }
        
        print("Loading aba_birds.csv into in-memory TaxonRegistry...")
        guard let url = Bundle.main.url(forResource: "aba_birds", withExtension: "csv") else {
            print("❌ Could not find aba_birds.csv in bundle.")
            return
        }
        
        do {
            let data = try String(contentsOf: url, encoding: .utf8)
            let lines = data.components(separatedBy: .newlines)
            
            var tempMap: [String: Taxon] = [:]
            var tempList: [Taxon] = []
            
            for line in lines.dropFirst() {
                if line.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { continue }
                
                let columns = parseCSVRow(line)
                if columns.count >= 4 {
                    let code = columns[0].trimmingCharacters(in: .whitespaces).uppercased()
                    let taxon = Taxon(
                        alphaCode: code,
                        commonName: columns[1].trimmingCharacters(in: .whitespaces),
                        scientificName: columns[2].trimmingCharacters(in: .whitespaces),
                        ebirdCode: columns[3].trimmingCharacters(in: .whitespaces)
                    )
                    tempMap[code] = taxon
                    tempList.append(taxon)
                }
            }
            
            self.taxonsByAlpha = tempMap
            self.sortedTaxons = tempList.sorted(by: { $0.commonName < $1.commonName })
            self.isLoaded = true
            print("✅ Successfully preloaded \(tempList.count) taxons into memory!")
            
        } catch {
            print("❌ Error reading CSV file: \(error)")
        }
    }
    
    public func taxon(forAlphaCode alphaCode: String) -> Taxon? {
        return taxonsByAlpha[alphaCode.uppercased()]
    }
    
    public func search(query: String) -> [Taxon] {
        let term = query.trimmingCharacters(in: .whitespaces).lowercased()
        if term.isEmpty { return sortedTaxons }
        
        let filtered = sortedTaxons.filter {
            $0.alphaCode.lowercased().contains(term) ||
            $0.commonName.lowercased().contains(term)
        }
        
        return filtered.sorted { t1, t2 in
            let t1Alpha = t1.alphaCode.lowercased().hasPrefix(term)
            let t2Alpha = t2.alphaCode.lowercased().hasPrefix(term)
            if t1Alpha != t2Alpha { return t1Alpha }
            
            let t1Name = t1.commonName.lowercased().hasPrefix(term)
            let t2Name = t2.commonName.lowercased().hasPrefix(term)
            if t1Name != t2Name { return t1Name }
            
            return t1.commonName < t2.commonName
        }
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

// MARK: - ChecklistSession Coordinator

@MainActor
public final class ChecklistSession: ObservableObject {
    @Published public private(set) var activeChecklist: Checklist?
    private let modelContext: ModelContext
    
    public init(modelContext: ModelContext) {
        self.modelContext = modelContext
        fetchActiveChecklist()
    }
    
    public func fetchActiveChecklist() {
        let descriptor = FetchDescriptor<Checklist>(sortBy: [SortDescriptor(\.startTime, order: .reverse)])
        if let lists = try? modelContext.fetch(descriptor) {
            self.activeChecklist = lists.first(where: { $0.endTime == nil })
        }
    }
    
    public func startNewSession() {
        if activeChecklist != nil { return }
        let newList = Checklist()
        modelContext.insert(newList)
        try? modelContext.save()
        self.activeChecklist = newList
    }
    
    public func endSession() {
        guard let list = activeChecklist else { return }
        list.endTime = Date()
        try? modelContext.save()
        self.activeChecklist = nil
    }
    
    public func addSighting(for taxon: Taxon) {
        guard let list = activeChecklist else { return }
        if let existing = list.sightings.first(where: { $0.alphaCode == taxon.alphaCode }) {
            existing.tally += 1
            existing.timestamp = Date()
        } else {
            let newSighting = Sighting(alphaCode: taxon.alphaCode, tally: 1)
            newSighting.checklist = list
            modelContext.insert(newSighting)
        }
        try? modelContext.save()
        self.objectWillChange.send()
    }
    
    public func removeSighting(_ sighting: Sighting) {
        modelContext.delete(sighting)
        try? modelContext.save()
        self.objectWillChange.send()
    }
    
    public func incrementTally(for sighting: Sighting) {
        sighting.tally += 1
        sighting.timestamp = Date()
        try? modelContext.save()
        self.objectWillChange.send()
    }
    
    public func decrementTally(for sighting: Sighting) {
        if sighting.tally > 1 {
            sighting.tally -= 1
            sighting.timestamp = Date()
            try? modelContext.save()
            self.objectWillChange.send()
        } else {
            removeSighting(sighting)
        }
    }
    
    public func generateExportCSV(for checklist: Checklist, registry: TaxonRegistry) -> String {
        var csv = "Common Name,Scientific Name,Count,State/Province,Country,Date,Start Time,Protocol,Number of Observers,Duration,All observations reported,Distance Covered,Area Covered,Checklist Comments\n"
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd/yyyy"
        let dateString = dateFormatter.string(from: checklist.startTime)
        
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "hh:mm a"
        let timeString = timeFormatter.string(from: checklist.startTime)
        
        let end = checklist.endTime ?? Date()
        let duration = max(1, Int(end.timeIntervalSince(checklist.startTime) / 60))
        let protocolFormatted = checklist.protocolType.rawValue
        let allReported = checklist.isCompleteChecklist ? "Y" : "N"
        
        for sighting in checklist.sightings {
            let taxon = registry.taxon(forAlphaCode: sighting.alphaCode)
            let commonName = taxon?.commonName ?? "Unknown Species"
            let scientificName = taxon?.scientificName ?? ""
            let tally = sighting.tally
            
            let escapedCommon = commonName.contains(",") ? "\"\(commonName)\"" : commonName
            let escapedScientific = scientificName.contains(",") ? "\"\(scientificName)\"" : scientificName
            
            csv += "\(escapedCommon),\(escapedScientific),\(tally),,,\(dateString),\(timeString),\(protocolFormatted),\(checklist.observersCount),\(duration),\(allReported),,,\n"
        }
        return csv
    }
}

// MARK: - Checklist Extensions for Statistics
extension Checklist {
    public var totalTaxaCount: Int {
        sightings.count
    }
    
    public var totalTallyCount: Int {
        sightings.reduce(0) { $0 + $1.tally }
    }
    
    public var durationInMinutes: Int {
        let end = endTime ?? Date()
        let interval = end.timeIntervalSince(startTime)
        return max(1, Int(interval / 60))
    }
    
    public var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: startTime)
    }
    
    public var formattedTimeRange: String {
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
    
    public var formattedDuration: String {
        let duration = durationInMinutes
        if duration < 60 {
            return "\(duration)m"
        } else {
            let hours = duration / 60
            let mins = duration % 60
            return mins > 0 ? "\(hours)h \(mins)m" : "\(hours)h"
        }
    }
}
