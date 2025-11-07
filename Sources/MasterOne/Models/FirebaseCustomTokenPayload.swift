//
//  FirebaseCustomTokenPayload.swift
//  MasterOne
//
//  Created by Tota Marcello on 31/10/25.
//


import JWTKit

struct FirebaseCustomTokenPayload: JWTPayload {
    let iss: String
    let sub: String
    let aud: String
    let iat: Int
    let exp: Int
    let uid: String

    func verify(using signer: JWTSigner) throws {
        // Basic verification (puoi aggiungere controlli se vuoi)
    }
}
