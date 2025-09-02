package ecto;

import haxe.ds.Option;
import haxe.functional.Result;

/**
 * Internal data structure for changesets.
 * This is what gets passed to Elixir.
 */
typedef ChangesetData<T, P> = {
    /** The original data being changed */
    var data: T;
    
    /** The typed parameters that were provided */  
    var params: P;
    
    /** Validation errors */
    var errors: Array<ChangesetError>;
    
    /** Whether the changeset is valid */
    var valid: Bool;
    
    /** Fields that are required */
    var required: Array<String>;
    
    /** Schema action (insert, update, delete) */
    var action: Option<ChangesetAction>;
}

/**
 * The actual Changeset abstract type that provides type-safe operations.
 */
abstract Changeset<T, P>(ChangesetData<T, P>) {
    public var data(get, never): T;
    public var params(get, never): P;
    public var errors(get, never): Array<ChangesetError>;
    public var valid(get, never): Bool;
    
    public function new(data: T, params: P) {
        this = {
            data: data,
            params: params,
            errors: [],
            valid: true,
            required: [],
            action: None
        };
    }
    
    inline function get_data(): T return this.data;
    inline function get_params(): P return this.params;
    inline function get_errors(): Array<ChangesetError> return this.errors;
    inline function get_valid(): Bool return this.valid;
    
    /**
     * Create a changeset from data and params.
     * Fully typed, no Dynamic!
     */
    public static function create<T, P>(data: T, params: P): Changeset<T, P> {
        return new Changeset(data, params);
    }
    
    /**
     * Validate required fields.
     */
    public function validateRequired(fields: Array<String>): Changeset<T, P> {
        // Implementation would use macros to check if fields in P are null
        return create(this.data, this.params);
    }
    
    /**
     * Validate string length.
     */
    public function validateLength(field: String, opts: {?min: Int, ?max: Int}): Changeset<T, P> {
        // Implementation would use macros to access field from P and validate
        return create(this.data, this.params);
    }
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
    var metadata: Map<String, String>;
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
    var options: Map<String, String>;
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
    Inclusion(list: Array<String>);
    
    /** Exclusion validation */
    Exclusion(list: Array<String>);
    
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
typedef ChangesetResult<T, P> = Result<T, Changeset<T, P>>;

/**
 * Helper functions for working with changesets.
 * 
 * DESIGN NOTE: Why Map<String, Dynamic> for changes?
 * 
 * Ecto changesets need to track heterogeneous field types (String, Int, Bool, Date, etc.)
 * in a single structure. While we provide typed APIs for creating changesets,
 * internally we need this flexibility for Ecto compatibility.
 * 
 * However, users NEVER interact with this Dynamic directly - they use typed
 * parameter structures and our type-safe builder APIs.
 */
class ChangesetTools {
    /**
     * Check if changeset is valid.
     */
    public static function isValid<T, P>(changeset: Changeset<T, P>): Bool {
        return changeset.valid && changeset.errors.length == 0;
    }
    
    /**
     * Check if changeset is invalid.
     */
    public static function isInvalid<T, P>(changeset: Changeset<T, P>): Bool {
        return !changeset.valid || changeset.errors.length > 0;
    }
    
    /**
     * Get all error messages for a field.
     */
    public static function getFieldErrors<T, P>(changeset: Changeset<T, P>, field: String): Array<String> {
        return changeset.errors
            .filter(error -> error.field == field)
            .map(error -> error.message);
    }
    
    /**
     * Check if field has errors.
     */
    public static function hasFieldError<T, P>(changeset: Changeset<T, P>, field: String): Bool {
        return Lambda.exists(changeset.errors, error -> error.field == field);
    }
    
    /**
     * Get first error message for a field.
     */
    public static function getFirstFieldError<T, P>(changeset: Changeset<T, P>, field: String): Option<String> {
        var errors = getFieldErrors(changeset, field);
        return errors.length > 0 ? Some(errors[0]) : None;
    }
    
    /**
     * Get all error messages as a map.
     */
    public static function getErrorsMap<T, P>(changeset: Changeset<T, P>): Map<String, Array<String>> {
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
    public static function toOption<T, P>(result: ChangesetResult<T, P>): Option<T> {
        return switch(result) {
            case Ok(value): Some(value);
            case Error(_): None;
        };
    }
    
    /**
     * Extract value from successful result or throw.
     */
    public static function unwrap<T, P>(result: ChangesetResult<T, P>): T {
        return switch(result) {
            case Ok(value): value;
            case Error(changeset): throw 'Changeset has errors: ${getErrorsMap(changeset)}';
        };
    }
    
    /**
     * Extract value from successful result or return default.
     */
    public static function unwrapOr<T, P>(result: ChangesetResult<T, P>, defaultValue: T): T {
        return switch(result) {
            case Ok(value): value;
            case Error(_): defaultValue;
        };
    }
}