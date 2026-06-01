import Foundation
import Compression
import SwiftData

/// A protocol defining taxonomic lookup requirements for CSV formatting.
@MainActor
public protocol TaxonLookup: AnyObject, Sendable {
    /// Retrieves a Taxon for a given 4-letter Alpha Code.
    func taxon(forAlphaCode alphaCode: String) -> Taxon?
}

public enum ChecklistExportError: Error, LocalizedError, Equatable {
    /// The checklist has no sightings to export.
    case emptySightings
    /// The underlying compression (zlib) failed.
    case compressionFailed(Error?)
    /// The base45 encoding failed.
    case encodingFailed
    /// The final URL could not be constructed.
    case invalidBaseURL
    
    public var errorDescription: String? {
        switch self {
        case .emptySightings:
            return "Cannot export an empty checklist. Please add at least one Sighting."
        case .compressionFailed(let error):
            return "Failed to compress checklist data: \(error?.localizedDescription ?? "unknown error")."
        case .encodingFailed:
            return "Failed to encode compressed checklist data to Base45."
        case .invalidBaseURL:
            return "The configured base URL is invalid."
        }
    }
    
    public static func == (lhs: ChecklistExportError, rhs: ChecklistExportError) -> Bool {
        switch (lhs, rhs) {
        case (.emptySightings, .emptySightings):
            return true
        case (.compressionFailed, .compressionFailed):
            return true
        case (.encodingFailed, .encodingFailed):
            return true
        case (.invalidBaseURL, .invalidBaseURL):
            return true
        default:
            return false
        }
    }
}

/// The seam through which Checklists are exported into various formats.
public protocol ChecklistExportFormat: Sendable {
    associatedtype Output
    func export(_ checklist: Checklist, lookup: any TaxonLookup) async throws -> Output
}

/// A deep module responsible for exporting a Checklist.
/// It coordinates formatting strategies through a clean, unified interface.
@MainActor
public final class ChecklistExporter: Sendable {
    
    public struct Configuration: Equatable, Sendable {
        public let baseURL: URL
        public static let defaultBaseURL = URL(string: "https://rdabrunk.github.io/BirdWatch/decoder/")!
        public static let `default` = Configuration(baseURL: defaultBaseURL)
        
        public init(baseURL: URL = defaultBaseURL) {
            self.baseURL = baseURL
        }
    }
    
    private let taxonLookup: any TaxonLookup
    private let configuration: Configuration
    
    public init(taxonLookup: any TaxonLookup, configuration: Configuration = .default) {
        self.taxonLookup = taxonLookup
        self.configuration = configuration
    }
    
    /// Polymorphic entry point leveraging the adapter pattern to support multiple formats.
    public func export<F: ChecklistExportFormat>(
        _ checklist: Checklist,
        as format: F
    ) async throws -> F.Output {
        try await format.export(checklist, lookup: taxonLookup)
    }
    
    // MARK: - Direct Asynchronous Export Methods
    
    /// Formats a Checklist as an eBird-compliant CSV (no header row) asynchronously.
    public func exportToCSV(_ checklist: Checklist) async throws -> String {
        guard !checklist.sightings.isEmpty else {
            throw ChecklistExportError.emptySightings
        }
        return try await MainActor.run {
            try CSVExportHelper.formatAsCSV(checklist, lookup: self.taxonLookup)
        }
    }
    
    /// Exports a completed Checklist as a compressed QR-ready URL asynchronously.
    /// Safely performs MainActor-isolated model reads and moves compression to a background thread.
    public func exportAsQRURL(_ checklist: Checklist) async throws -> URL {
        guard !checklist.sightings.isEmpty else {
            throw ChecklistExportError.emptySightings
        }
        let csvString = try await MainActor.run {
            try CSVExportHelper.formatAsCSV(checklist, lookup: self.taxonLookup)
        }
        return try await Task.detached(priority: .userInitiated) {
            try QRURLHelper.compressAndBuildURL(csvString: csvString, baseURL: self.configuration.baseURL)
        }.value
    }
}

// MARK: - Format Implementations

/// Formats a Checklist and its Sightings into eBird-compliant CSV.
public struct CSVExportFormat: ChecklistExportFormat {
    public struct Configuration: Sendable {
        public let delimiter: String
        public static let defaultCSV = Configuration(delimiter: ",")
        
        public init(delimiter: String = ",") {
            self.delimiter = delimiter
        }
    }
    
    private let config: Configuration
    
    public init(configuration: Configuration = .defaultCSV) {
        self.config = configuration
    }
    
    @MainActor
    public func export(_ checklist: Checklist, lookup: any TaxonLookup) async throws -> String {
        guard !checklist.sightings.isEmpty else {
            throw ChecklistExportError.emptySightings
        }
        return try CSVExportHelper.formatAsCSV(checklist, lookup: lookup, delimiter: config.delimiter)
    }
}

/// Formats a Checklist into a compressed QR-ready URL payload.
/// Encapsulates zlib compression and Base45 encoding details inside the formatter.
public struct QRURLExportFormat: ChecklistExportFormat {
    public struct Configuration: Sendable {
        public let baseURL: URL
        public static let defaultBaseURL = URL(string: "https://rdabrunk.github.io/BirdWatch/decoder/")!
        
        public init(baseURL: URL = defaultBaseURL) {
            self.baseURL = baseURL
        }
    }
    
    private let config: Configuration
    
    public init(configuration: Configuration = .init(baseURL: Configuration.defaultBaseURL)) {
        self.config = configuration
    }
    
    @MainActor
    public func export(_ checklist: Checklist, lookup: any TaxonLookup) async throws -> URL {
        // Extract CSV content on Main Actor first (due to SwiftData confinement)
        let csvString = try CSVExportHelper.formatAsCSV(checklist, lookup: lookup)
        
        // Relocate CPU-intensive compression and encoding to a background task
        return try await Task.detached(priority: .userInitiated) {
            try QRURLHelper.compressAndBuildURL(csvString: csvString, baseURL: config.baseURL)
        }.value
    }
}

// MARK: - Internal Helpers
// Encapsulates the shared calculations to maintain locality and reuse.

enum CSVExportHelper {
    @MainActor
    static func formatAsCSV(_ checklist: Checklist, lookup: any TaxonLookup, delimiter: String = ",") throws -> String {
        var rows: [String] = []
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "M/d/yyyy"
        let dateString = dateFormatter.string(from: checklist.startTime)
        
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "H:mm"
        let timeString = timeFormatter.string(from: checklist.startTime)
        
        let duration = checklist.durationInMinutes
        let protocolString: String
        switch checklist.protocolType {
        case .stationary: protocolString = "stationary"
        case .traveling: protocolString = "traveling"
        case .incidental: protocolString = "incidental"
        }
        
        let allReported = checklist.isCompleteChecklist ? "Y" : "N"
        
        let latString = (checklist.trackLocation && checklist.latitude != nil) ? "\(checklist.latitude!)" : ""
        let lonString = (checklist.trackLocation && checklist.longitude != nil) ? "\(checklist.longitude!)" : ""
        
        let locationName: String
        if let customName = checklist.customLocationName, !customName.isEmpty {
            locationName = customName
        } else if checklist.trackLocation, let lat = checklist.latitude, let lon = checklist.longitude {
            locationName = String(format: "My Location (%.4f, %.4f)", lat, lon)
        } else {
            locationName = "My Location"
        }
        let escapedLocation = escapeCSVField(locationName)
        
        let distanceString: String
        if checklist.protocolType == .traveling {
            distanceString = String(format: "%.2f", checklist.distanceMiles ?? 0.0)
        } else {
            distanceString = ""
        }
        
        for sighting in checklist.sightings {
            let taxon = lookup.taxon(forAlphaCode: sighting.alphaCode)
            let commonName = taxon?.commonName ?? "Unknown Species"
            let tally = sighting.tally
            
            let escapedCommon = escapeCSVField(commonName)
            
            let fields: [String] = [
                escapedCommon,   // 1. Common Name
                "",              // 2. Genus
                "",              // 3. Species
                "\(tally)",      // 5. Number
                "",              // 4. Species Comments
                escapedLocation, // 6. Location Name
                latString,       // 7. Latitude
                lonString,       // 8. Longitude
                dateString,      // 9. Date
                timeString,      // 10. Start Time
                "",              // 11. State/Province
                "",              // 12. Country Code
                protocolString,  // 13. Protocol
                "\(checklist.observersCount)", // 14. Number of Observers
                "\(duration)",   // 15. Duration
                allReported,     // 16. All observations reported?
                distanceString,  // 17. Effort Distance Miles
                "",              // 18. Effort area acres
                ""               // 19. Submission Comments
            ]
            rows.append(fields.joined(separator: delimiter))
        }
        
        return rows.joined(separator: "\n")
    }
    
    private static func escapeCSVField(_ field: String) -> String {
        if field.contains(",") || field.contains("\"") || field.contains("\n") || field.contains("\r") {
            let escaped = field.replacingOccurrences(of: "\"", with: "\"\"")
            return "\"\(escaped)\""
        }
        return field
    }
}

enum QRURLHelper {
    static func compressAndBuildURL(csvString: String, baseURL: URL) throws -> URL {
        let data = Data(csvString.utf8)
        let compressed: Data
        do {
            compressed = try (data as NSData).compressed(using: .zlib) as Data
        } catch {
            throw ChecklistExportError.compressionFailed(error)
        }
        
        let base45String = Base45.encode(compressed)
        guard let encodedBase45 = base45String.addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed) else {
            throw ChecklistExportError.encodingFailed
        }
        
        var urlComponents = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)
        urlComponents?.percentEncodedFragment = encodedBase45
        
        guard let finalURL = urlComponents?.url else {
            throw ChecklistExportError.invalidBaseURL
        }
        
        return finalURL
    }
}

// Zero-cost extension to conform TaxonRegistry to TaxonLookup
extension TaxonRegistry: TaxonLookup {}
