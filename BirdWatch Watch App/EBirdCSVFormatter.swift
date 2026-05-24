import Foundation

@MainActor
public struct EBirdCSVFormatter {
    public static func format(_ checklist: Checklist, registry: TaxonRegistry) -> String {
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
        
        let distanceString: String
        if checklist.protocolType == .traveling {
            distanceString = String(format: "%.2f", checklist.distanceMiles ?? 0.0)
        } else {
            distanceString = ""
        }
        
        for sighting in checklist.sightings {
            let taxon = registry.taxon(forAlphaCode: sighting.alphaCode)
            let commonName = taxon?.commonName ?? "Unknown Species"
            let tally = sighting.tally
            
            let escapedCommon = escapeCSVField(commonName)
            
            let fields: [String] = [
                escapedCommon, // 1. Common Name
                "",            // 2. Genus
                "",            // 3. Species
                "\(tally)",    // 4. Number
                "",            // 5. Species Comments
                "My Location", // 6. Location Name
                latString,     // 7. Latitude
                lonString,     // 8. Longitude
                dateString,    // 9. Date
                timeString,    // 10. Start Time
                "",            // 11. State/Province
                "",            // 12. Country Code
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
    
    static func escapeCSVField(_ field: String) -> String {
        if field.contains(",") || field.contains("\"") || field.contains("\n") || field.contains("\r") {
            let escaped = field.replacingOccurrences(of: "\"", with: "\"\"")
            return "\"\(escaped)\""
        }
        return field
    }
}
