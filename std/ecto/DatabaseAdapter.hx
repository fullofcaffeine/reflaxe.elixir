package ecto;

/**
 * Type-safe database adapters for Ecto repositories
 * 
 * Provides compile-time validation of database adapter selection
 * and ensures only supported adapters are used.
 */
enum DatabaseAdapter {
    /**
     * PostgreSQL adapter via Postgrex
     * The most common choice for Phoenix applications
     */
    Postgres;
    
    /**
     * MySQL/MariaDB adapter via MyXQL
     */
    MySQL;
    
    /**
     * SQLite3 adapter via Ecto.Adapters.SQLite3
     * Good for development and embedded applications
     */
    SQLite3;
    
    /**
     * Microsoft SQL Server adapter via Tds
     */
    SQLServer;
    
    /**
     * In-memory adapter for testing
     * No persistence, cleared on restart
     */
    InMemory;
}

/**
 * JSON encoding/decoding libraries for database types
 */
enum JsonLibrary {
    /**
     * Jason - The default and recommended JSON library for Phoenix
     * Fast, fully featured, and actively maintained
     */
    Jason;
    
    /**
     * Poison - Legacy JSON library, still supported
     * Use only if you have existing Poison dependencies
     */
    Poison;
    
    /**
     * No JSON support - For databases that don't need JSON types
     */
    None;
}

/**
 * PostgreSQL-specific extensions that can be enabled
 */
enum PostgresExtension {
    /**
     * UUID generation functions
     */
    UuidOssp;
    
    /**
     * PostGIS geographic data types
     */
    PostGIS;
    
    /**
     * HStore key-value storage
     */
    HStore;
    
    /**
     * Full text search
     */
    PgTrgm;
    
    /**
     * Cryptographic functions
     */
    PgCrypto;
    
    /**
     * JSONB indexing
     */
    JsonbPlv8;
}

/**
 * Type-safe repository configuration
 */
typedef RepoConfig = {
    /**
     * The database adapter to use
     */
    var adapter: DatabaseAdapter;
    
    /**
     * JSON library for encoding/decoding (optional)
     * Defaults to Jason for Postgres/MySQL
     */
    @:optional var json: JsonLibrary;
    
    /**
     * PostgreSQL extensions to load (optional)
     * Only applicable when adapter is Postgres
     */
    @:optional var extensions: Array<PostgresExtension>;
    
    /**
     * Connection pool size (optional)
     * Defaults to 10
     */
    @:optional var poolSize: Int;
    
    /**
     * Database name (optional)
     * Can be set via runtime configuration
     */
    @:optional var database: String;
    
    /**
     * Hostname for database connection (optional)
     * Defaults to "localhost"
     */
    @:optional var hostname: String;
    
    /**
     * Port number (optional)
     * Defaults to standard port for the adapter
     */
    @:optional var port: Int;
}