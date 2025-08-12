package reflaxe.elixir.helpers;

#if (macro || reflaxe_runtime)

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;

using StringTools;

/**
 * Enhanced error reporting for Ecto-related compilation failures
 * Provides helpful suggestions and schema validation with actionable feedback
 */
class EctoErrorReporter {
    
    /**
     * Common Ecto error patterns and their solutions
     */
    static final ERROR_PATTERNS = [
        {
            pattern: "Unknown field .* in schema",
            solution: "Check that the field exists in your schema definition. Did you mean to add it with @:field annotation?",
            docs: "See documentation/ANNOTATIONS.md#field-annotation"
        },
        {
            pattern: "Invalid association type",
            solution: "Association must be one of: has_one, has_many, belongs_to, many_to_many",
            docs: "See documentation/guides/ADVANCED_ECTO_GUIDE.md#associations"
        },
        {
            pattern: "Missing required changeset function",
            solution: "Classes with @:changeset must have a static changeset function",
            docs: "See documentation/guides/ADVANCED_ECTO_GUIDE.md#changesets"
        },
        {
            pattern: "Invalid field type",
            solution: "Field types must be valid Ecto types: string, integer, boolean, date, datetime, etc.",
            docs: "See documentation/guides/ADVANCED_ECTO_GUIDE.md#field-types"
        },
        {
            pattern: "Circular association detected",
            solution: "Schema has circular associations. Consider using :on_replace option or restructuring associations",
            docs: "See Ecto documentation on association cycles"
        },
        {
            pattern: "Reserved keyword in metadata",
            solution: "Cannot use Haxe reserved keywords (default, interface, operator) in metadata. Use alternatives like 'defaultValue'",
            docs: "See documentation/TESTING_PRINCIPLES.md#simplification-principle"
        }
    ];
    
    /**
     * Report schema validation error with helpful context
     */
    public static function reportSchemaError(schemaName: String, error: String, pos: Position): Void {
        var message = formatSchemaError(schemaName, error);
        var suggestion = getSuggestion(error);
        var fullMessage = '$message\n$suggestion';
        
        Context.error(fullMessage, pos);
    }
    
    /**
     * Report changeset validation error
     */
    public static function reportChangesetError(className: String, error: String, pos: Position): Void {
        var message = 'Changeset error in $className: $error';
        var suggestion = getChangesetSuggestion(error);
        var example = getChangesetExample();
        
        var fullMessage = '$message\n$suggestion\n\nExample:\n$example';
        Context.error(fullMessage, pos);
    }
    
    /**
     * Report query compilation error
     */
    public static function reportQueryError(queryExpr: String, error: String, pos: Position): Void {
        var message = 'Query compilation failed: $error';
        var suggestion = getQuerySuggestion(queryExpr, error);
        var alternatives = getQueryAlternatives(queryExpr);
        
        var fullMessage = '$message\n$suggestion';
        if (alternatives.length > 0) {
            fullMessage += '\n\nAlternatives:\n' + alternatives.join('\n');
        }
        
        Context.error(fullMessage, pos);
    }
    
    /**
     * Report migration DSL error
     */
    public static function reportMigrationError(operation: String, error: String, pos: Position): Void {
        var message = 'Migration error in $operation: $error';
        var suggestion = getMigrationSuggestion(operation, error);
        var example = getMigrationExample(operation);
        
        var fullMessage = '$message\n$suggestion\n\nCorrect usage:\n$example';
        Context.error(fullMessage, pos);
    }
    
    /**
     * Report association configuration error
     */
    public static function reportAssociationError(field: String, assocType: String, error: String, pos: Position): Void {
        var message = 'Association error for field "$field" ($assocType): $error';
        var suggestion = getAssociationSuggestion(assocType, error);
        var requirements = getAssociationRequirements(assocType);
        
        var fullMessage = '$message\n$suggestion\n\nRequirements:\n$requirements';
        Context.error(fullMessage, pos);
    }
    
    /**
     * Warning for potentially problematic patterns
     */
    public static function warnAboutPattern(pattern: String, suggestion: String, pos: Position): Void {
        var message = 'Warning: $pattern\nSuggestion: $suggestion';
        Context.warning(message, pos);
    }
    
    /**
     * Validate schema fields at compile time
     */
    public static function validateSchemaFields(fields: Array<{name: String, type: String, meta: Dynamic}>, pos: Position): Bool {
        var errors = [];
        var warnings = [];
        
        for (field in fields) {
            // Check for reserved keywords
            if (isReservedKeyword(field.name)) {
                errors.push('Field name "${field.name}" is a reserved keyword. Use a different name.');
            }
            
            // Check for invalid types
            if (!isValidEctoType(field.type)) {
                errors.push('Field "${field.name}" has invalid type "${field.type}". Valid types: string, integer, boolean, date, datetime, decimal, map, array');
            }
            
            // Check metadata for reserved keywords
            if (field.meta != null) {
                var metaErrors = validateMetadata(field.meta);
                if (metaErrors.length > 0) {
                    errors.push('Field "${field.name}" metadata errors: ' + metaErrors.join(', '));
                }
            }
            
            // Warn about nullable primary keys
            if (field.name == "id" && field.meta != null && field.meta.nullable == true) {
                warnings.push('Primary key "id" should not be nullable');
            }
        }
        
        // Report all errors
        if (errors.length > 0) {
            var errorMessage = "Schema validation failed:\n" + errors.map(e -> "  - " + e).join("\n");
            errorMessage += "\n\nSee documentation/guides/ADVANCED_ECTO_GUIDE.md for schema examples";
            Context.error(errorMessage, pos);
            return false;
        }
        
        // Report warnings
        for (warning in warnings) {
            Context.warning(warning, pos);
        }
        
        return true;
    }
    
    /**
     * Validate changeset configuration
     */
    public static function validateChangesetConfig(className: String, config: Dynamic, pos: Position): Bool {
        var errors = [];
        
        // Check for required changeset function
        if (!hasChangesetFunction(className)) {
            errors.push('Class $className with @:changeset must have a static changeset function');
        }
        
        // Validate cast fields exist in schema
        if (config.castFields != null) {
            // Cast Dynamic to Array<String> for iteration
            var castFields: Array<String> = cast config.castFields;
            for (field in castFields) {
                if (!schemaHasField(className, field)) {
                    errors.push('Cast field "$field" does not exist in schema');
                }
            }
        }
        
        // Validate required fields
        if (config.requiredFields != null) {
            // Cast Dynamic to Array<String> for iteration
            var requiredFields: Array<String> = cast config.requiredFields;
            for (field in requiredFields) {
                if (!schemaHasField(className, field)) {
                    errors.push('Required field "$field" does not exist in schema');
                }
            }
        }
        
        if (errors.length > 0) {
            var errorMessage = "Changeset validation failed for $className:\n" + errors.map(e -> "  - " + e).join("\n");
            errorMessage += "\n\nExample changeset:\n" + getChangesetExample();
            Context.error(errorMessage, pos);
            return false;
        }
        
        return true;
    }
    
    // Helper functions
    
    static function formatSchemaError(schemaName: String, error: String): String {
        return 'Schema "$schemaName" compilation failed: $error';
    }
    
    static function getSuggestion(error: String): String {
        for (pattern in ERROR_PATTERNS) {
            if (error.contains(pattern.pattern) || new EReg(pattern.pattern, "i").match(error)) {
                return 'Suggestion: ${pattern.solution}\nDocumentation: ${pattern.docs}';
            }
        }
        return "Check your schema definition and ensure all annotations are correct.";
    }
    
    static function getChangesetSuggestion(error: String): String {
        if (error.contains("cast")) {
            return "Ensure all cast fields exist in your schema and are properly typed";
        }
        if (error.contains("validate")) {
            return "Validation functions must match Ecto patterns (validate_required, validate_format, etc.)";
        }
        if (error.contains("constraint")) {
            return "Constraints must reference existing database constraints or indexes";
        }
        return "Review your changeset function for proper Ecto patterns";
    }
    
    static function getChangesetExample(): String {
        return '
public static function changeset(user: User, params: Dynamic): Dynamic {
    return user
        |> cast(params, ["name", "email", "age"])
        |> validateRequired(["name", "email"])
        |> validateFormat("email", ~r/@/)
        |> validateNumber("age", greaterThan: 0, lessThan: 150)
        |> uniqueConstraint("email");
}';
    }
    
    static function getQuerySuggestion(queryExpr: String, error: String): String {
        if (error.contains("from")) {
            return "Query must start with 'from' clause: from(u in User)";
        }
        if (error.contains("where")) {
            return "Where clauses use == for equality: where(u.active == true)";
        }
        if (error.contains("select")) {
            return "Select clause must be last: ...select(u)";
        }
        return "Review Ecto.Query syntax in documentation/guides/ADVANCED_ECTO_GUIDE.md";
    }
    
    static function getQueryAlternatives(queryExpr: String): Array<String> {
        var alternatives = [];
        
        // Suggest query syntax alternatives
        if (queryExpr.contains("User.where")) {
            alternatives.push("from(u in User) |> where(u.active == true)");
        }
        if (queryExpr.contains("Repo.get")) {
            alternatives.push("Repo.get(User, id)");
            alternatives.push("Repo.get_by(User, email: \"user@example.com\")");
        }
        
        return alternatives;
    }
    
    static function getMigrationSuggestion(operation: String, error: String): String {
        return switch(operation) {
            case "create_table":
                "Table creation requires a block: create table(:users) do ... end";
            case "add_column":
                "Column addition syntax: add :field_name, :field_type, options";
            case "create_index":
                "Index creation: create index(:table, [:field1, :field2])";
            default:
                "Check migration DSL syntax in documentation";
        };
    }
    
    static function getMigrationExample(operation: String): String {
        return switch(operation) {
            case "create_table":
                'create table(:users) do
    add :id, :bigserial, primary_key: true
    add :name, :string, null: false
    add :email, :string, null: false
    timestamps()
end';
            case "add_column":
                'alter table(:users) do
    add :age, :integer, default: 0
end';
            default:
                "";
        };
    }
    
    static function getAssociationSuggestion(assocType: String, error: String): String {
        return switch(assocType) {
            case "has_many":
                "has_many requires: plural field name, target schema, foreign_key option";
            case "belongs_to":
                "belongs_to requires: singular field name, target schema, creates foreign_key field";
            case "many_to_many":
                "many_to_many requires: join_through table or schema";
            default:
                "Check association configuration in documentation";
        };
    }
    
    static function getAssociationRequirements(assocType: String): String {
        return switch(assocType) {
            case "has_many":
                "- Plural field name (e.g., 'posts')\n- Target schema exists\n- Foreign key in target table";
            case "belongs_to":
                "- Singular field name (e.g., 'user')\n- Creates foreign_key field (e.g., 'user_id')\n- Target schema exists";
            case "many_to_many":
                "- Join table or schema specified\n- Both foreign keys exist in join table";
            default:
                "";
        };
    }
    
    static function isReservedKeyword(name: String): Bool {
        var reserved = ["default", "interface", "operator", "overload", "class", "enum", 
                       "function", "var", "if", "else", "switch", "case", "return", "break",
                       "continue", "while", "for", "do", "try", "catch", "throw", "new"];
        return reserved.contains(name);
    }
    
    static function isValidEctoType(type: String): Bool {
        var validTypes = ["string", "integer", "boolean", "date", "datetime", "naive_datetime",
                         "decimal", "float", "binary", "map", "array", "text", "uuid", "id"];
        return validTypes.contains(type.toLowerCase());
    }
    
    static function validateMetadata(meta: Dynamic): Array<String> {
        var errors = [];
        
        // Check for reserved keywords in metadata keys
        if (Reflect.hasField(meta, "default")) {
            errors.push("Use 'defaultValue' instead of 'default' (reserved keyword)");
        }
        if (Reflect.hasField(meta, "interface")) {
            errors.push("Cannot use 'interface' in metadata (reserved keyword)");
        }
        if (Reflect.hasField(meta, "operator")) {
            errors.push("Cannot use 'operator' in metadata (reserved keyword)");
        }
        
        return errors;
    }
    
    static function hasChangesetFunction(className: String): Bool {
        // This would check if the class has a changeset function
        // Simplified for demonstration
        return true;
    }
    
    static function schemaHasField(className: String, fieldName: String): Bool {
        // This would check if the schema has the specified field
        // Simplified for demonstration
        return true;
    }
    
    /**
     * Format error with code context
     */
    public static function formatErrorWithContext(error: String, code: String, line: Int, column: Int): String {
        var lines = code.split("\n");
        var context = [];
        
        // Add lines before error
        for (i in Std.int(Math.max(0, line - 2))...line) {
            context.push('${i + 1} | ${lines[i]}');
        }
        
        // Add error line with marker
        if (line < lines.length) {
            context.push('${line + 1} | ${lines[line]}');
            var marker = StringTools.lpad("", " ", column + 5) + "^--- " + error;
            context.push(marker);
        }
        
        // Add lines after error
        for (i in (line + 1)...Std.int(Math.min(lines.length, line + 3))) {
            context.push('${i + 1} | ${lines[i]}');
        }
        
        return context.join("\n");
    }
    
    /**
     * Suggest field name corrections using edit distance
     */
    public static function suggestFieldName(wrongName: String, availableFields: Array<String>): String {
        var suggestions = [];
        
        for (field in availableFields) {
            var distance = levenshteinDistance(wrongName.toLowerCase(), field.toLowerCase());
            if (distance <= 2) {
                suggestions.push(field);
            }
        }
        
        if (suggestions.length > 0) {
            return 'Did you mean: ' + suggestions.join(", ") + '?';
        }
        
        return 'Available fields: ' + availableFields.join(", ");
    }
    
    static function levenshteinDistance(s1: String, s2: String): Int {
        var len1 = s1.length;
        var len2 = s2.length;
        var matrix = [];
        
        for (i in 0...(len1 + 1)) {
            matrix[i] = [];
            matrix[i][0] = i;
        }
        
        for (j in 0...(len2 + 1)) {
            matrix[0][j] = j;
        }
        
        for (i in 1...(len1 + 1)) {
            for (j in 1...(len2 + 1)) {
                var cost = s1.charAt(i - 1) == s2.charAt(j - 1) ? 0 : 1;
                matrix[i][j] = Math.floor(Math.min(
                    matrix[i - 1][j] + 1,
                    Math.min(
                        matrix[i][j - 1] + 1,
                        matrix[i - 1][j - 1] + cost
                    )
                ));
            }
        }
        
        return matrix[len1][len2];
    }
}

#end