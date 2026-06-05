/**
 * API Service Template for Mobile Agent (Swift iOS Native)
 *
 * This file wraps the generated `Client` produced by `swift-openapi-generator`
 * from `Core/Networking/openapi.yaml`. It is the **only** place that calls the
 * backend API — never construct `URLRequest` or decode `Data` manually for
 * endpoints that exist in the OpenAPI spec.
 *
 * Dependencies (all auto-generated at `swift build` time):
 *   - `Client`       — generated root type; one instance per app
 *   - `Operations`   — one namespace per operation (e.g., `Operations.listTodos`)
 *   - `Components`   — shared schema types (e.g., `Components.Schemas.Todo`)
 *
 * File layout (split into real files in production):
 *   Core/Networking/
 *     openapi.yaml                      <- vendored OpenAPI spec (source of truth)
 *     openapi-generator-config.yaml     <- generator config (types + client, public)
 *     APIClient.swift                   <- URLSession transport + auth middleware wiring
 *     TodoService.swift                 <- this file
 */

// ---------------------------------------------------------------------------
// Core/Networking/TodoService.swift
// ---------------------------------------------------------------------------

import Foundation
import OpenAPIRuntime

/// Typed errors surfaced by `TodoService`.
public enum TodoServiceError: Error, LocalizedError {
    case notFound
    case conflict
    case undocumented(statusCode: Int)

    public var errorDescription: String? {
        switch self {
        case .notFound:          return "The requested todo was not found."
        case .conflict:          return "A todo with that title already exists."
        case .undocumented(let code): return "Unexpected server response: HTTP \(code)."
        }
    }
}

/// CRUD service for the `/todos` resource.
///
/// Depends on `Client` (generated from `Core/Networking/openapi.yaml`).
/// Inject via `AppDependencies` at app startup; never instantiate directly in views.
public final class TodoService {
    private let client: Client

    public init(client: Client) {
        self.client = client
    }

    // MARK: - List

    /// Returns all todos for the authenticated user.
    public func listTodos() async throws -> [Components.Schemas.Todo] {
        let response = try await client.listTodos(.init())
        switch response {
        case .ok(let ok):
            return try ok.body.json
        case .undocumented(let statusCode, _):
            throw TodoServiceError.undocumented(statusCode: statusCode)
        }
    }

    // MARK: - Create

    /// Creates a new todo with the given title.
    public func createTodo(title: String) async throws -> Components.Schemas.Todo {
        let body = Components.Schemas.CreateTodoRequest(title: title)
        let response = try await client.createTodo(.init(body: .json(body)))
        switch response {
        case .created(let created):
            return try created.body.json
        case .conflict:
            throw TodoServiceError.conflict
        case .undocumented(let statusCode, _):
            throw TodoServiceError.undocumented(statusCode: statusCode)
        }
    }

    // MARK: - Toggle

    /// Toggles the `completed` flag on the todo with the given ID.
    public func toggleTodo(id: String) async throws -> Components.Schemas.Todo {
        let response = try await client.toggleTodo(.init(path: .init(id: id)))
        switch response {
        case .ok(let ok):
            return try ok.body.json
        case .notFound:
            throw TodoServiceError.notFound
        case .undocumented(let statusCode, _):
            throw TodoServiceError.undocumented(statusCode: statusCode)
        }
    }

    // MARK: - Delete

    /// Permanently deletes the todo with the given ID.
    public func deleteTodo(id: String) async throws {
        let response = try await client.deleteTodo(.init(path: .init(id: id)))
        switch response {
        case .noContent:
            return
        case .notFound:
            throw TodoServiceError.notFound
        case .undocumented(let statusCode, _):
            throw TodoServiceError.undocumented(statusCode: statusCode)
        }
    }
}
