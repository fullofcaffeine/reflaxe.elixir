package ecto;

import haxe.ds.Option;
import haxe.functional.Result;

/**
 * Ecto.Changeset type definition for type-safe database operations.
 * 
 * Represents an Ecto changeset with proper typing for the schema and errors.
 * Provides compile-time safety for changeset operations and validations.
 * 
 * ## Usage
 * 
 * ```haxe
 * import ecto.Changeset;
 * 
 * function validateUser(attrs: Dynamic): Changeset<User> {
 *     var changeset: Changeset<User> = User.changeset(new User(), attrs);
 *     
 *     if (changeset.valid) {
 *         // Safe to insert
 *         return changeset;
 *     } else {
 *         // Handle validation errors
 *         trace('Validation errors: ${changeset.errors}');
 *         return changeset;
 *     }
 * }
 * ```
 * 
 * @see https://hexdocs.pm/ecto/Ecto.Changeset.html
 */
typedef Changeset<T> = {
    /** The original data being changed */
    var data: T;
    
    /** Changed values (not yet persisted) */
    var changes: Map<String, Dynamic>;
    
    /** Validation errors */
    var errors: Array<ChangesetError>;
    
    /** Whether the changeset is valid */
    var valid: Bool;
    
    /** Fields that are required */
    var required: Array<String>;
    
    /** Fields that have been prepared */
    var prepared: Array<String>;
    
    /** Filters to apply */
    var filters: Map<String, Dynamic>;
    
    /** Validations applied */
    var validations: Array<ChangesetValidation>;
    
    /** Constraints to check */
    var constraints: Array<ChangesetConstraint>;
    
    /** Repository operation type */
    var repo_opts: Option<RepoOptions>;
    
    /** Schema action (insert, update, delete) */
    var action: Option<ChangesetAction>;
    
    /** Types for the fields */
    var types: Map<String, String>;
    
    /** Whether changeset has been cast */
    var casting: Bool;
}

/**
 * Changeset validation error.
 */
typedef ChangesetError = {
    /** Field name with error */
    var field: String;
    
    /** Error message */
    var message: String;
    
    /** Error code/type */
    var code: String;
    
    /** Additional error metadata */
    var metadata: Map<String, Dynamic>;
}

/**
 * Changeset validation definition.
 */
typedef ChangesetValidation = {
    /** Field being validated */
    var field: String;
    
    /** Validation type */
    var validation: ValidationType;
    
    /** Validation options */
    var options: Map<String, Dynamic>;
}

/**
 * Changeset constraint definition.
 */
typedef ChangesetConstraint = {
    /** Constraint name */
    var name: String;
    
    /** Constraint type */
    var type: ConstraintType;
    
    /** Error message */
    var message: String;
}

/**
 * Repository operation options.
 */
typedef RepoOptions = {
    /** Transaction timeout */
    @:optional var timeout: Int;
    
    /** Whether to return struct or changeset on error */
    @:optional var returning: Bool;
    
    /** Conflict handling strategy */
    @:optional var on_conflict: ConflictStrategy;
    
    /** Whether to skip validations */
    @:optional var skip_validations: Bool;
}

/**
 * Changeset action types.
 */
enum ChangesetAction {
    /** Insert new record */
    Insert;
    
    /** Update existing record */
    Update;
    
    /** Delete record */
    Delete;
    
    /** Replace record */
    Replace;
    
    /** Ignore operation */
    Ignore;
}

/**
 * Validation types supported by Ecto.
 */
enum ValidationType {
    /** Required field validation */
    Required;
    
    /** Length validation */
    Length(min: Option<Int>, max: Option<Int>);
    
    /** Format validation (regex) */
    Format(pattern: String);
    
    /** Inclusion validation */
    Inclusion(list: Array<Dynamic>);
    
    /** Exclusion validation */
    Exclusion(list: Array<Dynamic>);
    
    /** Number validation */
    Number(min: Option<Float>, max: Option<Float>);
    
    /** Acceptance validation */
    Acceptance;
    
    /** Confirmation validation */
    Confirmation;
    
    /** Custom function validation */
    Custom(func: String);
}

/**
 * Constraint types for database constraints.
 */
enum ConstraintType {
    /** Unique constraint */
    Unique;
    
    /** Foreign key constraint */
    ForeignKey;
    
    /** Check constraint */
    Check;
    
    /** Exclusion constraint */
    Exclusion;
}

/**
 * Conflict resolution strategies.
 */
enum ConflictStrategy {
    /** Raise error on conflict */
    Error;
    
    /** Nothing (ignore conflict) */
    Nothing;
    
    /** Replace all fields */
    ReplaceAll;
    
    /** Replace specific fields */
    Replace(fields: Array<String>);
    
    /** Update specific fields */
    Update(fields: Array<String>);
}

/**
 * Result type for repository operations with changesets.
 * 
 * Represents the outcome of database operations that may succeed
 * with a record or fail with a changeset containing errors.
 */
typedef ChangesetResult<T> = Result<T, Changeset<T>>;

/**
 * Helper functions for working with changesets.
 */
class ChangesetTools {
    /**
     * Check if changeset is valid.
     */
    public static function isValid<T>(changeset: Changeset<T>): Bool {
        return changeset.valid && changeset.errors.length == 0;
    }
    
    /**
     * Check if changeset is invalid.
     */
    public static function isInvalid<T>(changeset: Changeset<T>): Bool {
        return !changeset.valid || changeset.errors.length > 0;
    }
    
    /**
     * Get all error messages for a field.
     */
    public static function getFieldErrors<T>(changeset: Changeset<T>, field: String): Array<String> {
        return changeset.errors
            .filter(error -> error.field == field)
            .map(error -> error.message);
    }
    
    /**
     * Check if field has errors.
     */
    public static function hasFieldError<T>(changeset: Changeset<T>, field: String): Bool {
        return changeset.errors.exists(error -> error.field == field);
    }
    
    /**
     * Get first error message for a field.
     */
    public static function getFirstFieldError<T>(changeset: Changeset<T>, field: String): Option<String> {
        var errors = getFieldErrors(changeset, field);
        return errors.length > 0 ? Some(errors[0]) : None;
    }
    
    /**
     * Get all error messages as a map.
     */
    public static function getErrorsMap<T>(changeset: Changeset<T>): Map<String, Array<String>> {
        var errorMap = new Map<String, Array<String>>();
        
        for (error in changeset.errors) {
            if (!errorMap.exists(error.field)) {
                errorMap.set(error.field, []);
            }
            errorMap.get(error.field).push(error.message);
        }
        
        return errorMap;
    }
    
    /**
     * Convert changeset result to Option.
     * Ok(value) -> Some(value), Error(_) -> None
     */
    public static function toOption<T>(result: ChangesetResult<T>): Option<T> {
        return switch(result) {
            case Ok(value): Some(value);
            case Error(_): None;
        };
    }
    
    /**
     * Extract value from successful result or throw.
     */
    public static function unwrap<T>(result: ChangesetResult<T>): T {
        return switch(result) {
            case Ok(value): value;
            case Error(changeset): throw 'Changeset has errors: ${getErrorsMap(changeset)}';
        };
    }
    
    /**
     * Extract value from successful result or return default.
     */
    public static function unwrapOr<T>(result: ChangesetResult<T>, defaultValue: T): T {
        return switch(result) {
            case Ok(value): value;
            case Error(_): defaultValue;
        };
    }
}