import Vapor
import Leaf
import AsyncHTTPClient

struct TokenResponse: Content {
    let access_token: String?
    let id_token: String?
    let refresh_token: String?
    let error: String?
    let error_description: String?
}

// MARK: - Context per la view "autovetture.leaf"
struct AutovettureContext: Codable {
    let title: String
    let currentPage: String
    let autovetture: [Autovettura]
    let userName: String
    let email: String
    let preferredUsername: String
    let oid: String
    let isAdmin: String
    let hasCar: String
}

func routes(_ app: Application) throws {

    // MARK: - Logout
    app.get("logout") { req -> Response in
        req.session.destroy()
        return req.redirect(to: "/login")
    }
    
    // MARK: - Login Azure
    app.get("login") { req async throws -> View in
        let clientId = AzureConfig.AZURE_CLIENT_ID
        let tenantId = AzureConfig.AZURE_TENANT_ID

        let redirectUri: String
        if req.application.environment == .production {
            redirectUri = AzureConfig.AZURE_REDIRECT_URI_PROD
        } else {
            redirectUri = AzureConfig.AZURE_REDIRECT_URI_DEV
        }

        let baseURL = "https://login.microsoftonline.com/\(tenantId)/oauth2/v2.0/authorize"
        let query = "client_id=\(clientId)&response_type=code&redirect_uri=\(redirectUri.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? redirectUri)&response_mode=query&scope=openid%20profile%20offline_access%20User.Read%20GroupMember.Read.All"
        let authURL = "\(baseURL)?\(query)"

        let context: [String: String] = ["authURL": authURL]
        return try await req.view.render("login", context)
    }

    // MARK: - Callback Azure
    app.get("auth", "callback") { req async throws -> Response in
        guard let code = try? req.query.get(String.self, at: "code") else {
            throw Abort(.badRequest, reason: "Codice di autorizzazione mancante")
        }

        let clientId = AzureConfig.AZURE_CLIENT_ID
        let clientSecret = AzureConfig.AZURE_CLIENT_SECRET
        let tenantId = AzureConfig.AZURE_TENANT_ID

        let redirectUri: String
        if req.application.environment == .production {
            redirectUri = AzureConfig.AZURE_REDIRECT_URI_PROD
        } else {
            redirectUri = AzureConfig.AZURE_REDIRECT_URI_DEV
        }

        let tokenUrl = URI(string: "https://login.microsoftonline.com/\(tenantId)/oauth2/v2.0/token")

        let body: [String: String] = [
            "client_id": clientId,
            "client_secret": clientSecret,
            "scope": "openid profile offline_access User.Read GroupMember.Read.All",
            "code": code,
            "redirect_uri": redirectUri,
            "grant_type": "authorization_code"
        ]

        let headers = HTTPHeaders([("Content-Type", "application/x-www-form-urlencoded")])

        let response = try await req.client.post(tokenUrl, headers: headers) { tokenReq in
            try tokenReq.content.encode(body, as: .urlEncodedForm)
        }

        guard let buffer = response.body else {
            throw Abort(.internalServerError, reason: "Risposta vuota dal server Azure")
        }

        let responseString = buffer.getString(at: buffer.readerIndex, length: buffer.readableBytes) ?? ""
        guard let data = responseString.data(using: .utf8) else {
            throw Abort(.internalServerError, reason: "Impossibile convertire la risposta in dati")
        }

        let tokenResponse = try JSONDecoder().decode(TokenResponse.self, from: data)

        if let error = tokenResponse.error {
            throw Abort(.unauthorized, reason: "Errore Azure: \(tokenResponse.error_description ?? error)")
        }

        guard let accessToken = tokenResponse.access_token else {
            throw Abort(.unauthorized, reason: "Token non ricevuto")
        }

        req.session.data["userToken"] = accessToken

        let userInfo = UserInfoHelper.createLeafContext(from: accessToken)
        let displayName = userInfo["userName"] ?? ""

        // ✅ Controllo membership gruppi
        let isAdmin = try await checkUserGroup(
            token: accessToken,
            groupId: "65b22736-2659-4fb0-9894-94e77199d2c0", // GPZ-Autovetture-Admin
            req: req
        )

        let hasCar = try await checkUserGroup(
            token: accessToken,
            groupId: "42344737-627f-4880-8bd4-658fee2ea2d2", // GPZ-Autovetture
            req: req
        )

        // ✅ Salva in sessione
        req.session.data["isAdmin"] = isAdmin ? "true" : "false"
        req.session.data["hasCar"] = hasCar ? "true" : "false"
        req.session.data["user"] = displayName

        // ✅ Redirect condizionale
        if !isAdmin && !hasCar {
            return req.redirect(to: "/noCar")
        }

        return req.redirect(to: "/")
    }

    // MARK: - Gruppi protetti
    let protected = app.grouped(AuthMiddleware())

    // 🔹 Admin Only
    let adminOnly = protected.grouped(RoleMiddleware(level: .adminOnly))

    // 🔹 Car User (assegnatario o admin)
    let carUser = protected.grouped(RoleMiddleware(level: .carUser))

    // 🔹 Guest (chiunque autenticato, inclusi noCar)
    let guest = protected.grouped(RoleMiddleware(level: .guest))

    // MARK: - Helper per contesto Leaf
    @Sendable func userContext(from req: Request) -> [String: String] {
        var context: [String: String] = [
            "isAdmin": req.session.data["isAdmin"] ?? "false",
            "hasCar": req.session.data["hasCar"] ?? "false"
        ]
        let token = req.session.data["userToken"] ?? ""
        let userInfo = UserInfoHelper.createLeafContext(from: token)
        context.merge(userInfo) { (_, new) in new }
        return context
    }

    // MARK: - ROTTE

    // ✅ Home (assegnatario o admin)
    carUser.get { req async throws -> View in
        var context: [String: String] = ["title": "Home", "currentPage": "home"]
        context.merge(userContext(from: req)) { _, new in new }
        return try await req.view.render("index", context)
    }

    // ✅ About (assegnatario o admin)
    carUser.get("about") { req async throws -> View in
        var context: [String: String] = ["title": "About", "currentPage": "about"]
        context.merge(userContext(from: req)) { _, new in new }
        return try await req.view.render("about", context)
    }

    // ✅ Autovetture (solo admin)
    
    adminOnly.get("autovetture", use: autovettureHandler)

    // ✅ Chilometri (assegnatario o admin)
    carUser.get("chilometri") { req async throws -> View in
        var context: [String: String] = ["title": "Chilometri", "currentPage": "chilometri"]
        context.merge(userContext(from: req)) { _, new in new }
        return try await req.view.render("chilometri", context)
    }

    // ✅ Test (solo admin)
    adminOnly.get("test") { req async throws -> View in
        var context: [String: String] = ["title": "Test", "currentPage": "test"]
        context.merge(userContext(from: req)) { _, new in new }
        return try await req.view.render("test", context)
    }

    // ✅ Hello (solo autenticati, qualsiasi ruolo)
    guest.get("hello") { req async throws -> String in
        "Hello, \(userContext(from: req)["userName"] ?? "Utente")!"
    }

    // ✅ Pagina noCar (solo per chi non ha auto né admin)
    guest.get("noCar") { req async throws -> View in
        var context = userContext(from: req)
        context["title"] = "Nessuna Auto"
        return try await req.view.render("noCar", context)
    }
}


// MARK: - Funzioni helper

func checkUserGroup(token: String, groupId: String, req: Request) async throws -> Bool {
    let url = URI(string: "https://graph.microsoft.com/v1.0/me/memberOf")
    var clientRequest = ClientRequest(method: .GET, url: url)
    clientRequest.headers.add(name: .authorization, value: "Bearer \(token)")
    
    let response = try await req.client.send(clientRequest)
    guard response.status == .ok else {
        req.logger.warning("Graph API returned status \(response.status)")
        return false
    }

    // ✅ Corretto modo per ottenere il corpo come Data
    guard let buffer = response.body else {
        req.logger.warning("No response body from Graph API")
        return false
    }
    let data = Data(buffer.readableBytesView)

    // ✅ Parsing JSON con tipizzazione esplicita
    guard
        let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
        let groups = json["value"] as? [[String: Any]]
    else {
        req.logger.warning("Invalid JSON structure from Graph API")
        return false
    }

    // ✅ Verifica per ID gruppo
    return groups.contains { ($0["id"] as? String) == groupId }
}



func checkCarAssignment(for req: Request, displayName: String) async throws -> Bool {
    let firebaseService = FirebaseService()
    let googleToken = try await firebaseService.getGoogleAccessToken(on: req)

    let url = "https://firestore.googleapis.com/v1/projects/masterone-7cc57/databases/(default)/documents:runQuery"

    let queryBody: [String: Any] = [
        "structuredQuery": [
            "from": [["collectionId": "autovetture"]],
            "where": [
                "fieldFilter": [
                    "field": ["fieldPath": "displayName"],
                    "op": "EQUAL",
                    "value": ["stringValue": displayName]
                ]
            ]
        ]
    ]

    let jsonData = try JSONSerialization.data(withJSONObject: queryBody)

    var request = HTTPClientRequest(url: url)
    request.method = .POST
    request.headers.add(name: "Authorization", value: "Bearer \(googleToken)")
    request.headers.add(name: "Content-Type", value: "application/json")
    request.body = .bytes(ByteBuffer(data: jsonData))

    let client = HTTPClient(eventLoopGroupProvider: .shared(req.application.eventLoopGroup))
    defer { _ = client.shutdown() }

    let response = try await client.execute(request, timeout: .seconds(10))
    return response.status == .ok
}

@Sendable
func autovettureHandler(_ req: Request) async throws -> View {
    let firebaseService = FirebaseService()
    let googleToken = try await firebaseService.getGoogleAccessToken(on: req)
    let autos = try await firebaseService.fetchAutovetture(token: googleToken, on: req)

    let userInfo = req.userContext()

    let context = AutovettureContext(
        title: "Autovetture",
        currentPage: "autovetture",
        autovetture: autos,
        userName: userInfo["userName"] ?? "",
        email: userInfo["email"] ?? "",
        preferredUsername: userInfo["preferredUsername"] ?? "",
        oid: userInfo["oid"] ?? "",
        isAdmin: userInfo["isAdmin"] ?? "false",
        hasCar: userInfo["hasCar"] ?? "false"
    )

    return try await req.view.render("autovetture", context)
}


extension Request {
    func userContext() -> [String: String] {
        var context: [String: String] = [
            "isAdmin": self.session.data["isAdmin"] ?? "false",
            "hasCar": self.session.data["hasCar"] ?? "false"
        ]
        let token = self.session.data["userToken"] ?? ""
        let userInfo = UserInfoHelper.createLeafContext(from: token)
        context.merge(userInfo) { (_, new) in new }
        return context
    }
}
