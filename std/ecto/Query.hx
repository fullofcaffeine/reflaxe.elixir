package ecto;

#if (elixir || reflaxe_runtime)

import haxe.functional.Result;

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
     * @param field The field name to filter on
     * @param value The value to compare against
     * @return The query with the where clause added
     */
    public function where<V>(field: String, value: V): EctoQuery<T> {
        var newQuery = untyped __elixir__('Ecto.Query.where({0}, [{1}: {2}])', this, field, value);
        return new EctoQuery<T>(newQuery);
    }
    
    /**
     * Add an order_by clause to the query
     * @param field The field to order by
     * @param direction Either "asc" or "desc"
     * @return The query with the order_by clause added
     */
    public function orderBy(field: String, direction: String = "asc"): EctoQuery<T> {
        // Build the order_by clause with proper direction atom
        var newQuery = if (direction == "desc") {
            untyped __elixir__('Ecto.Query.order_by({0}, [desc: {1}])', this, field);
        } else {
            untyped __elixir__('Ecto.Query.order_by({0}, [asc: {1}])', this, field);
        }
        return new EctoQuery<T>(newQuery);
    }
    
    /**
     * Add a limit to the query
     * @param count The maximum number of records to return
     * @return The query with the limit applied
     */
    public function limit(count: Int): EctoQuery<T> {
        var newQuery = untyped __elixir__('Ecto.Query.limit({0}, {1})', this, count);
        return new EctoQuery<T>(newQuery);
    }
    
    /**
     * Add an offset to the query
     * @param count The number of records to skip
     * @return The query with the offset applied
     */
    public function offset(count: Int): EctoQuery<T> {
        var newQuery = untyped __elixir__('Ecto.Query.offset({0}, {1})', this, count);
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
        var query = untyped __elixir__('Ecto.Query.from({0})', schema);
        return new EctoQuery<T>(query);
    }
    
    /**
     * Create a where clause with multiple conditions
     * @param query The query to add conditions to
     * @param conditions Map of field names to values
     * @return The query with where conditions added
     */
    public static function whereAll<T>(query: EctoQuery<T>, conditions: Map<String, Dynamic>): EctoQuery<T> {
        // Use Elixir's Enum.reduce to iterate over Map entries properly
        // This avoids Haxe's iterator desugaring issues
        var elixirQuery = untyped __elixir__(
            'Enum.reduce(Map.to_list({0}), {1}, fn {field, value}, acc -> Ecto.Query.where(acc, [{field}: value]) end)',
            conditions, query.toElixirQuery()
        );
        return new EctoQuery<T>(elixirQuery);
    }
}

#end