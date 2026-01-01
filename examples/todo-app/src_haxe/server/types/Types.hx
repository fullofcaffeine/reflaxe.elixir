package server.types;

import elixir.DateTime.NaiveDateTime;
import elixir.types.Term;

/**
 * Comprehensive Phoenix LiveView types for the todo-app
 * 
 * These types provide full type safety for Phoenix LiveView interactions,
 * socket operations, event handling, and database operations.
 */

// ============================================================================
// Core Phoenix LiveView Types
// ============================================================================

/**
 * Enhanced User type matching the User schema
 */
typedef User = {
    var id: Int;
    var name: String;
    var email: String;
    var bio: Null<String>;
    var passwordHash: String;  // camelCase
    var confirmedAt: Null<NaiveDateTime>;  // camelCase
    var lastLoginAt: Null<NaiveDateTime>;  // camelCase
    var active: Bool;
}

// Socket type removed - use phoenix.Phoenix.Socket<T> instead
// This avoids conflicts with the proper Phoenix LiveView extern

/**
 * Socket assigns structure for type-safe assign access
 */
typedef SocketAssigns = {
    var todos: Array<server.schemas.Todo>;
    var filter: String;
    var sortBy: String;  // camelCase
    var currentUser: User;  // camelCase
    var editingTodo: Null<server.schemas.Todo>;  // camelCase
    var showForm: Bool;  // camelCase
    var searchQuery: String;  // camelCase
    var selectedTags: Array<String>;  // camelCase
    var totalTodos: Int;  // camelCase
    var completedTodos: Int;  // camelCase
    var pendingTodos: Int;  // camelCase
    var flash: FlashMessages;
}

/**
 * Flash message types
 */
typedef FlashMessages = {
    var ?info: String;
    var ?error: String;
    var ?success: String;
    var ?warning: String;
}

/**
 * Redirect options for navigation
 */
typedef RedirectOptions = {
    var ?to: String;
    var ?external: String;
}

/**
 * Patch options for live navigation  
 */
typedef PatchOptions = {
    var ?to: String;
    var ?replace: Bool;
}

// ============================================================================
// Event System Types  
// ============================================================================

/**
 * Comprehensive event parameters with validation
 */
typedef EventParams = {
    // Todo CRUD fields
    var ?id: Int;
    var ?title: String;
    var ?description: String;
    var ?priority: String;
    var ?dueDate: String;  // camelCase
    var ?tags: String;
    var ?completed: Bool;
    
    // UI interaction fields
    var ?filter: String;
    var ?sortBy: String;  // camelCase
    var ?query: String;
    var ?tag: String;
    var ?action: String;
    
    // Form validation metadata
    var ?_target: Array<String>;
    var ?_csrf_token: String;
    
    // Additional runtime field (avoid in app logic; decode into typed params)
    var ?value: Term;
    var ?key: String;
    var ?index: Int;
}

// ============================================================================
// Real-time Communication Types - TYPE-SAFE PUBSUB & PRESENCE
// ============================================================================

/**
 * Type-safe Presence topics - compile-time validation of presence channels
 * Use with @:presenceTopic annotation for type safety
 */
enum PresenceTopic {
    Users;           // "users" - Track online users
    EditingTodos;    // "editing:todos" - Track who's editing what
    ActiveRooms;     // "active:rooms" - Track active chat rooms
}

/**
 * Helper class for type-safe presence topic conversion
 * Provides compile-time validation while generating proper topic strings
 */
class PresenceTopics {
    /**
     * Convert a type-safe PresenceTopic to its string representation
     * for use with @:presenceTopic annotation
     */
    public static function toString(topic: PresenceTopic): String {
        return switch(topic) {
            case Users: "users";
            case EditingTodos: "editing:todos";
            case ActiveRooms: "active:rooms";
        }
    }
    
    /**
     * Parse a string back to PresenceTopic (for runtime validation if needed)
     */
    public static function fromString(topic: String): Null<PresenceTopic> {
        return switch(topic) {
            case "users": Users;
            case "editing:todos": EditingTodos;
            case "active:rooms": ActiveRooms;
            default: null;
        }
    }
}

/**
 * Type-safe PubSub topics - prevents typos and invalid topic strings
 */
enum PubSubTopic {
    TodoUpdates;          // "todo:updates"
    UserActivity;         // "user:activity"  
    SystemNotifications;  // "system:notifications"
}

/**
 * Type-safe PubSub message types - compile-time validation of message structure
 */
enum PubSubMessageType {
    TodoCreated(todo: server.schemas.Todo);
    TodoUpdated(todo: server.schemas.Todo);
    TodoDeleted(id: Int);
    BulkUpdate(action: BulkOperationType);
    UserOnline(user_id: Int);
    UserOffline(user_id: Int);
    SystemAlert(message: String, level: AlertLevel);
}

/**
 * Bulk operation types for type-safe bulk actions
 */
enum BulkOperationType {
    CompleteAll;
    DeleteCompleted;
    SetPriority(priority: TodoPriority);
    AddTag(tag: String);
    RemoveTag(tag: String);
}

// SafePubSub class moved to framework level: /std/phoenix/SafePubSub.hx
// Application-specific PubSub types moved to: server/pubsub/TodoPubSub.hx
// 
// This demonstrates the framework-level development principle:
// Common patterns discovered in applications should become framework features
// so ALL Phoenix apps benefit from the same type safety improvements.

/**
 * Alert levels for system notifications
 */
enum AlertLevel {
    Info;
    Warning;
    Error;
    Critical;
}

/**
 * Enhanced PubSub message with type safety
 */
typedef PubSubMessage = {
    var type: PubSubMessageType;
    var ?metadata: PubSubMetadata;
}

/**
 * PubSub metadata for message tracking
 */
typedef PubSubMetadata = {
    var ?timestamp: Term;
    var ?source: String;
    var ?version: String;
    var ?user_id: Int;
}

// ============================================================================
// Session and Authentication Types
// ============================================================================

/**
 * Session data structure
 */
typedef Session = {
    var ?userId: Int;  // camelCase
    var ?token: String;
    var ?csrfToken: String;  // camelCase
    var ?locale: String;
    var ?timezone: String;
    var ?userAgent: String;  // camelCase
    var ?ipAddress: String;  // camelCase
    var ?loginAt: Term;  // camelCase
}

/**
 * Mount parameters for LiveView initialization
 */
typedef MountParams = {
    var ?id: String;
    var ?action: String;
    var ?slug: String;
    var ?page: String;
    var ?filter: String;
    var ?sort: String;
    var ?search: String;
}

// ============================================================================
// Database Operation Types
// ============================================================================

/**
 * Ecto repository operation result
 */
typedef RepoResult<T> = {
    var success: Bool;
    var ?data: T;
    var ?error: String;
    var ?changeset: Term;
}

/**
 * Ecto changeset type
 */
typedef Changeset<T> = {
    var valid: Bool;
    var data: T;
    var changes: Term;
    var errors: Array<FieldError>;
    var action: Null<String>;
}

/**
 * Field validation error
 */
typedef FieldError = {
    var field: String;
    var message: String;
    var validation: String;
}

// ============================================================================
// Form and Validation Types
// ============================================================================

/**
 * Form field metadata for HEEx templates
 */
typedef FormField = {
    var id: String;
    var name: String;
    var value: Term;
    var errors: Array<String>;
    var valid: Bool;
    var data: Term;
}

/**
 * Form structure for changesets
 */
typedef Form<T> = {
    var source: Changeset<T>;
    var impl: String;
    var id: String;
    var name: String;
    var data: T;
    var params: Term;
    var hidden: Array<FormField>;
    var options: FormOptions;
}

/**
 * Form rendering options
 */
typedef FormOptions = {
    var ?method: String;
    var ?multipart: Bool;
    var ?csrf_token: String;
    var ?as: String;
}

// ============================================================================
// Component and Template Types
// ============================================================================

/**
 * Component assigns for HXX templates
 */
typedef ComponentAssigns = {
    var ?className: String;
    var ?id: String;
    var ?phx_click: String;
    var ?phx_submit: String;
    var ?phx_change: String;
    var ?phx_keyup: String;
    var ?phx_blur: String;
    var ?phx_focus: String;
    var ?phx_hook: String;
    var ?phx_update: String;
    var ?phx_target: String;
    var ?phx_debounce: String;
    var ?phx_throttle: String;
    var ?rest: Term;
}

// ============================================================================
// LiveView Lifecycle Types
// ============================================================================

// MountResult, HandleEventResult, and HandleInfoResult moved to framework level:
// - phoenix.Phoenix.MountResult<TAssigns> for type-safe mount operations
// - phoenix.Phoenix.HandleEventResult<TAssigns> for type-safe event handling
// - phoenix.Phoenix.HandleInfoResult<TAssigns> for type-safe info handling
// 
// Use framework types instead of application duplicates:
// import phoenix.Phoenix.MountResult;
// import phoenix.Phoenix.HandleEventResult;
// import phoenix.Phoenix.HandleInfoResult;
//
// This demonstrates the framework-level development principle:
// LiveView lifecycle types discovered in applications should become framework features
// so ALL Phoenix apps benefit from the same type safety improvements.

// ============================================================================
// Utility Types
// ============================================================================

// Result<T,E> and Option<T> moved to framework level:
// - haxe.functional.Result<T,E> for error handling
// - haxe.ds.Option<T> for null safety
// 
// Use framework types instead of application duplicates:
// import haxe.functional.Result;
// import haxe.ds.Option;

/**
 * Pagination metadata
 */
typedef Pagination = {
    var page: Int;
    var per_page: Int;
    var total_count: Int;
    var total_pages: Int;
    var has_next: Bool;
    var has_prev: Bool;
}

/**
 * Sort direction
 */
enum SortDirection {
    Asc;
    Desc;
}

/**
 * Sort configuration
 */
typedef SortConfig = {
    var field: String;
    var direction: SortDirection;
}

// ============================================================================
// Application-Specific Types
// ============================================================================

/**
 * Todo filter options
 */
enum TodoFilter {
    All;
    Active;
    Completed;
    ByTag(tag: String);
    ByPriority(priority: String);
    ByDueDate(date: NaiveDateTime);
}

/**
 * Todo sort options
 */
enum TodoSort {
    Created;
    Priority;
    DueDate;
    Title;
    Status;
}

/**
 * Todo priority levels
 */
enum TodoPriority {
    Low;
    Medium;
    High;
}

/**
 * Bulk operation types
 */
enum BulkOperation {
    CompleteAll;
    DeleteCompleted;
    SetPriority(priority: TodoPriority);
    AddTag(tag: String);
    RemoveTag(tag: String);
}
