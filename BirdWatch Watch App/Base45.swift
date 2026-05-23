import Foundation

public enum Base45Error: Error {
    case invalidCharacter(Character)
    case malformedInput
    case overflow
}

public struct Base45 {
    private static let alphabet = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ $%*+-./:")
    private static let reverseAlphabet: [Character: Int] = {
        var dict: [Character: Int] = [:]
        for (index, char) in alphabet.enumerated() {
            dict[char] = index
        }
        return dict
    }()
    
    public static func encode(_ data: Data) -> String {
        var result = ""
        let count = data.count
        var i = 0
        
        while i < count {
            if i + 1 < count {
                let a = Int(data[i])
                let b = Int(data[i + 1])
                let val = (a * 256) + b
                
                let c = val % 45
                let d = (val / 45) % 45
                let e = (val / 45 / 45) % 45
                
                result.append(alphabet[c])
                result.append(alphabet[d])
                result.append(alphabet[e])
                i += 2
            } else {
                let a = Int(data[i])
                let c = a % 45
                let d = (a / 45) % 45
                
                result.append(alphabet[c])
                result.append(alphabet[d])
                i += 1
            }
        }
        
        return result
    }
    
    public static func decode(_ string: String) throws -> Data {
        var result = Data()
        var indices: [Int] = []
        
        for char in string {
            guard let val = reverseAlphabet[char] else {
                throw Base45Error.invalidCharacter(char)
            }
            indices.append(val)
        }
        
        let count = indices.count
        if count % 3 == 1 {
            throw Base45Error.malformedInput
        }
        
        var i = 0
        while i < count {
            if i + 2 < count {
                let c = indices[i]
                let d = indices[i + 1]
                let e = indices[i + 2]
                let val = c + d * 45 + e * 45 * 45
                
                guard val <= 65535 else {
                    throw Base45Error.overflow
                }
                
                result.append(UInt8((val >> 8) & 0xFF))
                result.append(UInt8(val & 0xFF))
                i += 3
            } else {
                let b = indices[i]
                let c = indices[i + 1]
                let val = b + c * 45
                
                guard val <= 255 else {
                    throw Base45Error.overflow
                }
                
                result.append(UInt8(val))
                i += 2
            }
        }
        
        return result
    }
}
