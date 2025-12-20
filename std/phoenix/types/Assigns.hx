package phoenix.types;

import elixir.types.Term;
import phoenix.types.Flash.FlashMap;

/**
 * Type-safe wrapper for Phoenix template assigns
 * 
 * Provides compile-time type checking for template variables while maintaining
 * runtime compatibility with Phoenix's assigns map.
 * 
 * Usage:
 * ```haxe
 * typedef UserPageAssigns = {
 *     user: User,
 *     posts: Array<Post>,
 *     ?flash: FlashMessage
 * }
 * 
 * function render(assigns: Assigns<UserPageAssigns>): String {
 *     // Type-safe access to assigns
 *     var userName = assigns.user.name;  // Compile-time type checking
 *     var postCount = assigns.posts.length;
 * }
 * ```
 * 
 * @see /docs/02-user-guide/TYPE_SAFE_PHOENIX_ABSTRACTIONS.md - Assigns/Socket/Flash typed usage
 */
@:forward
abstract Assigns<T>(T) from T to T {
    
    /**
     * Create typed assigns from an arbitrary term
     * Used when receiving assigns from Phoenix.
     * 
     * @param value Raw assigns map from Phoenix
     * @return Assigns<T> Type-safe wrapper
     */
    @:from
    public static function fromDynamic<T>(value: Term): Assigns<T> {
        return cast value;
    }
    
    /**
     * Create typed assigns from a structured object
     * Used when building assigns in Haxe code
     * 
     * @param obj Typed object matching the assigns structure
     * @return Assigns<T> Type-safe wrapper
     */
    public static function fromObject<T>(obj: T): Assigns<T> {
        return cast obj;
    }
    
    /**
     * Get the underlying term
     * Use when passing to Phoenix functions that expect a raw term.
     * 
     * @return Term Raw assigns map for Phoenix compatibility
     */
    @:to
    public function toDynamic(): Term {
        return cast this;
    }
    
    /**
     * Array-style field access (Reading)
     * 
     * Enables syntax: assigns["field"] for type-safe field access
     * Following the same pattern as haxe.DynamicAccess and Map
     * 
     * @param key Field name to access
     * @return Term Field value, null if not present
     */
    @:arrayAccess
    public inline function get(key: String): Term {
        return Reflect.field(this, key);
    }
    
    /**
     * Array-style field assignment (Writing)
     * 
     * Enables syntax: assigns["field"] = value for type-safe field assignment
     * Following the same pattern as haxe.DynamicAccess and Map
     * 
     * @param key Field name to set
     * @param value Value to assign
     * @return V The assigned value
     */
    @:arrayAccess
    public inline function set<V>(key: String, value: V): V {
        Reflect.setField(this, key, value);
        return value;
    }
    
    /**
     * Alternative method-based field access
     * 
     * Use when you prefer explicit method calls over array syntax
     * 
     * @param field Field name to access
     * @return Term Field value
     */
    public inline function getField(field: String): Term {
        return Reflect.field(this, field);
    }
    
    /**
     * Alternative method-based field assignment
     * 
     * Use when you prefer explicit method calls over array syntax
     * 
     * @param field Field name to set
     * @param value Value to assign
     * @return V The assigned value
     */
    public inline function setField<V>(field: String, value: V): V {
        Reflect.setField(this, field, value);
        return value;
    }
    
    /**
     * Check if a field exists in assigns
     * 
     * @param field Field name to check
     * @return Bool True if field exists
     */
    public function hasField(field: String): Bool {
        return Reflect.hasField(this, field);
    }
    
    /**
     * Get all field names
     * Useful for debugging and introspection
     * 
     * @return Array<String> List of all assign keys
     */
    public function getFields(): Array<String> {
        return Reflect.fields(this);
    }
    
    /**
     * Merge with another assigns object
     * Creates a new assigns with combined fields
     * 
     * @param other Other assigns to merge
     * @return Assigns<T> New merged assigns
     */
    public function merge<U>(other: Assigns<U>): Assigns<T> {
        var result = {};
        
        // Copy current assigns
        for (field in Reflect.fields(this)) {
            Reflect.setField(result, field, Reflect.field(this, field));
        }
        
        // Copy other assigns (overwrites existing)
        for (field in Reflect.fields(other.toDynamic())) {
            Reflect.setField(result, field, Reflect.field(other.toDynamic(), field));
        }
        
        return fromDynamic(result);
    }
    
    /**
     * Create a new assigns with an additional field
     * Type-safe way to add assigns
     * 
     * @param field Field name to add
     * @param value Field value to add
     * @return Assigns<T> New assigns with additional field
     */
    public function withField<V>(field: String, value: V): Assigns<T> {
        var result = {};
        
        // Copy existing fields
        for (existingField in Reflect.fields(this)) {
            Reflect.setField(result, existingField, Reflect.field(this, existingField));
        }
        
        // Add new field
        Reflect.setField(result, field, value);
        
        return fromDynamic(result);
    }
}

/**
 * Common assigns types for typical Phoenix applications
 * These can be extended or used as-is for standard patterns
 */

/**
 * Basic layout assigns
 * Contains common fields needed in most layout templates
 */
typedef LayoutAssigns<TUser, TSocketAssigns> = {
    inner_content: String,
    ?flash: FlashMap,
    ?csrf_token: String,
    ?current_user: TUser,
    ?page_title: String
}

/**
 * Live view assigns base
 * Common fields for LiveView components
 */
typedef LiveViewAssigns<TUser, TSocketAssigns> = {
    ?flash: FlashMap,
    ?live_action: String,
    ?current_user: TUser,
    ?socket: Socket<TSocketAssigns>
}

/**
 * Empty assigns for simple templates
 * Use when no specific assigns are needed
 */
typedef EmptyAssigns = {}
