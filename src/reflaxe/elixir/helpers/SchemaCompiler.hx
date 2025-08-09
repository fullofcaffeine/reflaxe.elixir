package reflaxe.elixir.helpers;

#if (macro || reflaxe_runtime)

import haxe.macro.Context;
import haxe.macro.Type;
import haxe.macro.Expr;
import reflaxe.data.ClassFuncData;
import reflaxe.data.ClassVarData;
import reflaxe.elixir.helpers.NamingHelper;
import reflaxe.elixir.schema.SchemaIntrospection;

using StringTools;
using reflaxe.helpers.NameMetaHelper;

/**
 * SchemaCompiler - Compiles @:schema annotated classes to Ecto.Schema modules
 * 
 * Supports:
 * - @:schema annotation detection and table name extraction
 * - @:field, @:primary_key, @:timestamps annotations
 * - @:has_many, @:belongs_to, @:has_one associations
 * - Integration with SchemaIntrospection for compile-time validation
 * - Complete Ecto.Schema module generation with schema/2 macro calls
 */
class SchemaCompiler {
    
    /**
     * Check if a class type has @:schema annotation
     */
    public static function isSchemaClassType(classType: ClassType): Bool {
        if (classType == null) return false;
        return classType.meta.has(":schema");
    }
    
    /**
     * Extract schema configuration from @:schema annotation
     */
    public static function getSchemaConfig(classType: ClassType): SchemaConfig {
        if (!classType.meta.has(":schema")) {
            return {tableName: null};
        }
        
        var meta = classType.meta.extract(":schema")[0];
        var tableName = null;
        
        if (meta.params != null && meta.params.length > 0) {
            switch (meta.params[0].expr) {
                case EConst(CString(s, _)):
                    tableName = s;
                case _:
            }
        }
        
        return {tableName: tableName};
    }
    
    /**
     * Compile @:schema annotated class to Ecto.Schema module
     */
    public static function compileFullSchema(className: String, config: SchemaConfig, varFields: Array<ClassVarData>): String {
        var moduleName = NamingHelper.getElixirModuleName(className);
        var tableName = config.tableName != null ? config.tableName : NamingHelper.toSnakeCase(className) + "s";
        
        var result = 'defmodule ${moduleName} do\n';
        result += '  @moduledoc """\n';
        result += '  Ecto schema module generated from Haxe @:schema class\n';
        result += '  Table: ${tableName}\n';
        result += '  """\n\n';
        
        // Import Ecto.Schema
        result += '  use Ecto.Schema\n';
        result += '  import Ecto.Changeset\n\n';
        
        // Add schema definition
        result += '  @primary_key {:id, :id, autogenerate: true}\n';
        result += '  @derive {Phoenix.Param, key: :id}\n\n';
        
        result += '  schema "${tableName}" do\n';
        
        // Process field definitions
        for (field in varFields) {
            var fieldDef = compileSchemaField(field);
            if (fieldDef != null && fieldDef.length > 0) {
                result += '    ${fieldDef}\n';
            }
        }
        
        result += '  end\n\n';
        
        // Add changeset function
        result += '  @doc """\n';
        result += '  Changeset function for ${className} schema\n';
        result += '  """\n';
        result += '  def changeset(%${className}{} = ${NamingHelper.toSnakeCase(className)}, attrs \\\\ %{}) do\n';
        result += '    ${NamingHelper.toSnakeCase(className)}\n';
        result += '    |> cast(attrs, changeable_fields())\n';
        result += '    |> validate_required(required_fields())\n';
        result += '  end\n\n';
        
        // Add helper functions
        result += '  defp changeable_fields do\n';
        result += '    [${getChangeableFields(varFields)}]\n';
        result += '  end\n\n';
        
        result += '  defp required_fields do\n';
        result += '    [${getRequiredFields(varFields)}]\n';
        result += '  end\n\n';
        
        result += 'end\n';
        
        // Register schema with SchemaIntrospection system
        registerSchemaForIntrospection(className, tableName, varFields);
        
        return result;
    }
    
    /**
     * Compile individual schema field from ClassVarData
     */
    static function compileSchemaField(field: ClassVarData): String {
        var fieldName = NamingHelper.toSnakeCase(field.field.name);
        
        // Check for special annotations
        var fieldMeta = field.field.meta;
        
        // Skip primary key fields (handled by schema/2 macro)
        if (fieldMeta.has(":primary_key")) {
            return "";
        }
        
        // Handle timestamps annotation
        if (fieldMeta.has(":timestamps")) {
            return "timestamps()";
        }
        
        // Handle regular field annotation
        if (fieldMeta.has(":field")) {
            var fieldConfig = extractFieldConfig(fieldMeta);
            var elixirType = fieldConfig.type != null ? fieldConfig.type : mapHaxeTypeToElixir(field.type);
            
            var fieldDef = 'field :${fieldName}, :${elixirType}';
            
            // Add field options
            var options = [];
            if (!fieldConfig.nullable) {
                options.push("null: false");
            }
            if (fieldConfig.defaultValue != null) {
                options.push('default: ${fieldConfig.defaultValue}');
            }
            
            if (options.length > 0) {
                fieldDef += ', ' + options.join(', ');
            }
            
            return fieldDef;
        }
        
        // Handle association annotations
        if (fieldMeta.has(":has_many")) {
            var assocConfig = extractAssociationConfig(fieldMeta, ":has_many");
            return 'has_many :${fieldName}, ${assocConfig.schema}';
        }
        
        if (fieldMeta.has(":belongs_to")) {
            var assocConfig = extractAssociationConfig(fieldMeta, ":belongs_to");
            return 'belongs_to :${fieldName}, ${assocConfig.schema}';
        }
        
        if (fieldMeta.has(":has_one")) {
            var assocConfig = extractAssociationConfig(fieldMeta, ":has_one");
            return 'has_one :${fieldName}, ${assocConfig.schema}';
        }
        
        // Default field compilation
        var elixirType = mapHaxeTypeToElixir(field.type);
        return 'field :${fieldName}, :${elixirType}';
    }
    
    /**
     * Extract field configuration from @:field annotation
     */
    static function extractFieldConfig(meta: haxe.macro.Type.MetaAccess): FieldConfig {
        var config = {type: null, nullable: true, defaultValue: null};
        
        var fieldMeta = meta.extract(":field");
        if (fieldMeta.length > 0 && fieldMeta[0].params != null) {
            for (param in fieldMeta[0].params) {
                switch (param.expr) {
                    case EObjectDecl(fields):
                        for (objField in fields) {
                            switch (objField.field) {
                                case "type":
                                    switch (objField.expr.expr) {
                                        case EConst(CString(s, _)):
                                            config.type = s;
                                        case _:
                                    }
                                case "null" | "nullable":
                                    switch (objField.expr.expr) {
                                        case EConst(CIdent("false")):
                                            config.nullable = false;
                                        case EConst(CIdent("true")):
                                            config.nullable = true;
                                        case _:
                                    }
                                case "default" | "defaultValue":
                                    config.defaultValue = extractDefaultValue(objField.expr);
                                case _:
                            }
                        }
                    case _:
                }
            }
        }
        
        return config;
    }
    
    /**
     * Extract association configuration from annotation
     */
    static function extractAssociationConfig(meta: haxe.macro.Type.MetaAccess, annotationName: String): AssociationConfig {
        var config = {schema: null, foreignKey: null};
        
        var assocMeta = meta.extract(annotationName);
        if (assocMeta.length > 0 && assocMeta[0].params != null && assocMeta[0].params.length >= 2) {
            // Format: @:has_many("posts", "Post", "user_id")
            switch (assocMeta[0].params[1].expr) {
                case EConst(CString(s, _)):
                    config.schema = s;
                case _:
            }
            
            if (assocMeta[0].params.length >= 3) {
                switch (assocMeta[0].params[2].expr) {
                    case EConst(CString(s, _)):
                        config.foreignKey = s;
                    case _:
                }
            }
        }
        
        return config;
    }
    
    /**
     * Extract default value from expression
     */
    static function extractDefaultValue(expr: Expr): Dynamic {
        return switch (expr.expr) {
            case EConst(CString(s, _)): '"${s}"';
            case EConst(CInt(i)): i;
            case EConst(CFloat(f)): f;
            case EConst(CIdent("true")): "true";
            case EConst(CIdent("false")): "false";
            case EConst(CIdent("null")): "nil";
            case _: null;
        };
    }
    
    /**
     * Map Haxe types to Elixir/Ecto types
     */
    static function mapHaxeTypeToElixir(haxeType: haxe.macro.Type): String {
        return switch (haxeType) {
            case TInst(t, _):
                switch (t.get().name) {
                    case "String": "string";
                    case "Array": "string"; // Arrays often stored as JSON
                    default: "string";
                }
            case TAbstract(t, _):
                switch (t.get().name) {
                    case "Int": "integer";
                    case "Float": "float";
                    case "Bool": "boolean";
                    default: "string";
                }
            case _: "string";
        };
    }
    
    /**
     * Get changeable fields list for changeset
     */
    static function getChangeableFields(varFields: Array<ClassVarData>): String {
        var fields = [];
        for (field in varFields) {
            // Skip primary key and timestamps
            if (!field.field.meta.has(":primary_key") && !field.field.meta.has(":timestamps")) {
                // Skip associations for changeset
                if (!field.field.meta.has(":has_many") && !field.field.meta.has(":belongs_to") && !field.field.meta.has(":has_one")) {
                    fields.push(':${NamingHelper.toSnakeCase(field.field.name)}');
                }
            }
        }
        return fields.join(", ");
    }
    
    /**
     * Get required fields list for changeset validation
     */
    static function getRequiredFields(varFields: Array<ClassVarData>): String {
        var fields = [];
        for (field in varFields) {
            // Check if field has null: false in @:field annotation
            if (field.field.meta.has(":field")) {
                var fieldConfig = extractFieldConfig(field.field.meta);
                if (!fieldConfig.nullable) {
                    fields.push(':${NamingHelper.toSnakeCase(field.field.name)}');
                }
            }
        }
        return fields.join(", ");
    }
    
    /**
     * Register schema with SchemaIntrospection for compile-time validation
     */
    static function registerSchemaForIntrospection(className: String, tableName: String, varFields: Array<ClassVarData>): Void {
        var fields = new Map<String, reflaxe.elixir.schema.SchemaIntrospection.FieldInfo>();
        var associations = new Map<String, reflaxe.elixir.schema.SchemaIntrospection.AssociationInfo>();
        
        // Process fields
        for (field in varFields) {
            var fieldName = NamingHelper.toSnakeCase(field.field.name);
            
            if (field.field.meta.has(":field")) {
                var fieldConfig = extractFieldConfig(field.field.meta);
                var elixirType = fieldConfig.type != null ? fieldConfig.type : mapHaxeTypeToElixir(field.type);
                
                fields.set(fieldName, {
                    name: fieldName,
                    type: mapElixirTypeToHaxe(elixirType),
                    nullable: fieldConfig.nullable,
                    defaultValue: fieldConfig.defaultValue,
                    indexed: false
                });
            }
            
            // Handle associations
            if (field.field.meta.has(":has_many")) {
                var assocConfig = extractAssociationConfig(field.field.meta, ":has_many");
                associations.set(fieldName, {
                    name: fieldName,
                    type: "has_many",
                    schema: assocConfig.schema,
                    foreignKey: assocConfig.foreignKey,
                    throughAssociation: null
                });
            }
            
            if (field.field.meta.has(":belongs_to")) {
                var assocConfig = extractAssociationConfig(field.field.meta, ":belongs_to");
                associations.set(fieldName, {
                    name: fieldName,
                    type: "belongs_to", 
                    schema: assocConfig.schema,
                    foreignKey: assocConfig.foreignKey,
                    throughAssociation: null
                });
            }
        }
        
        // Handle timestamps
        var hasTimestamps = false;
        for (field in varFields) {
            if (field.field.meta.has(":timestamps")) {
                hasTimestamps = true;
                break;
            }
        }
        
        if (hasTimestamps) {
            fields.set("inserted_at", {
                name: "inserted_at",
                type: "String", // Simplified for Haxe compatibility
                nullable: false,
                defaultValue: null,
                indexed: false
            });
            fields.set("updated_at", {
                name: "updated_at",
                type: "String",
                nullable: false,
                defaultValue: null,
                indexed: false
            });
        }
        
        // Register schema
        var schemaInfo = {
            name: className,
            fields: fields,
            associations: associations,
            tableName: tableName,
            primaryKey: "id"
        };
        
        reflaxe.elixir.schema.SchemaIntrospection.addSchema(schemaInfo);
    }
    
    /**
     * Map Elixir types back to Haxe types for SchemaIntrospection
     */
    static function mapElixirTypeToHaxe(elixirType: String): String {
        return switch (elixirType) {
            case "string": "String";
            case "integer": "Int";
            case "float": "Float";
            case "boolean": "Bool";
            case "date": "String";
            case "datetime", "naive_datetime": "String";
            case "decimal": "Float";
            case "binary": "String";
            case "text": "String";
            default: "Dynamic";
        };
    }
}

/**
 * Schema configuration extracted from @:schema annotation
 */
typedef SchemaConfig = {
    tableName: Null<String>
}

/**
 * Field configuration extracted from @:field annotation
 */
typedef FieldConfig = {
    type: Null<String>,
    nullable: Bool,
    defaultValue: Dynamic
}

/**
 * Association configuration extracted from association annotations
 */
typedef AssociationConfig = {
    schema: Null<String>,
    foreignKey: Null<String>
}

#end