import Testing
import Foundation
@testable import BirdWatch_Watch_App

struct Base45Tests {
    @Test func testRoundTrip() throws {
        let input = "Hello!! World 12345"
        let data = Data(input.utf8)
        
        let encoded = Base45.encode(data)
        
        // Ensure only valid Base45 characters are produced
        let validCharset = CharacterSet(charactersIn: "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ $%*+-./:")
        for char in encoded {
            let unicodeScalars = char.unicodeScalars
            #expect(unicodeScalars.allSatisfy { validCharset.contains($0) })
        }
        
        let decoded = try Base45.decode(encoded)
        let decodedString = String(data: decoded, encoding: .utf8)
        
        #expect(decodedString == input)
    }
}
