//
//  DereferencedResponse.swift
//  
//
//  Created by Mathew Polzin on 6/18/20.
//

/// An `OpenAPI.Response` type that guarantees
/// its `headers` and `content` are inlined instead of
/// referenced.
@dynamicMemberLookup
public struct DereferencedResponse: Equatable {
    public let underlyingResponse: OpenAPI.Response
    public let headers: DereferencedHeader.Map?
    public let content: DereferencedContent.Map

    public subscript<T>(dynamicMember path: KeyPath<OpenAPI.Response, T>) -> T {
        return underlyingResponse[keyPath: path]
    }

    /// Create a `DereferencedResponse` if all references in the
    /// response can be found in the given Components Object.
    ///
    /// - Throws: `ReferenceError.cannotLookupRemoteReference` or
    ///     `MissingReferenceError.referenceMissingOnLookup(name:)` depending
    ///     on whether an unresolvable reference points to another file or just points to a
    ///     component in the same file that cannot be found in the Components Object.
    public init(response: OpenAPI.Response, resolvingIn components: OpenAPI.Components) throws {
        self.headers = try response.headers?.mapValues { header in
            try DereferencedHeader(
                header: try components.forceDereference(header),
                resolvingIn: components
            )
        }

        self.content = try response.content.mapValues { content in
            try DereferencedContent(content: content, resolvingIn: components)
        }

        self.underlyingResponse = response
    }

    public typealias Map = OrderedDictionary<OpenAPI.Response.StatusCode, DereferencedResponse>
}
