// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "MasterOne",
    platforms: [
       .macOS(.v13)
    ],
    dependencies: [
        // 💧 A server-side Swift web framework.
        .package(url: "https://github.com/vapor/vapor.git", from: "4.115.0"),
        // 🗄 An ORM for SQL and NoSQL databases.
        .package(url: "https://github.com/vapor/fluent.git", from: "4.9.0"),
        // 🐬 Fluent driver for MySQL.
        .package(url: "https://github.com/vapor/fluent-mysql-driver.git", from: "4.4.0"),
        // 🍃 An expressive, performant, and extensible templating language built for Swift.
        .package(url: "https://github.com/vapor/leaf.git", from: "4.3.0"),
        // 🔵 Non-blocking, event-driven networking for Swift. Used for custom executors
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.65.0"),
        
        .package(url: "https://github.com/vapor/jwt-kit.git", from: "4.0.0"),
                
        .package(url: "https://github.com/Flight-School/AnyCodable.git", from: "0.6.7")


    ],
    targets: [
        .executableTarget(
            name: "MasterOne",
            dependencies: [
                .product(name: "Fluent", package: "fluent"),
                .product(name: "FluentMySQLDriver", package: "fluent-mysql-driver"),
                .product(name: "Leaf", package: "leaf"),
                .product(name: "Vapor", package: "vapor"),
                .product(name: "NIOCore", package: "swift-nio"),
                .product(name: "NIOPosix", package: "swift-nio"),
                .product(name: "JWTKit", package: "jwt-kit"),
                .product(name: "AnyCodable", package: "AnyCodable"),

            ],
            resources: [
                   // 🔹 Aggiungi questa riga per includere il file delle credenziali
                   .copy("Resources")
               ],
            swiftSettings: swiftSettings
        ),
        .testTarget(
            name: "MasterOneTests",
            dependencies: [
                .target(name: "MasterOne"),
                .product(name: "VaporTesting", package: "vapor"),
            ],
            swiftSettings: swiftSettings
        )
    ]
)

var swiftSettings: [SwiftSetting] { [
    .enableUpcomingFeature("ExistentialAny"),
] }
