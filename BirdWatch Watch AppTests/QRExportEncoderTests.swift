import Testing
import Foundation
import Compression
@testable import BirdWatch_Watch_App

struct QRExportEncoderTests {
    @Test func testQRExportEncoderRoundTrip() throws {
        let originalCSV = "Common Name,Genus,Species,Number,Species Comments\nBlack-capped Chickadee,,,3,"
        let baseURL = "https://rdabrunk.github.io/BirdWatch/decoder/"
        
        // When
        let encodedURLString = try QRExportEncoder.encode(csv: originalCSV, baseURL: baseURL)
        
        // Then
        #expect(encodedURLString.hasPrefix(baseURL + "#"))
        
        let components = encodedURLString.components(separatedBy: "#")
        #expect(components.count == 2)
        
        let percentEncodedBase45 = components[1]
        let base45Str = percentEncodedBase45.removingPercentEncoding ?? percentEncodedBase45
        
        // Decode Base45
        let compressedData = try Base45.decode(base45Str)
        
        // Decompress raw deflate
        let decompressedData = try (compressedData as NSData).decompressed(using: .zlib) as Data
        let decompressedString = String(data: decompressedData, encoding: .utf8)
        
        #expect(decompressedString == originalCSV)
    }
}
