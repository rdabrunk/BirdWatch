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

/// A deep module responsible for exporting a Checklist into a compressed QR-ready URL or CSV string.
/// It encapsulates CSV formatting, zlib compression, Base45 encoding, and fragment URL construction.
@MainActor
public final class ChecklistExporter: Sendable {
    
    /// A configuration object specifying settings for the export process.
    public struct Configuration: Equatable, Sendable {
        /// The web page URL that will decode the checklist QR code payload.
        public let baseURL: URL
        
        /// Default configuration pointing to the production GitHub Pages decoder.
        public static let defaultBaseURL = URL(string: "https://rdabrunk.github.io/BirdWatch/decoder/")!
        
        public static let `default` = Configuration(baseURL: defaultBaseURL)
        
        public init(baseURL: URL = defaultBaseURL) {
            self.baseURL = baseURL
        }
    }
    
    private let taxonLookup: any TaxonLookup
    private let configuration: Configuration
    
    /// Initializes the exporter with a taxonomic lookup delegate and optional configuration.
    public init(taxonLookup: any TaxonLookup, configuration: Configuration = .default) {
        self.taxonLookup = taxonLookup
        self.configuration = configuration
    }
    
    /// Formats a Checklist as an eBird-compliant CSV (no header row).
    public func exportToCSV(_ checklist: Checklist) throws -> String {
        guard !checklist.sightings.isEmpty else {
            throw ChecklistExportError.emptySightings
        }
        
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
        
        // Coordinates and distance strings
        let latString = (checklist.trackLocation && checklist.latitude != nil) ? "\(checklist.latitude!)" : ""
        let lonString = (checklist.trackLocation && checklist.longitude != nil) ? "\(checklist.longitude!)" : ""
        
        let locationName: String
        if checklist.trackLocation, let lat = checklist.latitude, let lon = checklist.longitude {
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
            let taxon = taxonLookup.taxon(forAlphaCode: sighting.alphaCode)
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
                protocolString,// 13. Protocol
                "\(checklist.observersCount)", // 14. Number of Observers
                "\(duration)", // 15. Duration
                allReported,   // 16. All observations reported?
                distanceString,// 17. Effort Distance Miles
                "",            // 18. Effort area acres
                ""             // 19. Submission Comments
            ]
            rows.append(fields.joined(separator: ","))
        }
        
        return rows.joined(separator: "\n")
    }
    
    /// Exports a completed Checklist as a compressed URL suitable for QR code generation.
    public func exportAsQRURL(_ checklist: Checklist) throws -> URL {
        let csvString = try exportToCSV(checklist)
        
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
        
        var urlComponents = URLComponents(url: configuration.baseURL, resolvingAgainstBaseURL: false)
        urlComponents?.percentEncodedFragment = encodedBase45
        
        guard let finalURL = urlComponents?.url else {
            throw ChecklistExportError.invalidBaseURL
        }
        
        return finalURL
    }
    
    private func escapeCSVField(_ field: String) -> String {
        if field.contains(",") || field.contains("\"") || field.contains("\n") || field.contains("\r") {
            let escaped = field.replacingOccurrences(of: "\"", with: "\"\"")
            return "\"\(escaped)\""
        }
        return field
    }
}

// Zero-cost extension to conform TaxonRegistry to TaxonLookup
extension TaxonRegistry: TaxonLookup {}

