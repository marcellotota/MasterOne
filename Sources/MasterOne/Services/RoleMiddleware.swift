//
//  RoleMiddleware.swift
//  MasterOne
//
//  Created by Tota Marcello on 06/11/25.
//


import Vapor

struct RoleMiddleware: AsyncMiddleware {
    enum AccessLevel {
        case adminOnly
        case carUser
        case guest
    }

    let level: AccessLevel

    func respond(to request: Request, chainingTo next: any AsyncResponder) async throws -> Response {
        let isAdmin = request.session.data["isAdmin"] == "true"
        let hasCar = request.session.data["hasCar"] == "true"

        switch level {
        case .adminOnly:
            guard isAdmin else { return request.redirect(to: "/") }
        case .carUser:
            guard isAdmin || hasCar else { return request.redirect(to: "/noCar") }
        case .guest:
            break
        }

        return try await next.respond(to: request)
    }
}