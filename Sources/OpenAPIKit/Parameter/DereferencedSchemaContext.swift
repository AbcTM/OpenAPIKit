//
//  DereferencedSchemaContext.swift
//  
//
//  Created by Mathew Polzin on 6/18/20.
//

/// A `SchemaContext` type that guarantees its
/// `schema` and `examples` are inlined instead
/// of referenced.
@dynamicMemberLookup
public struct DereferencedSchemaContext: Equatable {
    /// The original `OpenAPI.Parameter.SchemaContext` prior to being dereferenced.
    public let underlyingSchemaContext: OpenAPI.Parameter.SchemaContext
    /// The dereferenced schema.
    public let schema: DereferencedJSONSchema
    /// The dereferenced examples (if defined).
    public let examples: OrderedDictionary<String, OpenAPI.Example>?
    /// The dereferenced example (if defined).
    ///
    /// This will expose the first example in the `examples`
    /// property if that is defined. OpenAPI also allows defining
    /// a single `example` which results in this property being
    /// non-`nil` while the `examples` property is `nil`.
    public let example: AnyCodable?

    public subscript<T>(dynamicMember path: KeyPath<OpenAPI.Parameter.SchemaContext, T>) -> T {
        return underlyingSchemaContext[keyPath: path]
    }

    /// Create a `DereferencedSchemaContext` if all references in the
    /// content can be found in the given Components Object.
    ///
    /// - Throws: `ReferenceError.cannotLookupRemoteReference` or
    ///     `MissingReferenceError.referenceMissingOnLookup(name:)` depending
    ///     on whether an unresolvable reference points to another file or just points to a
    ///     component in the same file that cannot be found in the Components Object.
    public init(_ schemaContext: OpenAPI.Parameter.SchemaContext, resolvingIn components: OpenAPI.Components) throws {
        self.schema = try DereferencedJSONSchema(
            try components.forceDereference(schemaContext.schema),
            resolvingIn: components
        )
        let examples = try schemaContext.examples?.mapValues { try components.forceDereference($0) }
        self.examples = examples

        self.example = examples.flatMap(OpenAPI.Content.firstExample(from:))
            ?? schemaContext.example

        self.underlyingSchemaContext = schemaContext
    }
}
