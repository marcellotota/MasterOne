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
    
    // ✅ Abilita le sessioni
    app.middleware.use(app.sessions.middleware)
    // ✅ Configura il provider di sessione (in-memory per ora)
    app.sessions.use(.memory)
    
    // 🔹 Inizializza Firestore
    let firebaseService = FirebaseService()
    app.storage[FirebaseServiceKey.self] = firebaseService
    
    
    // Configura Leaf come motore di template
    app.views.use(.leaf)
    
    
    
    
    // Servi i file statici da /Public (css, js, immagini)
    app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))
    
    // MARK: - Routes
    // Registrazione delle route
    try routes(app)
}
