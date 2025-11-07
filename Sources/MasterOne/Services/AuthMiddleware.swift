//
//  AuthMiddleware.swift
//  MasterOne
//
//  Created by Tota Marcello on 03/11/25.
//



import Vapor

struct AuthMiddleware: AsyncMiddleware {
    func respond(to request: Request, chainingTo next: any AsyncResponder) async throws -> Response {
        // ✅ Permetti accesso libero a login e callback
        let path = request.url.path
        if path == "/login" || path.hasPrefix("/auth") {
            return try await next.respond(to: request)
        }

        // ✅ Verifica sessione utente
        guard let _ = request.session.data["userToken"] else {
            return request.redirect(to: "/login")
        }

        return try await next.respond(to: request)
    }
}
