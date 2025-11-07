import Vapor
import JWTKit

struct FirebaseService {
    let serviceAccount: FirebaseServiceAccount

    init() {
        let url = URL(fileURLWithPath: "masterone-7cc57-firebase-adminsdk-fbsvc-fb08682098.json")
        let data = try! Data(contentsOf: url)
        self.serviceAccount = try! JSONDecoder().decode(FirebaseServiceAccount.self, from: data)
    }

    // MARK: - Ottieni Access Token Google (async/await)
    func getGoogleAccessToken(on req: Request) async throws -> String {
        struct TokenResponse: Decodable { let access_token: String }

        // ✅ Crea JWT per Google OAuth
        let jwtPayload = GoogleJWT(serviceAccount: serviceAccount)
        let signer = try JWTSigner.rs256(key: .private(pem: serviceAccount.private_key))
        let jwt = try signer.sign(jwtPayload)

        // ✅ Richiesta POST per ottenere il token
        var headers = HTTPHeaders()
        headers.add(name: .contentType, value: "application/x-www-form-urlencoded")
        let body = "grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=\(jwt)"

        let response = try await req.client.post(URI(string: "https://oauth2.googleapis.com/token"), headers: headers) { reqBody in
            reqBody.body = ByteBuffer(string: body)
        }

        guard response.status == .ok else {
            throw Abort(.internalServerError, reason: "Errore OAuth Google: \(response.status)")
        }

        // ✅ Decodifica body
        guard let buffer = response.body else {
            throw Abort(.internalServerError, reason: "Body vuoto nella risposta OAuth")
        }
        let bodyData = Data(buffer: buffer)
        let tokenResponse = try JSONDecoder().decode(TokenResponse.self, from: bodyData)
        return tokenResponse.access_token
    }

    // MARK: - Leggi raccolta autovetture (async/await)
    func fetchAutovetture(token: String, on req: Request) async throws -> [Autovettura] {
        let url = "https://firestore.googleapis.com/v1/projects/masterone-7cc57/databases/(default)/documents/autovetture"
        var headers = HTTPHeaders()
        headers.add(name: "Authorization", value: "Bearer \(token)")

        let response = try await req.client.get(URI(string: url), headers: headers)

        guard response.status == .ok else {
            throw Abort(.internalServerError, reason: "Errore Firestore: \(response.status)")
        }

        // ✅ Decodifica body
        guard let buffer = response.body else {
            throw Abort(.internalServerError, reason: "Body vuoto nella risposta Firestore")
        }
        let bodyData = Data(buffer: buffer)

        let firestoreResponse = try JSONDecoder().decode(FirestoreListResponse.self, from: bodyData)
        return firestoreResponse.documents.map { doc in
            Autovettura(from: doc) // Assicurati di avere un init che converte FirestoreDocument → Autovettura
        }
    }
}

// MARK: - Modelli Firestore
struct FirestoreListResponse: Decodable {
    let documents: [FirestoreDocument]
}

struct FirestoreDocument: Decodable {
    let name: String
    let fields: [String: FirestoreField]
}

struct FirestoreField: Decodable {
    let stringValue: String?
}
