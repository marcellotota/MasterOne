//
//  Auto.swift
//  MasterOne
//
//  Created by Tota Marcello on 28/10/25.
//

import Vapor
struct Autovettura: Codable {
    let id: String
    let modello: String
    let marca: String
    let fasciaPolicy: String
    let societa: String
    
    init(from firestoreDoc: FirestoreDocument) {
        self.id = firestoreDoc.fields["id"]?.stringValue ?? ""
        self.modello = firestoreDoc.fields["Modello"]?.stringValue ?? ""
        self.marca = firestoreDoc.fields["Marca"]?.stringValue ?? ""
        self.fasciaPolicy = firestoreDoc.fields["Fascia di Policy"]?.stringValue ?? ""
        self.societa = firestoreDoc.fields["Società"]?.stringValue ?? ""
    }
}
