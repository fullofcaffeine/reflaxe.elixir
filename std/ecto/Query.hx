package ecto;

#if (elixir || reflaxe_runtime)

import haxe.functional.Result;
// Note: Avoid depending on compiler-time NameUtils at runtime; use Elixir's Macro.underscore

/**
 * Type-safe Ecto Query API for Haxe→Elixir
 * 
 * Provides a practical, type-safe wrapper around Ecto.Query functions.
 * Uses __elixir__() strategically to generate idiomatic Elixir queries
 * while maintaining full type safety in Haxe.
 */

/**
 * Represents an Ecto query with type information.
 * This is an opaque type that wraps the actual Elixir query struct.
 */
abstract EctoQuery<T>(Dynamic) {
    public inline function new(query: Dynamic) {
        this = query;
    }
    
    /**
     * Add a where clause to the query
     * @param _field The field name to filter on (currently unused - needs API redesign)
     * @param value The value to compare against
     * @return The query with the where clause added
     * @deprecated This API needs redesign to properly handle dynamic field queries
     */
    public function where<V>(fieldName: String, value: V): EctoQuery<T> {
        // Use field/2 with a binding and convert string to existing atom
        // Avoids atom leaks and matches Ecto expectations
        var newQuery = untyped __elixir__(
            '(require Ecto.Query; Ecto.Query.where({0}, [q], field(q, ^String.to_existing_atom(Macro.underscore({1}))) == ^{2}))',
            this, fieldName, value
        );
        return new EctoQuery<T>(newQuery);
    }
    
    /**
     * Preload associations
     * @param associations The associations to preload
     * @return The query with preload added
     */
    public function preload(associations: Dynamic): EctoQuery<T> {
        var newQuery = untyped __elixir__(
            '(require Ecto.Query; Ecto.Query.preload({0}, ^{1}))',
            this, associations
        );
        return new EctoQuery<T>(newQuery);
    }
    
    /**
     * Add an order_by clause to the query
     * @param field The field to order by
     * @param direction Either "asc" or "desc"
     * @return The query with the order_by clause added
     */
    public function orderBy(field: String, direction: String = "asc"): EctoQuery<T> {
        // Use field/2 with a binding and convert string to existing atom
        var newQuery = if (direction == "desc") {
            untyped __elixir__('(require Ecto.Query; Ecto.Query.order_by({0}, [q], [desc: field(q, ^String.to_existing_atom(Macro.underscore({1})))]))', this, field);
        } else {
            untyped __elixir__('(require Ecto.Query; Ecto.Query.order_by({0}, [q], [asc: field(q, ^String.to_existing_atom(Macro.underscore({1})))]))', this, field);
        }
        return new EctoQuery<T>(newQuery);
    }

    // Note: Use NameUtils.toSnakeCase instead of duplicating logic
    
    /**
     * Add a limit to the query
     * @param count The maximum number of records to return
     * @return The query with the limit applied
     */
    public function limit(count: Int): EctoQuery<T> {
        // Using import inside the expression to access the macro
        // Using require to make the macro available without importing all functions
        var newQuery = untyped __elixir__('(require Ecto.Query; Ecto.Query.limit({0}, ^{1}))', this, count);
        return new EctoQuery<T>(newQuery);
    }
    
    /**
     * Add an offset to the query
     * @param count The number of records to skip
     * @return The query with the offset applied
     */
    public function offset(count: Int): EctoQuery<T> {
        // Using import inside the expression to access the macro
        // Using require to make the macro available without importing all functions
        var newQuery = untyped __elixir__('(require Ecto.Query; Ecto.Query.offset({0}, ^{1}))', this, count);
        return new EctoQuery<T>(newQuery);
    }
    
    /**
     * Get the underlying Elixir query struct
     * Used internally when passing to Repo functions
     */
    @:allow(ecto)
    public inline function toElixirQuery(): Dynamic {
        return this;
    }
}

/**
 * Internal implementation type for the Elixir query struct
 */
private typedef EctoQueryImpl = Dynamic;

/**
 * Main Query module with factory methods for creating queries
 */
class Query {
    /**
     * Create a new query from a schema
     * @param schema The schema class to query
     * @return A new EctoQuery instance
     */
    public static function from<T>(schema: Class<T>): EctoQuery<T> {
        // CRITICAL: Ecto.Query.from is a macro that needs the module at compile time
        // We use Ecto.Queryable.to_query/1 which can accept runtime module values
        // This is the recommended way to create queries dynamically
        return new EctoQuery<T>(untyped __elixir__('Ecto.Queryable.to_query({0})', schema));
    }
    
    /**
     * Create a where clause with multiple conditions
     * @param query The query to add conditions to
     * @param conditions Map of field names to values
     * @return The query with where conditions added
     */
    public static function whereAll<T>(query: EctoQuery<T>, conditions: Map<String, Dynamic>): EctoQuery<T> {
        // Use Enum.reduce to build up the query with field/2 function for dynamic field access
        // This is the idiomatic way to handle dynamic field names in Ecto
        var elixirQuery = untyped __elixir__(
            'Enum.reduce(Map.to_list({0}), {1}, fn {field_name, value}, acc ->
                import Ecto.Query
                from(q in acc, where: field(q, ^String.to_existing_atom(field_name)) == ^value)
            end)',
            conditions, query.toElixirQuery()
        );
        return new EctoQuery<T>(elixirQuery);
    }
}

#end
