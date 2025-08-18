package phoenix.types;

/**
 * Type-safe wrapper for Phoenix Flash messages
 * 
 * Provides compile-time type checking for flash message operations
 * while maintaining runtime compatibility with Phoenix's flash behavior.
 * 
 * Usage:
 * ```haxe
 * function create(conn: Conn<UserParams>): Conn<UserParams> {
 *     return conn.putFlash(FlashMessage.info("User created successfully!"))
 *               .putFlash(FlashMessage.error("Please check your input"));
 * }
 * 
 * // In templates/views
 * var messages = socket.getFlash();
 * if (FlashMessage.hasType(messages, FlashType.Error)) {
 *     // Show error styling
 * }
 * ```
 */

/**
 * Flash message types
 */
enum FlashType {
    Info;
    Success;
    Warning;
    Error;
    Notice;
    Alert;
}

/**
 * Flash message data structure
 */
typedef FlashData = {
    type: FlashType,
    message: String,
    ?title: String,
    ?dismissible: Bool,
    ?timeout: Int,
    ?metadata: Dynamic
}

/**
 * Type-safe wrapper for flash messages
 */
abstract FlashMessage(FlashData) from FlashData to FlashData {
    
    /**
     * Create flash message from Dynamic value
     */
    public static function fromDynamic(flash: Dynamic): FlashMessage {
        return cast flash;
    }
    
    /**
     * Get the underlying Dynamic flash
     */
    public function toDynamic(): Dynamic {
        return this;
    }
    
    /**
     * Create an info flash message
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
     */
    public static function success(message: String, ?title: String): FlashMessage {
        return {
            type: Success,
            message: message,
            title: title,
            dismissible: true
        };
    }
    
    /**
     * Create a warning flash message
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
     */
    public static function error(message: String, ?title: String): FlashMessage {
        return {
            type: Error,
            message: message,
            title: title,
            dismissible: true
        };
    }
    
    /**
     * Create a notice flash message
     */
    public static function notice(message: String, ?title: String): FlashMessage {
        return {
            type: Notice,
            message: message,
            title: title,
            dismissible: true
        };
    }
    
    /**
     * Create an alert flash message
     */
    public static function alert(message: String, ?title: String): FlashMessage {
        return {
            type: Alert,
            message: message,
            title: title,
            dismissible: false  // Alerts typically require explicit dismissal
        };
    }
    
    /**
     * Get message text
     */
    public function getMessage(): String {
        return this.message;
    }
    
    /**
     * Get message type
     */
    public function getType(): FlashType {
        return this.type;
    }
    
    /**
     * Get message title
     */
    public function getTitle(): Null<String> {
        return this.title;
    }
    
    /**
     * Check if message is dismissible
     */
    public function isDismissible(): Bool {
        return this.dismissible != null ? this.dismissible : true;
    }
    
    /**
     * Get auto-timeout duration (if any)
     */
    public function getTimeout(): Null<Int> {
        return this.timeout;
    }
    
    /**
     * Get additional metadata
     */
    public function getMetadata(): Dynamic {
        return this.metadata;
    }
    
    /**
     * Set auto-timeout for message
     */
    public function withTimeout(milliseconds: Int): FlashMessage {
        var updated = Reflect.copy(this);
        updated.timeout = milliseconds;
        return updated;
    }
    
    /**
     * Set dismissible flag
     */
    public function withDismissible(dismissible: Bool): FlashMessage {
        var updated = Reflect.copy(this);
        updated.dismissible = dismissible;
        return updated;
    }
    
    /**
     * Add metadata to flash message
     */
    public function withMetadata(metadata: Dynamic): FlashMessage {
        var updated = Reflect.copy(this);
        updated.metadata = metadata;
        return updated;
    }
}

/**
 * Flash message utility functions
 */
class FlashMessageTools {
    /**
     * Convert FlashType enum to string
     */
    public static function typeToString(type: FlashType): String {
        return switch (type) {
            case Info: "info";
            case Success: "success";
            case Warning: "warning";
            case Error: "error";
            case Notice: "notice";
            case Alert: "alert";
        };
    }
    
    /**
     * Convert string to FlashType enum
     */
    public static function stringToType(str: String): FlashType {
        return switch (str.toLowerCase()) {
            case "info": Info;
            case "success": Success;
            case "warning" | "warn": Warning;
            case "error" | "danger": Error;
            case "notice": Notice;
            case "alert": Alert;
            default: Info;
        };
    }
    
    /**
     * Check if flash collection has specific type
     */
    public static function hasType(flash: Dynamic, type: FlashType): Bool {
        if (flash == null) return false;
        
        var typeStr = typeToString(type);
        return Reflect.hasField(flash, typeStr) && Reflect.field(flash, typeStr) != null;
    }
    
    /**
     * Get flash messages of specific type
     */
    public static function getByType(flash: Dynamic, type: FlashType): Null<String> {
        if (!hasType(flash, type)) return null;
        
        var typeStr = typeToString(type);
        return Reflect.field(flash, typeStr);
    }
    
    /**
     * Get all flash message types present
     */
    public static function getTypes(flash: Dynamic): Array<FlashType> {
        if (flash == null) return [];
        
        var types = [];
        var fields = Reflect.fields(flash);
        
        for (field in fields) {
            var value = Reflect.field(flash, field);
            if (value != null) {
                types.push(stringToType(field));
            }
        }
        
        return types;
    }
    
    /**
     * Check if any flash messages exist
     */
    public static function hasAny(flash: Dynamic): Bool {
        if (flash == null) return false;
        
        var fields = Reflect.fields(flash);
        for (field in fields) {
            var value = Reflect.field(flash, field);
            if (value != null) return true;
        }
        
        return false;
    }
    
    /**
     * Get CSS class for flash type
     */
    public static function getCssClass(type: FlashType): String {
        return switch (type) {
            case Info: "flash-info";
            case Success: "flash-success";
            case Warning: "flash-warning";
            case Error: "flash-error";
            case Notice: "flash-notice";
            case Alert: "flash-alert";
        };
    }
    
    /**
     * Get icon name for flash type (for icon libraries)
     */
    public static function getIconName(type: FlashType): String {
        return switch (type) {
            case Info: "info-circle";
            case Success: "check-circle";
            case Warning: "exclamation-triangle";
            case Error: "times-circle";
            case Notice: "bell";
            case Alert: "exclamation-circle";
        };
    }
    
    /**
     * Create flash message collection from individual messages
     */
    public static function createCollection(messages: Array<FlashMessage>): Dynamic {
        var collection = {};
        
        for (message in messages) {
            var typeStr = typeToString(message.getType());
            Reflect.setField(collection, typeStr, message.getMessage());
        }
        
        return collection;
    }
}

/**
 * Flash message builder for complex scenarios
 */
class FlashMessageBuilder {
    private var type: FlashType;
    private var message: String;
    private var title: Null<String>;
    private var dismissible: Bool = true;
    private var timeout: Null<Int>;
    private var metadata: Dynamic;
    
    public function new(type: FlashType, message: String) {
        this.type = type;
        this.message = message;
    }
    
    public function withTitle(title: String): FlashMessageBuilder {
        this.title = title;
        return this;
    }
    
    public function withDismissible(dismissible: Bool): FlashMessageBuilder {
        this.dismissible = dismissible;
        return this;
    }
    
    public function withTimeout(milliseconds: Int): FlashMessageBuilder {
        this.timeout = milliseconds;
        return this;
    }
    
    public function withMetadata(metadata: Dynamic): FlashMessageBuilder {
        this.metadata = metadata;
        return this;
    }
    
    public function build(): FlashMessage {
        return {
            type: type,
            message: message,
            title: title,
            dismissible: dismissible,
            timeout: timeout,
            metadata: metadata
        };
    }
}