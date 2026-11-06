// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "DailyTodo",
    platforms: [
        .macOS(.v14)
    ],
    targets: [
        .target(
            name: "DailyTodoCore",
            path: "Sources/DailyTodoCore"
        ),
        .executableTarget(
            name: "DailyTodo",
            dependencies: ["DailyTodoCore"],
            path: "Sources/DailyTodo"
        ),
        .executableTarget(
            name: "DailyTodoChecks",
            dependencies: ["DailyTodoCore"],
            path: "Sources/DailyTodoChecks"
        )
    ]
)
