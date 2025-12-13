package phoenix.types;

#if (elixir || reflaxe_runtime)

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
 * @see /docs/02-user-guide/PHOENIX_INTEGRATION.md - Complete usage guide
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
     * Convert FlashType to Phoenix LiveView flash key.
     * LiveView officially supports only :info and :error.
     * Success/Warning map to :info for compatibility.
     */
    public static function toPhoenixKey(type: FlashType): String {
        return switch (type) {
            case Info: "info";
            case Success: "info";
            case Warning: "info";
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
 * Phoenix flash data structure from socket/assigns
 */
typedef PhoenixFlashData = {
    ?type: String,
    ?message: String,
    ?title: String,
    ?details: Array<String>,
    ?dismissible: Bool,
    ?timeout: Int,
    ?action: {
        label: String,
        url: String
    }
}

/**
 * Minimal Ecto changeset representation for error extraction
 */
typedef EctoChangeset = {
    ?errors: Array<{field: String, message: {text: String, ?opts: Array<{key: String, value: String}>}}>,
    ?valid: Bool
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
     * @param title Title (use null if not needed)
     * @return FlashMessage Structured flash message
     */
    public static function info(message: String, title: String): FlashMessage {
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
     * @param title Title (use null if not needed)
     * @return FlashMessage Structured flash message
     */
    public static function success(message: String, title: String): FlashMessage {
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
     * @param title Title (use null if not needed)
     * @return FlashMessage Structured flash message
     */
    public static function warning(message: String, title: String): FlashMessage {
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
     * @param details Array of error details (use null if not needed)
     * @param title Title (use null if not needed)
     * @return FlashMessage Structured flash message
     */
    public static function error(message: String, details: Array<String>, title: String): FlashMessage {
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
    public static function validationError(message: String, changeset: EctoChangeset): FlashMessage {
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
     * @return PhoenixFlashData Phoenix-compatible flash data
     */
    public static function toPhoenixFlash(flash: FlashMessage): PhoenixFlashData {
        return {
            type: FlashTypeTools.toString(flash.type),
            message: flash.message,
            title: flash.title,
            details: flash.details,
            dismissible: flash.dismissible,
            timeout: flash.timeout,
            action: flash.action
        };
    }
    
    /**
     * Parse Phoenix flash map to structured FlashMessage
     * Used when receiving flash data from Phoenix
     * 
     * @param phoenixFlash Phoenix flash data from assigns
     * @return FlashMessage Structured flash message
     */
    public static function fromPhoenixFlash(phoenixFlash: PhoenixFlashData): FlashMessage {
        // Extract type field and convert to FlashType
        var typeString = phoenixFlash.type != null ? phoenixFlash.type : "info";
        var flashType = FlashTypeTools.fromString(typeString);
        
        // Extract message with default
        var message = phoenixFlash.message != null ? phoenixFlash.message : "";
        
        return {
            type: flashType,
            message: message,
            title: phoenixFlash.title,
            details: phoenixFlash.details,
            dismissible: phoenixFlash.dismissible != null ? phoenixFlash.dismissible : true,
            timeout: phoenixFlash.timeout,
            action: phoenixFlash.action
        };
    }
    
    /**
     * Extract error messages from Ecto changeset
     * Helper function for validation error handling
     * 
     * @param changeset Ecto changeset with errors
     * @return Array<String> List of error messages
     */
    private static function extractChangesetErrors(changeset: EctoChangeset): Array<String> {
        if (changeset == null || changeset.errors == null) {
            return [];
        }
        return changeset.errors.map(function(err) {
            var field = err.field;
            var text = (err.message != null) ? err.message.text : "";
            return '$field: $text';
        });
    }
}

#end

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
        final infoMessages = flashMap.info != null ? [Flash.info(flashMap.info, null)] : [];
        final successMessages = flashMap.success != null ? [Flash.success(flashMap.success, null)] : [];
        final warningMessages = flashMap.warning != null ? [Flash.warning(flashMap.warning, null)] : [];
        final errorMessages = flashMap.error != null ? [Flash.error(flashMap.error, null, null)] : [];

        return infoMessages
            .concat(successMessages)
            .concat(warningMessages)
            .concat(errorMessages);
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
