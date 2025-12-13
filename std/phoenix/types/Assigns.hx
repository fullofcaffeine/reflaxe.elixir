package phoenix.types;

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
 * @see /docs/06-guides/TYPE_SAFE_ASSIGNS.md - Complete usage guide
 */
abstract Assigns<T>(Dynamic) from Dynamic to Dynamic {
    
    /**
     * Create typed assigns from a Dynamic value
     * Used when receiving assigns from Phoenix
     * 
     * @param value Raw assigns map from Phoenix
     * @return Assigns<T> Type-safe wrapper
     */
    public static function fromDynamic<T>(value: Dynamic): Assigns<T> {
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
     * Get the underlying Dynamic value
     * Use when passing to Phoenix functions that expect Dynamic
     * 
     * @return Dynamic Raw assigns map for Phoenix compatibility
     */
    public function toDynamic(): Dynamic {
        return this;
    }
    
    /**
     * Array-style field access (Reading)
     * 
     * Enables syntax: assigns["field"] for type-safe field access
     * Following the same pattern as haxe.DynamicAccess and Map
     * 
     * @param key Field name to access
     * @return Dynamic Field value, null if not present
     */
    @:arrayAccess
    public inline function get(key: String): Dynamic {
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
     * @return Dynamic Field value
     */
    public inline function getField(field: String): Dynamic {
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
    
    /**
     * Phoenix-specific assigns access
     * Special handling for common Phoenix assigns patterns
     */
    
    /**
     * Get inner_content (common in layouts)
     * This is automatically provided by Phoenix for layout templates
     * 
     * @return String The inner content HTML
     */
    public function getInnerContent(): String {
        return Reflect.field(this, "inner_content");
    }
    
    /**
     * Get flash messages
     * Type-safe access to flash message map
     * 
     * @return Dynamic Flash message map (TODO: replace with typed FlashMessage)
     */
    public function getFlash(): Dynamic {
        return Reflect.field(this, "flash");
    }
    
    /**
     * Get current user (common pattern in Phoenix apps)
     * Returns null if not present
     * 
     * @return Dynamic Current user object (TODO: replace with typed User)
     */
    public function getCurrentUser(): Dynamic {
        return Reflect.field(this, "current_user");
    }
    
    /**
     * Get CSRF token (for forms)
     * 
     * @return String CSRF token for form protection
     */
    public function getCsrfToken(): String {
        return Reflect.field(this, "csrf_token");
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
typedef LayoutAssigns = {
    inner_content: String,
    ?flash: Dynamic,
    ?csrf_token: String,
    ?current_user: Dynamic,
    ?page_title: String
}

/**
 * Live view assigns base
 * Common fields for LiveView components
 */
typedef LiveViewAssigns = {
    ?flash: Dynamic,
    ?live_action: String,
    ?current_user: Dynamic,
    ?socket: Dynamic
}

/**
 * Empty assigns for simple templates
 * Use when no specific assigns are needed
 */
typedef EmptyAssigns = {}
