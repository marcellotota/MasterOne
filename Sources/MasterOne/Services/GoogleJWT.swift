//
//  GoogleJWT.swift
//  MasterOne
//
//  Created by Tota Marcello on 31/10/25.
//


// Sources/App/Services/GoogleJWT.swift

import Foundation
import JWTKit

struct GoogleJWT: JWTPayload {
    let iss: String
    let scope: String
    let aud: String
    let exp: Int
    let iat: Int

    func verify(using signer: JWTSigner) throws {}

    init(serviceAccount: FirebaseServiceAccount) {
        let now = Int(Date().timeIntervalSince1970)
        self.iss = serviceAccount.client_email
        self.scope = "https://www.googleapis.com/auth/datastore https://www.googleapis.com/auth/userinfo.email"
        self.aud = serviceAccount.token_uri
        self.iat = now
        self.exp = now + 3600
    }
}