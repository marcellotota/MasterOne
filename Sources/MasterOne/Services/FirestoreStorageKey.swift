//
//  FirestoreStorageKey.swift
//  MasterOne
//
//  Created by Tota Marcello on 31/10/25.
//

import Vapor

// 🔹 NON deve essere private, altrimenti configure.swift non la vede
struct FirebaseServiceKey: StorageKey {
    typealias Value = FirebaseService
}
