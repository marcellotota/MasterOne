import Leaf
import Vapor

// Configures your application
public func configure(_ app: Application) async throws {
    
    // 🔹 Imposta la porta automaticamente se fornita da Render
    if let port = Environment.get("PORT").flatMap(Int.init) {
        app.http.server.configuration.port = port
    } else {
        app.http.server.configuration.port = 8085 // fallback locale
    }
    
    // Configura Leaf come motore di template
    app.views.use(.leaf)
    
    // Servi i file statici da /Public (css, js, immagini)
    app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))
    
    // Registrazione delle route
    try routes(app)
}
