import Foundation
import Compression

public struct QRExportEncoder {
    public static func encode(csv: String, baseURL: String) throws -> String {
        let data = Data(csv.utf8)
        let compressed = try (data as NSData).compressed(using: .zlib) as Data
        let base45String = Base45.encode(compressed)
        let encodedBase45 = base45String.addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed) ?? base45String
        return "\(baseURL)#\(encodedBase45)"
    }
}
