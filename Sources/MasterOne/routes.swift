import Fluent
import Vapor
import Leaf

func routes(_ app: Application) throws {
    
    // Index page
    app.get { req -> EventLoopFuture<View> in
        let context: [String: String] = ["title": "Home", "currentPage": "home"]
        return req.view.render("index", context)
    }
    
    // About page
    app.get("about") { req -> EventLoopFuture<View> in
        let context: [String: String] = ["title": "About", "currentPage": "about"]
        return req.view.render("about", context)
    }
   
    // Auto page
    struct ParcoAutoContext: Codable {
        var parcoAuto = [Auto]()
    }
    struct AutovettureContext: Codable {
        let title: String
        let currentPage: String
        let parcoAuto: [Auto]
    }
    app.get("autovetture") { req -> EventLoopFuture<View> in
        let context = AutovettureContext(
            title: "Autovetture",
            currentPage: "autovetture",
            parcoAuto: autoTest
        )
        return req.view.render("autovetture", context)
    }
    
    // Chilometri page
    app.get("chilometri") { req -> EventLoopFuture<View> in
        let context: [String: String] = ["title": "Chilometri", "currentPage": "chilometri"]
        return req.view.render("chilometri", context)
    }
    
    //Pagina Test
    app.get("test") { req in
        return req.view.render("test")
    }
    
// Fine aggiunta pagine
    app.get("hello") { req async -> String in
        "Hello, world!"
    }

    try app.register(collection: TodoController())
}
