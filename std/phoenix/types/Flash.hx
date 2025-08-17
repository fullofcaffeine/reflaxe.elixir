package phoenix.types;

/**
 * Type-safe flash message system for Phoenix applications
 * 
 * Provides compile-time checking for flash message types and structured
 * access to flash data while maintaining Phoenix compatibility.
 * 
 * Usage:
 * ```haxe
 * // Type-safe flash creation
 * var flash = FlashMessage.info("User created successfully");
 * var errorFlash = FlashMessage.error("Validation failed", ["Name is required"]);
 * 
 * // Type-safe flash checking
 * if (flash.hasType(FlashType.Error)) {
 *     // Handle error display
 * }
 * ```
 * 
 * @see documentation/guides/TYPE_SAFE_FLASH.md - Complete usage guide
 */

/**
 * Standard flash message types used in Phoenix applications
 * 
 * These correspond to common CSS classes and UI patterns:
 * - Info: Blue, informational messages
 * - Success: Green, confirmation messages  
 * - Warning: Yellow, caution messages
 * - Error: Red, error messages
 */
enum FlashType {
    Info;
    Success;
    Warning;
    Error;
}

/**
 * Helper functions for FlashType enum
 */
class FlashTypeTools {
    
    /**
     * Convert FlashType to string for Phoenix compatibility
     * 
     * @param type Flash type enum value
     * @return String Phoenix-compatible string representation
     */
    public static function toString(type: FlashType): String {
        return switch (type) {
            case Info: "info";
            case Success: "success";
            case Warning: "warning";
            case Error: "error";
        };
    }
    
    /**
     * Parse string to FlashType
     * 
     * @param str String representation of flash type
     * @return FlashType Enum value, defaults to Info for unknown strings
     */
    public static function fromString(str: String): FlashType {
        return switch (str.toLowerCase()) {
            case "info": Info;
            case "success": Success;
            case "warning": Warning;
            case "error": Error;
            case _: Info; // Default fallback
        };
    }
    
    /**
     * Get CSS class for flash type
     * Standard Tailwind CSS classes for flash styling
     * 
     * @param type Flash type enum value
     * @return String CSS class string
     */
    public static function getCssClass(type: FlashType): String {
        return switch (type) {
            case Info: "bg-blue-50 border-blue-200 text-blue-800";
            case Success: "bg-green-50 border-green-200 text-green-800";
            case Warning: "bg-yellow-50 border-yellow-200 text-yellow-800";
            case Error: "bg-red-50 border-red-200 text-red-800";
        };
    }
    
    /**
     * Get icon name for flash type
     * Standard icon names for flash message display
     * 
     * @param type Flash type enum value
     * @return String Icon name (compatible with Heroicons or similar)
     */
    public static function getIconName(type: FlashType): String {
        return switch (type) {
            case Info: "information-circle";
            case Success: "check-circle";
            case Warning: "exclamation-triangle";
            case Error: "x-circle";
        };
    }
}

/**
 * Structured flash message with metadata
 * 
 * Provides a typed interface for flash messages that can carry
 * additional context beyond just a string message.
 */
typedef FlashMessage = {
    type: FlashType,
    message: String,
    ?title: String,
    ?details: Array<String>,
    ?dismissible: Bool,
    ?timeout: Int,  // Auto-dismiss timeout in milliseconds
    ?action: {
        label: String,
        url: String
    }
}

/**
 * Type-safe flash message builder and utilities
 */
class Flash {
    
    /**
     * Create an info flash message
     * 
     * @param message Primary message text
     * @param title Optional title
     * @return FlashMessage Structured flash message
     */
    public static function info(message: String, ?title: String): FlashMessage {
        return {
            type: Info,
            message: message,
            title: title,
            dismissible: true
        };
    }
    
    /**
     * Create a success flash message
     * 
     * @param message Primary message text
     * @param title Optional title
     * @return FlashMessage Structured flash message
     */
    public static function success(message: String, ?title: String): FlashMessage {
        return {
            type: Success,
            message: message,
            title: title,
            dismissible: true,
            timeout: 5000  // Auto-dismiss success messages
        };
    }
    
    /**
     * Create a warning flash message
     * 
     * @param message Primary message text
     * @param title Optional title
     * @return FlashMessage Structured flash message
     */
    public static function warning(message: String, ?title: String): FlashMessage {
        return {
            type: Warning,
            message: message,
            title: title,
            dismissible: true
        };
    }
    
    /**
     * Create an error flash message
     * 
     * @param message Primary message text
     * @param details Optional array of error details
     * @param title Optional title
     * @return FlashMessage Structured flash message
     */
    public static function error(message: String, ?details: Array<String>, ?title: String): FlashMessage {
        return {
            type: Error,
            message: message,
            details: details,
            title: title,
            dismissible: true
        };
    }
    
    /**
     * Create a validation error flash from changeset errors
     * 
     * @param message Primary message text
     * @param changeset Ecto changeset with validation errors
     * @return FlashMessage Error flash with validation details
     */
    public static function validationError(message: String, changeset: Dynamic): FlashMessage {
        var errors = extractChangesetErrors(changeset);
        return {
            type: Error,
            message: message,
            details: errors,
            title: "Validation Failed",
            dismissible: true
        };
    }
    
    /**
     * Convert FlashMessage to Phoenix-compatible map
     * Used when passing flash messages to Phoenix functions
     * 
     * @param flash Structured flash message
     * @return Dynamic Phoenix-compatible flash map
     */
    public static function toPhoenixFlash(flash: FlashMessage): Dynamic {
        var result = {
            type: FlashTypeTools.toString(flash.type),
            message: flash.message
        };
        
        if (flash.title != null) {
            Reflect.setField(result, "title", flash.title);
        }
        
        if (flash.details != null) {
            Reflect.setField(result, "details", flash.details);
        }
        
        if (flash.dismissible != null) {
            Reflect.setField(result, "dismissible", flash.dismissible);
        }
        
        if (flash.timeout != null) {
            Reflect.setField(result, "timeout", flash.timeout);
        }
        
        if (flash.action != null) {
            Reflect.setField(result, "action", flash.action);
        }
        
        return result;
    }
    
    /**
     * Parse Phoenix flash map to structured FlashMessage
     * Used when receiving flash data from Phoenix
     * 
     * @param phoenixFlash Phoenix flash map
     * @return FlashMessage Structured flash message
     */
    public static function fromPhoenixFlash(phoenixFlash: Dynamic): FlashMessage {
        var type = FlashTypeTools.fromString(Reflect.field(phoenixFlash, "type"));
        var message = Reflect.field(phoenixFlash, "message");
        
        return {
            type: type,
            message: message,
            title: Reflect.field(phoenixFlash, "title"),
            details: Reflect.field(phoenixFlash, "details"),
            dismissible: Reflect.field(phoenixFlash, "dismissible"),
            timeout: Reflect.field(phoenixFlash, "timeout"),
            action: Reflect.field(phoenixFlash, "action")
        };
    }
    
    /**
     * Extract error messages from Ecto changeset
     * Helper function for validation error handling
     * 
     * @param changeset Ecto changeset with errors
     * @return Array<String> List of error messages
     */
    private static function extractChangesetErrors(changeset: Dynamic): Array<String> {
        var errors: Array<String> = [];
        
        // This is a simplified extraction - in practice, you'd traverse
        // the changeset.errors structure properly
        var changesetErrors = Reflect.field(changeset, "errors");
        if (changesetErrors != null) {
            // Convert Elixir error format to string array
            // Implementation depends on specific changeset structure
            for (field in Reflect.fields(changesetErrors)) {
                var fieldErrors = Reflect.field(changesetErrors, field);
                if (Std.isOfType(fieldErrors, Array)) {
                    for (error in cast(fieldErrors, Array<Dynamic>)) {
                        errors.push('${field}: ${error}');
                    }
                } else {
                    errors.push('${field}: ${fieldErrors}');
                }
            }
        }
        
        return errors;
    }
}

/**
 * Flash message map type for Phoenix compatibility
 * Used in assigns and socket state
 */
typedef FlashMap = {
    ?info: String,
    ?success: String,
    ?warning: String,
    ?error: String
}

/**
 * Utilities for working with Phoenix flash maps
 */
class FlashMapTools {
    
    /**
     * Check if flash map has any messages
     * 
     * @param flashMap Phoenix flash map
     * @return Bool True if any flash messages exist
     */
    public static function hasAny(flashMap: FlashMap): Bool {
        return flashMap.info != null || 
               flashMap.success != null || 
               flashMap.warning != null || 
               flashMap.error != null;
    }
    
    /**
     * Get all flash messages as structured array
     * 
     * @param flashMap Phoenix flash map
     * @return Array<FlashMessage> Array of structured flash messages
     */
    public static function getAll(flashMap: FlashMap): Array<FlashMessage> {
        var messages: Array<FlashMessage> = [];
        
        if (flashMap.info != null) {
            messages.push(Flash.info(flashMap.info));
        }
        if (flashMap.success != null) {
            messages.push(Flash.success(flashMap.success));
        }
        if (flashMap.warning != null) {
            messages.push(Flash.warning(flashMap.warning));
        }
        if (flashMap.error != null) {
            messages.push(Flash.error(flashMap.error));
        }
        
        return messages;
    }
    
    /**
     * Clear all flash messages
     * 
     * @return FlashMap Empty flash map
     */
    public static function clear(): FlashMap {
        return {};
    }
}