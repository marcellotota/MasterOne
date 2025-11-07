//
//  AzureConfig.swift
//  MasterOne
//
//  Created by Tota Marcello on 06/11/25.
//

import Vapor

enum AzureConfig {
    static let AZURE_CLIENT_ID =  "f0f876b8-e065-45d8-8dfc-64c1b9bc04db"
    static let AZURE_TENANT_ID = "2c84adf0-c372-442d-81e4-b1edbd0350e6"
    static let AZURE_REDIRECT_URI_DEV = "http://localhost:8085/auth/callback"
    static let AZURE_REDIRECT_URI_PROD = "https://masterone.onrender.com/auth/callback"
    static let AZURE_CLIENT_SECRET = "-vd8Q~G.C.pfu7.WSzlhg8sAly.aWB_~JCmelaGn"

    static let scopes = "openid profile email offline_access User.Read GroupMember.Read.All"
}
