package reflaxe.elixir.schema;

#if (macro || reflaxe_runtime)

import haxe.macro.Context;
import haxe.macro.Type;
import haxe.macro.Expr.ComplexType;
import elixir.types.Term;
import sys.FileSystem;
import sys.io.File;

using StringTools;

typedef SchemaInfo = {
    name: String,
    fields: Map<String, FieldInfo>,
    associations: Map<String, AssociationInfo>,
    tableName: String,
    primaryKey: String
};

typedef FieldInfo = {
    name: String,
    type: String,
    nullable: Bool,
    defaultValue: Term,
    indexed: Bool
};

typedef AssociationInfo = {
    name: String,
    type: String,
    schema: String,
    foreignKey: String,
    throughAssociation: Null<String>
};

/**
 * Schema introspection utilities for compile-time field validation
 * Parses Ecto schema definitions and provides field/association metadata
 */
class SchemaIntrospection {
    
    /**
     * Cache for parsed schema information
     */
    static var schemaCache = new Map<String, SchemaInfo>();
    
    /**
     * Get schema fields for compile-time validation
     */
    public static function getSchemaFields(schemaName: String): Map<String, FieldInfo> {
        var schema = getSchemaInfo(schemaName);
        return schema != null ? schema.fields : new Map<String, FieldInfo>();
    }
    
    /**
     * Check if schema exists
     */
    public static function schemaExists(schemaName: String): Bool {
        return getSchemaInfo(schemaName) != null;
    }
    
    /**
     * Check if field exists in schema
     */
    public static function hasField(schemaName: String, fieldName: String): Bool {
        var schema = getSchemaInfo(schemaName);
        return schema != null && schema.fields.exists(fieldName);
    }
    
    /**
     * Get field type for validation
     */
    public static function getFieldType(schemaName: String, fieldName: String): String {
        var schema = getSchemaInfo(schemaName);
        if (schema != null && schema.fields.exists(fieldName)) {
            var field = schema.fields.get(fieldName);
            if (field != null) {
                return field.type;
            }
        }
        return "unknown";
    }
    
    /**
     * Check if association exists in schema
     */
    public static function hasAssociation(schemaName: String, associationName: String): Bool {
        var schema = getSchemaInfo(schemaName);
        return schema != null && schema.associations.exists(associationName);
    }
    
    /**
     * Get association information
     */
    public static function getAssociation(schemaName: String, associationName: String): Null<AssociationInfo> {
        var schema = getSchemaInfo(schemaName);
        if (schema != null && schema.associations.exists(associationName)) {
            return schema.associations.get(associationName);
        }
        return null;
    }
    
    /**
     * Get complete schema information
     */
    public static function getSchemaInfo(schemaName: String): Null<SchemaInfo> {
        if (schemaCache.exists(schemaName)) {
            return schemaCache.get(schemaName);
        }
        
        var schema = parseSchemaFromSource(schemaName);
        if (schema != null) {
            schemaCache.set(schemaName, schema);
        }
        
        return schema;
    }
    
    /**
     * Parse schema from Elixir source files or annotations
     */
    static function parseSchemaFromSource(schemaName: String): Null<SchemaInfo> {
        // Try parsing from Haxe schema annotations first
        var haxeSchema = parseHaxeSchemaAnnotations(schemaName);
        if (haxeSchema != null) {
            return haxeSchema;
        }
        
        // Try parsing from Elixir source files
        var elixirSchema = parseElixirSchemaFile(schemaName);
        if (elixirSchema != null) {
            return elixirSchema;
        }
        
        // Fallback to predefined schema definitions
        return getPredefinedSchema(schemaName);
    }
    
    /**
     * Parse schema from Haxe @:schema annotations
     */
    static function parseHaxeSchemaAnnotations(schemaName: String): Null<SchemaInfo> {
        // Check if we have a Haxe type with @:schema annotation
        var type = getHaxeSchemaType(schemaName);
        if (type == null) return null;
        
        var fields = new Map<String, FieldInfo>();
        var associations = new Map<String, AssociationInfo>();
        
        switch (type) {
            case TInst(t, _):
                var classType = t.get();
                
                // Parse fields from class metadata and fields
                for (field in classType.fields.get()) {
                    var fieldInfo = parseFieldFromHaxe(field);
                    if (fieldInfo != null) {
                        fields.set(fieldInfo.name, fieldInfo);
                    }
                }
                
                // Parse associations from metadata (simplified)
                // In a real implementation, this would parse metadata annotations
                
            case _:
        }
        
        return {
            name: schemaName,
            fields: fields,
            associations: associations,
            tableName: schemaName.toLowerCase() + "s",
            primaryKey: "id"
        };
    }
    
    /**
     * Parse schema from Elixir schema files
     */
    static function parseElixirSchemaFile(schemaName: String): Null<SchemaInfo> {
        var schemaPath = findElixirSchemaFile(schemaName);
        if (schemaPath == null || !FileSystem.exists(schemaPath)) {
            return null;
        }
        
        var content = File.getContent(schemaPath);
        return parseElixirSchemaContent(content, schemaName);
    }
    
    /**
     * Find Elixir schema file in common locations
     */
    static function findElixirSchemaFile(schemaName: String): Null<String> {
        var possiblePaths = [
            'lib/myapp/schemas/${schemaName.toLowerCase()}.ex',
            'lib/schemas/${schemaName.toLowerCase()}.ex',
            'lib/${schemaName.toLowerCase()}.ex',
            'priv/schemas/${schemaName.toLowerCase()}.ex'
        ];
        
        for (path in possiblePaths) {
            if (FileSystem.exists(path)) {
                return path;
            }
        }
        
        return null;
    }
    
    /**
     * Parse Elixir schema content
     */
    static function parseElixirSchemaContent(content: String, schemaName: String): Null<SchemaInfo> {
        var fields = new Map<String, FieldInfo>();
        var associations = new Map<String, AssociationInfo>();
        var tableName = schemaName.toLowerCase() + "s";
        var primaryKey = "id";
        
        // Parse schema block
        var schemaPattern = ~/schema\s+"([^"]+)"\s+do([\s\S]*?)end/;
        if (schemaPattern.match(content)) {
            tableName = schemaPattern.matched(1);
            var schemaBlock = schemaPattern.matched(2);
            
            // Parse field definitions
            var fieldPattern = ~/field\s+:([a-z_]+),\s+:([a-z_]+)(?:,\s*(.*))?/g;
            while (fieldPattern.match(schemaBlock)) {
                var fieldName = fieldPattern.matched(1);
                var fieldType = fieldPattern.matched(2);
                var options = fieldPattern.matched(3);
                
                var nullable = options != null && options.contains("null: true");
                var indexed = options != null && options.contains("index: true");
                
                fields.set(fieldName, {
                    name: fieldName,
                    type: mapElixirTypeToHaxe(fieldType),
                    nullable: nullable,
                    defaultValue: null,
                    indexed: indexed
                });
            }
            
            // Parse association definitions
            var assocPatterns = [
                ~/has_one\s+:([a-z_]+),\s+([A-Za-z.]+)(?:,\s*(.*))?/g,
                ~/has_many\s+:([a-z_]+),\s+([A-Za-z.]+)(?:,\s*(.*))?/g,
                ~/belongs_to\s+:([a-z_]+),\s+([A-Za-z.]+)(?:,\s*(.*))?/g,
                ~/many_to_many\s+:([a-z_]+),\s+([A-Za-z.]+)(?:,\s*(.*))?/g
            ];
            
            for (pattern in assocPatterns) {
                while (pattern.match(schemaBlock)) {
                    var assocName = pattern.matched(1);
                    var assocSchema = pattern.matched(2);
                    var options = pattern.matched(3);
                    
                    var assocType = getAssociationType(pattern);
                    var foreignKey = extractForeignKey(options, assocType, assocName);
                    
                    associations.set(assocName, {
                        name: assocName,
                        type: assocType,
                        schema: assocSchema,
                        foreignKey: foreignKey,
                        throughAssociation: extractThroughAssociation(options)
                    });
                }
            }
        }
        
        // Parse timestamps() macro
        if (content.contains("timestamps()")) {
            fields.set("inserted_at", {
                name: "inserted_at",
                type: "NaiveDateTime",
                nullable: false,
                defaultValue: null,
                indexed: false
            });
            fields.set("updated_at", {
                name: "updated_at", 
                type: "NaiveDateTime",
                nullable: false,
                defaultValue: null,
                indexed: false
            });
        }
        
        return {
            name: schemaName,
            fields: fields,
            associations: associations,
            tableName: tableName,
            primaryKey: primaryKey
        };
    }
    
    /**
     * Get predefined schema definitions for common patterns
     */
    static function getPredefinedSchema(schemaName: String): Null<SchemaInfo> {
        return switch (schemaName) {
            case "User":
                createUserSchema();
            case "Post":
                createPostSchema();
            case "Comment":
                createCommentSchema();
            default:
                createGenericSchema(schemaName);
        };
    }
    
    static function createUserSchema(): SchemaInfo {
        var fields = new Map<String, FieldInfo>();
        fields.set("id", {name: "id", type: "Int", nullable: false, defaultValue: null, indexed: true});
        fields.set("name", {name: "name", type: "String", nullable: false, defaultValue: null, indexed: false});
        fields.set("email", {name: "email", type: "String", nullable: false, defaultValue: null, indexed: true});
        fields.set("age", {name: "age", type: "Int", nullable: true, defaultValue: null, indexed: false});
        fields.set("active", {name: "active", type: "Bool", nullable: false, defaultValue: true, indexed: false});
        fields.set("inserted_at", {name: "inserted_at", type: "NaiveDateTime", nullable: false, defaultValue: null, indexed: false});
        fields.set("updated_at", {name: "updated_at", type: "NaiveDateTime", nullable: false, defaultValue: null, indexed: false});
        
        var associations = new Map<String, AssociationInfo>();
        associations.set("posts", {name: "posts", type: "has_many", schema: "Post", foreignKey: "user_id", throughAssociation: null});
        associations.set("comments", {name: "comments", type: "has_many", schema: "Comment", foreignKey: "user_id", throughAssociation: null});
        
        return {
            name: "User",
            fields: fields,
            associations: associations,
            tableName: "users",
            primaryKey: "id"
        };
    }
    
    static function createPostSchema(): SchemaInfo {
        var fields = new Map<String, FieldInfo>();
        fields.set("id", {name: "id", type: "Int", nullable: false, defaultValue: null, indexed: true});
        fields.set("title", {name: "title", type: "String", nullable: false, defaultValue: null, indexed: false});
        fields.set("body", {name: "body", type: "String", nullable: true, defaultValue: null, indexed: false});
        fields.set("user_id", {name: "user_id", type: "Int", nullable: false, defaultValue: null, indexed: true});
        fields.set("published", {name: "published", type: "Bool", nullable: false, defaultValue: false, indexed: true});
        fields.set("inserted_at", {name: "inserted_at", type: "NaiveDateTime", nullable: false, defaultValue: null, indexed: false});
        fields.set("updated_at", {name: "updated_at", type: "NaiveDateTime", nullable: false, defaultValue: null, indexed: false});
        
        var associations = new Map<String, AssociationInfo>();
        associations.set("user", {name: "user", type: "belongs_to", schema: "User", foreignKey: "user_id", throughAssociation: null});
        associations.set("comments", {name: "comments", type: "has_many", schema: "Comment", foreignKey: "post_id", throughAssociation: null});
        
        return {
            name: "Post",
            fields: fields,
            associations: associations,
            tableName: "posts",
            primaryKey: "id"
        };
    }
    
    static function createCommentSchema(): SchemaInfo {
        var fields = new Map<String, FieldInfo>();
        fields.set("id", {name: "id", type: "Int", nullable: false, defaultValue: null, indexed: true});
        fields.set("content", {name: "content", type: "String", nullable: false, defaultValue: null, indexed: false});
        fields.set("user_id", {name: "user_id", type: "Int", nullable: false, defaultValue: null, indexed: true});
        fields.set("post_id", {name: "post_id", type: "Int", nullable: false, defaultValue: null, indexed: true});
        fields.set("inserted_at", {name: "inserted_at", type: "NaiveDateTime", nullable: false, defaultValue: null, indexed: false});
        fields.set("updated_at", {name: "updated_at", type: "NaiveDateTime", nullable: false, defaultValue: null, indexed: false});
        
        var associations = new Map<String, AssociationInfo>();
        associations.set("user", {name: "user", type: "belongs_to", schema: "User", foreignKey: "user_id", throughAssociation: null});
        associations.set("post", {name: "post", type: "belongs_to", schema: "Post", foreignKey: "post_id", throughAssociation: null});
        
        return {
            name: "Comment",
            fields: fields,
            associations: associations,
            tableName: "comments",
            primaryKey: "id"
        };
    }
    
    static function createGenericSchema(schemaName: String): Null<SchemaInfo> {
        // Only create generic schemas for known patterns
        if (!["User", "Post", "Comment"].contains(schemaName)) {
            return null;
        }
        
        var fields = new Map<String, FieldInfo>();
        fields.set("id", {name: "id", type: "Int", nullable: false, defaultValue: null, indexed: true});
        fields.set("name", {name: "name", type: "String", nullable: true, defaultValue: null, indexed: false});
        fields.set("inserted_at", {name: "inserted_at", type: "NaiveDateTime", nullable: false, defaultValue: null, indexed: false});
        fields.set("updated_at", {name: "updated_at", type: "NaiveDateTime", nullable: false, defaultValue: null, indexed: false});
        
        return {
            name: schemaName,
            fields: fields,
            associations: new Map<String, AssociationInfo>(),
            tableName: schemaName.toLowerCase() + "s",
            primaryKey: "id"
        };
    }
    
    // Helper functions
    
    static function getHaxeSchemaType(schemaName: String): Null<Type> {
        try {
            #if macro
            // Try resolving bare name first
            var t = Context.resolveType(TPath({name: schemaName, pack: []}), Context.currentPos());
            if (t != null) return t;
            // If a fully-qualified name was provided (contains dots), split into pack + name
            if (schemaName.indexOf(".") != -1) {
                var parts = schemaName.split(".");
                var name = parts.pop();
                var pack = parts;
                return Context.resolveType(TPath({name: name, pack: pack}), Context.currentPos());
            }
            return null;
            #else
            return null;
            #end
        } catch (e) {
            return null;
        }
    }
    
    static function parseFieldFromHaxe(field: haxe.macro.Type.ClassField): Null<FieldInfo> {
        // Parse basic type info from Haxe field type for better schema emission
        #if macro
        var typeStr = switch (field.type) {
            case TInst(t, _):
                var n = t.get().name;
                switch (n) {
                    case "String": "String";
                    case "Int": "Int";
                    case "Bool": "Bool";
                    case "Date": "NaiveDateTime"; // map Haxe Date to datetime-like
                    default: "Term";
                }
            case TAbstract(t, _):
                var n = t.get().name;
                switch (n) {
                    case "Int": "Int";
                    case "Bool": "Bool";
                    case "Single", "Float": "Float";
                    default: "Term";
                }
            case TType(t, _): t.get().name;
            case _:
                "Term";
        }
        #else
        var typeStr = "Term";
        #end

        return {
            name: field.name,
            type: typeStr,
            nullable: true,
            defaultValue: null,
            indexed: false
        };
    }
    
    static function parseAssociationsFromMetadata(meta: Term): Array<AssociationInfo> {
        // Simplified association parsing from metadata
        return [];
    }
    
    static function mapElixirTypeToHaxe(elixirType: String): String {
        return switch (elixirType) {
            case "string": "String";
            case "integer": "Int";
            case "float": "Float";
            case "boolean": "Bool";
            case "date": "Date";
            case "datetime", "naive_datetime": "NaiveDateTime";
            case "decimal": "Float";
            case "binary": "String";
            case "text": "String";
            default: "Term";
        };
    }
    
    static function getAssociationType(pattern: EReg): String {
        // Simplified pattern type detection
        return "has_many"; // Default assumption for simplicity
    }
    
    static function extractForeignKey(options: String, assocType: String, assocName: String): String {
        if (options != null && options.contains("foreign_key:")) {
            var fkPattern = ~/foreign_key:\s*:([a-z_]+)/;
            if (fkPattern.match(options)) {
                return fkPattern.matched(1);
            }
        }
        
        // Default foreign key naming
        return switch (assocType) {
            case "belongs_to": assocName + "_id";
            case "has_one", "has_many": "id"; // This schema's id
            default: assocName + "_id";
        };
    }
    
    static function extractThroughAssociation(options: String): Null<String> {
        if (options != null && options.contains("through:")) {
            var throughPattern = ~/through:\s*:([a-z_]+)/;
            if (throughPattern.match(options)) {
                return throughPattern.matched(1);
            }
        }
        return null;
    }
    
    /**
     * Clear schema cache (useful for testing)
     */
    public static function clearCache(): Void {
        schemaCache = new Map<String, SchemaInfo>();
    }
    
    /**
     * Add custom schema definition
     */
    public static function addSchema(schema: SchemaInfo): Void {
        schemaCache.set(schema.name, schema);
    }
}

#end
