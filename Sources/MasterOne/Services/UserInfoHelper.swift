
import Foundation
import Vapor

struct UserInfoHelper {
    
    /// Decodes a JWT token and returns a dictionary of user info
    static func decodeJWT(_ token: String) -> [String: Any]? {
        let segments = token.split(separator: ".")
        guard segments.count == 3 else { return nil }
        
        let payloadSegment = segments[1]
        var base64 = String(payloadSegment)
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        
        // Padding
        while base64.count % 4 != 0 {
            base64 += "="
        }
        
        guard let data = Data(base64Encoded: base64),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        
        return json
    }
    
    /// Extracts user details from JWT and returns a Leaf context dictionary
    static func createLeafContext(from token: String) -> [String: String] {
        guard let userInfo = decodeJWT(token) else {
            return ["userName": "Utente", "email": "", "preferredUsername": "", "oid": ""]
        }
        
        let name = userInfo["name"] as? String ?? "Utente"
        let preferredUsername = userInfo["preferred_username"] as? String ?? ""
        let email = userInfo["email"] as? String ?? ""
        let oid = userInfo["oid"] as? String ?? ""
        
        return [
            "userName": name,
            "email": email,
            "preferredUsername": preferredUsername,
            "oid": oid
        ]
    }
}
