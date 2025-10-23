package phoenix;

// Import framework types
import haxe.functional.Result;
import haxe.ds.Option;
import phoenix.Ecto.Changeset;

/**
 * Comprehensive Phoenix framework extern definitions with full type safety
 * 
 * Provides strongly-typed interfaces for Phoenix controllers, LiveView, HTML helpers,
 * PubSub messaging, and routing - eliminating all Dynamic types for compile-time safety.
 * 
 * ## Three-Layer LiveView Socket Design
 * 
 * This module provides three related types for LiveView socket handling:
 * 
 * 1. **Socket<T>** - The base Phoenix.LiveView.Socket struct
 *    - Direct mapping to Elixir's Phoenix.LiveView.Socket
 *    - What Phoenix functions expect and return
 *    - Contains assigns, connection state, etc.
 * 
 * 2. **LiveSocket<T>** (in LiveSocket.hx) - Type-safe Haxe wrapper
 *    - Abstract type wrapping Socket<T> with zero runtime overhead
 *    - Provides compile-time validated assign operations
 *    - Implicitly converts to/from Socket<T>
 *    - Prevents typos in assign keys at compile time
 * 
 * 3. **LiveView** (below) - Static functions module
 *    - Maps to Phoenix.LiveView module functions
 *    - Provides assign/3, push_patch/2, etc.
 *    - Traditional Phoenix operations
 * 
 * ## Usage Pattern
 * ```haxe
 * function mount(params, session, socket: Socket<MyAssigns>) {
 *     // Option 1: Use LiveView functions (mirrors Elixir)
 *     socket = LiveView.assign(socket, "count", 0);
 *     
 *     // Option 2: Convert to LiveSocket for type safety
 *     var liveSocket: LiveSocket<MyAssigns> = socket;
 *     liveSocket = liveSocket.assign(_.count, 0);  // Compile-time validated!
 *     
 *     return Ok(socket);
 * }
 * ```
 */

/**
 * Phoenix.Controller for handling HTTP requests with type-safe operations
 */
@:native("Phoenix.Controller")
extern class Controller {
    /**
     * Render a template with type-safe assigns
     */
    static function render<T>(conn: Conn, template: String, assigns: T): Conn;
    
    /**
     * Redirect to a path or URL with proper options
     */
    static function redirect(conn: Conn, options: RedirectOptions): Conn;
    
    /**
     * Send a JSON response with proper encoding
     */
    static function json<T>(conn: Conn, data: T): Conn;
    
    /**
     * Send plain text response
     */
    static function text(conn: Conn, text: String): Conn;
    
    /**
     * Send HTML response
     */
    static function html(conn: Conn, html: String): Conn;
    
    /**
     * Put HTTP status code
     */
    @:native("put_status")
    static function putStatus(conn: Conn, status: HttpStatus): Conn;
    
    /**
     * Put response header with validation
     */
    @:native("put_resp_header")
    static function putRespHeader(conn: Conn, key: String, value: String): Conn;
    
    /**
     * Put flash message with type-safe message types
     */
    @:native("put_flash")
    static function putFlash(conn: Conn, type: FlashType, message: String): Conn;
    
    /**
     * Get flash message with optional type filter
     */
    @:native("get_flash")
    static function getFlash(conn: Conn, ?type: FlashType): Option<String>;
    
    /**
     * Assign values to the connection for templates
     */
    static function assign<T>(conn: Conn, key: String, value: T): Conn;
    
    /**
     * Assign multiple values at once
     */
    @:native("assign")
    static function assignMultiple<T>(conn: Conn, assigns: T): Conn;
}

/**
 * Phoenix.LiveView for real-time interactive applications with complete type safety
 * 
 * ## Static Method Generics Pattern
 * 
 * This extern follows Haxe's standard pattern where static methods declare their own type parameters
 * instead of referencing the class's type parameter. This is the same pattern used by Promise<T>,
 * Type, and Reflect in Haxe's standard library.
 * 
 * ## Usage Example
 * ```haxe
 * typedef MyAssigns = { todos: Array<Todo>, filter: String };
 * 
 * // Type parameter TAssigns will be inferred as MyAssigns
 * LiveView.mount<MyAssigns>(params, session, socket);
 * ```
 * 
 * @see /documentation/GENERIC_EXTERN_STATIC_FUNCTIONS.md - Complete explanation of this pattern
 */
@:native("Phoenix.LiveView")
extern class LiveView {
    /**
     * Mount callback - called when LiveView is first rendered
     * 
     * @param TAssigns The type of socket assigns structure for this mount operation
     */
    static function mount<TAssigns>(params: MountParams, session: Session, socket: Socket<TAssigns>): MountResult<TAssigns>;
    
    /**
     * Handle event from client with type-safe event parameters
     * 
     * @param TAssigns The type of socket assigns structure for this event operation
     */
    static function handleEvent<TAssigns>(event: String, params: EventParams, socket: Socket<TAssigns>): HandleEventResult<TAssigns>;
    
    /**
     * Handle info messages from processes
     * 
     * @param TAssigns The type of socket assigns structure for this info operation
     */
    static function handleInfo<TAssigns>(info: PubSubMessage, socket: Socket<TAssigns>): HandleInfoResult<TAssigns>;
    
    /**
     * Render the LiveView template with typed assigns
     */
    static function render<T>(assigns: T): String;
    
    /**
     * Assign single value to the socket
     * 
     * IMPORTANT: The value parameter is Dynamic because it can be any type.
     * Phoenix.LiveView.assign/3 accepts any value for the given key.
     * The key must be a string that will be converted to an atom in Elixir.
     * 
     * Example:
     * ```haxe
     * socket = LiveView.assign(socket, "user", currentUser);
     * socket = LiveView.assign(socket, "count", 42);
     * ```
     * 
     * @param TAssigns The type of socket assigns structure
     * @param key The assign key (will be converted to atom in Elixir)
     * @param value The value to assign (can be any type)
     */
    static function assign<TAssigns>(socket: Socket<TAssigns>, key: String, value: Dynamic): Socket<TAssigns>;
    
    /**
     * Assign multiple values to the socket using a map of assigns
     * 
     * IMPORTANT: Phoenix.LiveView doesn't have a direct assign/2 function.
     * This function should use the socket's assign function internally.
     * 
     * In Phoenix LiveView, bulk assigns are done through the socket itself,
     * not through the Phoenix.LiveView module. This is a helper that generates
     * the proper socket.assign/2 call.
     * 
     * Example:
     * ```haxe
     * socket = LiveView.assignMultiple(socket, {
     *     user: currentUser,
     *     count: 42,
     *     showForm: true
     * });
     * ```
     * 
     * Generates:
     * ```elixir
     * assign(socket, %{user: current_user, count: 42, show_form: true})
     * ```
     * 
     * @param TAssigns The type of socket assigns structure
     * @param assigns Partial assigns object (only fields being updated)
     */
    extern inline static function assignMultiple<TAssigns>(socket: Socket<TAssigns>, assigns: Dynamic): Socket<TAssigns> {
        // Emit fully-qualified call to prevent reliance on local imports
        return untyped __elixir__('Phoenix.Component.assign({0}, {1})', socket, assigns);
    }
    
    /**
     * Assign new values only if not already present
     * 
     * @param TAssigns The type of socket assigns structure
     * @param TValue The type of the value being assigned
     */
    @:native("assign_new")
    static function assignNew<TAssigns, TValue>(socket: Socket<TAssigns>, key: String, func: () -> TValue): Socket<TAssigns>;
    
    /**
     * Update an assign value with a function
     * 
     * @param TAssigns The type of socket assigns structure  
     * @param TValue The type of the specific field being updated
     */
    static function update<TAssigns, TValue>(socket: Socket<TAssigns>, key: String, updater: TValue -> TValue): Socket<TAssigns>;
    
    /**
     * Push a patch to the client (live navigation)
     * 
     * @param TAssigns The type of socket assigns structure
     */
    @:native("push_patch")
    static function pushPatch<TAssigns>(socket: Socket<TAssigns>, options: PatchOptions): Socket<TAssigns>;
    
    /**
     * Push a redirect to the client
     * 
     * @param TAssigns The type of socket assigns structure
     */
    @:native("push_redirect")
    static function pushRedirect<TAssigns>(socket: Socket<TAssigns>, options: RedirectOptions): Socket<TAssigns>;
    
    /**
     * Push an event to the client-side hooks
     * 
     * @param TAssigns The type of socket assigns structure
     * @param TPayload The type of the event payload
     */
    @:native("push_event")
    static function pushEvent<TAssigns, TPayload>(socket: Socket<TAssigns>, event: String, payload: TPayload): Socket<TAssigns>;
    
    /**
     * Put flash message for LiveView
     * 
     * @param TAssigns The type of socket assigns structure
     */
    @:native("put_flash")
    static function putFlash<TAssigns>(socket: Socket<TAssigns>, type: FlashType, message: String): Socket<TAssigns>;
    
    /**
     * Put temporary flash (cleared after next render)
     * 
     * @param TAssigns The type of socket assigns structure
     */
    @:native("put_temp_flash")
    static function putTempFlash<TAssigns>(socket: Socket<TAssigns>, type: FlashType, message: String): Socket<TAssigns>;
    
    /**
     * Clear flash messages from the socket
     * 
     * ## Critical Naming Issue Resolution
     * 
     * **IMPORTANT**: This function is named `clearFlash` in Haxe but maps to `clear_flash` in Elixir.
     * 
     * ### The Problem (Fixed)
     * Previously named `clear_flash` directly in Haxe, which caused compilation error:
     * ```
     * Field index for clear_flash not found on prototype Phoenix.LiveView
     * ```
     * 
     * ### Root Cause
     * Haxe's eval target (used during macro expansion) has issues resolving snake_case field names
     * on extern classes. This is a known Haxe limitation when the eval target tries to access
     * fields during compilation, particularly for extern classes with generic methods.
     * 
     * ### The Solution
     * - Use camelCase naming in Haxe: `clearFlash`
     * - Map to snake_case in Elixir via: `@:native("clear_flash")`
     * - This follows Haxe conventions while generating correct Elixir code
     * 
     * ### General Pattern
     * For all Phoenix.LiveView methods with snake_case names in Elixir:
     * 1. Define with camelCase in Haxe extern
     * 2. Use @:native("snake_case_name") to map to Elixir
     * 3. This avoids eval target field resolution issues
     * 
     * @param TAssigns The type of socket assigns structure
     * @param type Optional flash type to clear (Info, Error, etc.)
     * @return Updated socket with flash messages cleared
     * 
     * @see https://github.com/HaxeFoundation/haxe/issues/11631 - Similar field index issues
     */
    @:native("clear_flash")
    @:overload(function<TAssigns>(socket: Socket<TAssigns>): Socket<TAssigns> {})
    static function clearFlash<TAssigns>(socket: Socket<TAssigns>, type: FlashType): Socket<TAssigns>;
    
    /**
     * Check if socket is connected (not during initial render)
     * 
     * @param TAssigns The type of socket assigns structure
     */
    static function connected<TAssigns>(socket: Socket<TAssigns>): Bool;
    
    /**
     * Get assign value with type safety
     * 
     * @param TAssigns The type of socket assigns structure
     * @param TValue The type of the specific field being retrieved
     */
    static function getAssign<TAssigns, TValue>(socket: Socket<TAssigns>, key: String): Option<TValue>;

    /**
     * Streams API – declarative collection rendering helpers
     * Mirrors Phoenix.LiveView.stream/3 and friends; options are left Dynamic for flexibility.
     */
    @:native("stream")
    static function stream<TAssigns>(socket: Socket<TAssigns>, name: String, item: Dynamic, ?opts: Dynamic): Socket<TAssigns>;

    @:native("stream_insert")
    static function streamInsert<TAssigns>(socket: Socket<TAssigns>, name: String, item: Dynamic, ?opts: Dynamic): Socket<TAssigns>;

    @:native("stream_delete")
    static function streamDelete<TAssigns>(socket: Socket<TAssigns>, name: String, item: Dynamic, ?opts: Dynamic): Socket<TAssigns>;

    /**
     * Uploads API – allow and consume uploads
     */
    @:native("allow_upload")
    static function allowUpload<TAssigns>(socket: Socket<TAssigns>, name: String, options: Dynamic): Socket<TAssigns>;

    @:native("consume_uploaded_entries")
    static function consumeUploadedEntries<TAssigns>(socket: Socket<TAssigns>, name: String, handler: Dynamic): Array<Dynamic>;
}

/**
 * Phoenix.HTML helpers for generating type-safe HTML
 */
@:native("Phoenix.HTML")
extern class HTML {
    /**
     * Generate a type-safe link element
     */
    static function link(text: String, options: LinkOptions): String;
    
    /**
     * Generate a form with changeset validation
     */
    static function formFor<T>(changeset: Changeset<T>, action: String, options: FormOptions, content: Form<T> -> String): String;
    
    /**
     * Generate form inputs with proper typing
     */
    static function textInput<T>(form: Form<T>, field: String, options: InputOptions): String;
    static function emailInput<T>(form: Form<T>, field: String, options: InputOptions): String;
    static function passwordInput<T>(form: Form<T>, field: String, options: InputOptions): String;
    static function textarea<T>(form: Form<T>, field: String, options: TextareaOptions): String;
    static function select<T>(form: Form<T>, field: String, options: Array<SelectOption>, inputOptions: InputOptions): String;
    static function checkbox<T>(form: Form<T>, field: String, options: CheckboxOptions): String;
    static function hiddenInput<T>(form: Form<T>, field: String, options: InputOptions): String;
    
    /**
     * Form labels and validation display
     */
    static function label<T>(form: Form<T>, field: String, options: LabelOptions): String;
    static function errorTag<T>(form: Form<T>, field: String): String;
    
    /**
     * Submit button with options
     */
    static function submit(text: String, options: SubmitOptions): String;
    
    /**
     * Mark HTML as safe (use carefully!)
     */
    static function raw(html: String): SafeHTML;
    
    /**
     * Escape HTML for security
     */
    static function htmlEscape(text: String): String;
    
    /**
     * Generate CSRF token
     */
    static function csrfMetaTag(): String;
}

/**
 * Phoenix.Router helpers for generating type-safe paths and URLs
 */
@:native("Phoenix.Router")
extern class Router {
    /**
     * Generate a path for a route with parameters
     */
    static function path<T>(conn: Conn, route: RouteHelper, params: T): String;
    
    /**
     * Generate a URL for a route with parameters
     */
    static function url<T>(conn: Conn, route: RouteHelper, params: T): String;
    
    /**
     * Get current path from connection
     */
    static function currentPath(conn: Conn): String;
    
    /**
     * Get current URL from connection
     */
    static function currentUrl(conn: Conn): String;
    
    /**
     * Get current route from connection
     */
    static function currentRoute(conn: Conn): Option<String>;
    
    /**
     * Check if current route matches pattern
     */
    static function routeMatches(conn: Conn, pattern: String): Bool;
}

/**
 * Phoenix.LiveView.Socket - The base Phoenix LiveView socket type
 * 
 * This is the fundamental socket type used by Phoenix LiveView for server-side
 * state management. It represents the raw Phoenix.LiveView.Socket struct in Elixir.
 * 
 * ## Purpose
 * - Holds the assigns (state) for a LiveView connection
 * - Matches Phoenix's expected function signatures (mount, handle_event, etc.)
 * - Provides the underlying storage for LiveView state
 * 
 * ## Relationship with LiveSocket
 * - **Socket<T>** is the base type - what Phoenix functions expect and return
 * - **LiveSocket<T>** is a type-safe wrapper that adds convenient methods
 * - You can freely convert between them:
 *   ```haxe
 *   var socket: Socket<MyAssigns> = ...; 
 *   var liveSocket: LiveSocket<MyAssigns> = socket;  // Add type-safe methods
 *   var backToSocket: Socket<MyAssigns> = liveSocket; // Return to base type
 *   ```
 * 
 * ## When to Use Socket vs LiveSocket
 * - **Use Socket<T>** in function signatures that Phoenix expects
 * - **Use LiveSocket<T>** when you need to manipulate assigns with type safety
 * 
 * ## Example
 * ```haxe
 * // Phoenix expects Socket in mount signature
 * static function mount(params: Dynamic, session: Dynamic, socket: Socket<MyAssigns>) {
 *     // Convert to LiveSocket for type-safe operations
 *     var liveSocket: LiveSocket<MyAssigns> = socket;
 *     
 *     // Use LiveSocket's type-safe methods
 *     return liveSocket.assign(_.userId, 123)
 *                      .assign(_.userName, "Alice");
 *     // Returns Socket<MyAssigns> automatically
 * }
 * ```
 * 
 * @param T The application-specific assigns structure type (e.g., TodoLiveAssigns)
 * @see LiveSocket For the type-safe wrapper with convenient methods
 * @see https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.Socket.html
 */
@:native("Phoenix.LiveView.Socket")
extern class Socket<T> {
    var assigns: T; // Type-safe assigns with application-specific structure
    var changed: Map<String, Bool>;
    var connected: Bool;
    var endpoint: String;
    var id: String;
    var parent_pid: ProcessId;
    var root_pid: ProcessId;
    var router: String;
    var transport_pid: ProcessId;
    var view: String;
    var fingerprints: Map<String, String>;
    var _private: Map<String, Any>;
}

/**
 * Phoenix.PubSub for type-safe real-time messaging
 * 
 * ARCHITECTURAL NOTE: These extern definitions map to the actual Phoenix.PubSub API.
 * Phoenix.PubSub.subscribe/3 signature: subscribe(pubsub, topic, opts \\ [])
 * Where pubsub is an atom (like TodoApp.PubSub), topic is a string, opts is a keyword list
 */
@:native("Phoenix.PubSub")
extern class PubSub {
    /**
     * Subscribe to a topic for real-time updates
     * 
     * Maps to: Phoenix.PubSub.subscribe(pubsub, topic, opts \\ [])
     * 
     * @param pubsub PubSub server name (atom like TodoApp.PubSub)
     * @param topic Topic string to subscribe to
     * @return :ok on success, {:error, reason} on failure
     */
    static function subscribe(pubsub: Dynamic, topic: String): Dynamic;
    
    /**
     * Subscribe to a topic with options
     * 
     * @param pubsub PubSub server name (atom like TodoApp.PubSub) 
     * @param topic Topic string to subscribe to
     * @param options Subscription options as keyword list
     * @return :ok on success, {:error, reason} on failure
     */
    static function subscribeWithOptions(pubsub: PubSubServer, topic: String, options: PubSubOptions): Result<Void, String>;
    
    /**
     * Broadcast a typed message to all subscribers  
     * @param pubsub PubSub server instance (typically AppName.PubSub)
     * @param topic Topic string to broadcast on
     * @param message Message payload to broadcast
     */
    static function broadcast<T>(pubsub: Dynamic, topic: String, message: T): Dynamic;
    
    /**
     * Broadcast with specific PubSub server
     */
    static function broadcastTo<T>(pubsub: PubSubServer, topic: String, message: T): Result<Void, String>;
    
    /**
     * Broadcast from a specific process (excludes sender)
     */
    static function broadcastFrom<T>(from: ProcessId, topic: String, message: T): Result<Void, String>;
    
    /**
     * Unsubscribe from a topic
     */
    static function unsubscribe(topic: String): Result<Void, String>;
    
    /**
     * Unsubscribe with specific PubSub server
     */
    static function unsubscribeFrom(pubsub: PubSubServer, topic: String): Result<Void, String>;
    
    /**
     * Get subscribers for a topic
     */
    static function subscribers(topic: String): Array<ProcessId>;
    
    /**
     * Local broadcast (single node only)
     */
    static function localBroadcast<T>(topic: String, message: T): Result<Void, String>;
    
    /**
     * Get subscription count for a topic
     */
    static function subscriptionCount(topic: String): Int;
}

// ============================================================================
// Additional Type Definitions for Phoenix Integration
// ============================================================================

/**
 * Plug.Conn structure for HTTP requests
 */
typedef Conn = {
    var method: HttpMethod;
    var path_info: Array<String>;
    var query_string: String;
    var req_headers: Array<Header>;
    var resp_headers: Array<Header>;
    var status: Null<HttpStatus>;
    var state: ConnState;
    var params: Map<String, String>;
    var assigns: Map<String, Any>;
    var body_params: Map<String, Any>;
    var query_params: Map<String, String>;
    var path_params: Map<String, String>;
    var cookies: Map<String, String>;
    var halted: Bool;
    var scheme: String;
    var host: String;
    var port: Int;
    var script_name: Array<String>;
    var request_path: String;
    var remote_ip: IpAddress;
}

/**
 * HTTP methods enum
 */
enum HttpMethod {
    GET;
    POST;
    PUT;
    PATCH;
    DELETE;
    HEAD;
    OPTIONS;
}

/**
 * HTTP status codes with semantic meaning
 */
enum HttpStatus {
    Ok; // 200
    Created; // 201
    NoContent; // 204
    MovedPermanently; // 301
    Found; // 302
    NotModified; // 304
    BadRequest; // 400
    Unauthorized; // 401
    Forbidden; // 403
    NotFound; // 404
    MethodNotAllowed; // 405
    UnprocessableEntity; // 422
    InternalServerError; // 500
    BadGateway; // 502
    ServiceUnavailable; // 503
    Custom(code: Int);
}

/**
 * Flash message types
 */
enum FlashType {
    Info;
    Success;
    Warning;
    Error;
    Custom(type: String);
}

/**
 * Connection state
 */
enum ConnState {
    Unset;
    Set;
    Sent;
    Chunked;
    FileChunked;
}

/**
 * Form input options
 */
typedef InputOptions = {
    var ?className: String;
    var ?id: String;
    var ?placeholder: String;
    var ?required: Bool;
    var ?disabled: Bool;
    var ?readonly: Bool;
    var ?maxlength: Int;
    var ?minlength: Int;
    var ?pattern: String;
    var ?autocomplete: String;
    var ?autofocus: Bool;
    var ?value: String;
    var ?name: String;
}

/**
 * Textarea-specific options
 */
typedef TextareaOptions = InputOptions & {
    var ?rows: Int;
    var ?cols: Int;
    var ?wrap: String;
}

/**
 * Checkbox options
 */
typedef CheckboxOptions = InputOptions & {
    var ?checked: Bool;
    var ?checked_value: String;
    var ?unchecked_value: String;
    var ?hidden_input: Bool;
}

/**
 * Select option definition
 */
typedef SelectOption = {
    var label: String;
    var value: String;
    var ?selected: Bool;
    var ?disabled: Bool;
}

/**
 * Label options
 */
typedef LabelOptions = {
    var ?className: String;
    var ?forAttr: String;
    var ?text: String;
}

/**
 * Submit button options
 */
typedef SubmitOptions = {
    var ?className: String;
    var ?id: String;
    var ?disabled: Bool;
    var ?form: String;
    var ?formaction: String;
    var ?formmethod: String;
}

/**
 * Link options
 */
typedef LinkOptions = {
    var to: String;
    var ?className: String;
    var ?id: String;
    var ?method: HttpMethod;
    var ?data: Map<String, String>;
    var ?confirm: String;
    var ?target: String;
}

/**
 * Route helper identifier
 */
enum RouteHelper {
    Named(name: String);
    Path(path: String);
}

/**
 * PubSub server reference
 */
typedef PubSubServer = String;

/**
 * PubSub subscription options
 */
typedef PubSubOptions = {
    var ?fastlane: Map<String, Any>;
    var ?link: Bool;
    var ?metadata: Map<String, Any>;
}

/**
 * Process ID (Erlang PID)
 */
typedef ProcessId = String;

/**
 * IP Address
 */
typedef IpAddress = String;

/**
 * HTTP Header
 */
typedef Header = {
    var name: String;
    var value: String;
}

/**
 * Safe HTML marker
 */
abstract SafeHTML(String) from String to String {}

/**
 * Form options for Phoenix HTML forms
 */
typedef FormOptions = {
    var ?method: String;
    var ?multipart: Bool;
    var ?csrf_token: String;
    var ?as: String;
}

/**
 * Phoenix HTML form structure
 */
typedef Form<T> = {
    var source: Changeset<T>;
    var impl: String;
    var id: String;
    var name: String;
    var data: T;
    var params: Map<String, String>; // Form parameters as string map
    var hidden: Array<FormField>;
    var options: FormOptions;
}

/**
 * Form field value types for type-safe form handling
 */
enum FormFieldValue {
    StringValue(s: String);
    IntValue(i: Int);
    FloatValue(f: Float);
    BoolValue(b: Bool);
    ArrayValue(values: Array<FormFieldValue>);
}

/**
 * Form field metadata for HEEx templates
 */
typedef FormField = {
    var id: String;
    var name: String;
    var value: FormFieldValue; // Type-safe form field values
    var errors: Array<String>;
    var valid: Bool;
    var data: FormFieldValue; // Type-safe field data
}

// ============================================================================
// LiveView Lifecycle Result Types
// ============================================================================

/**
 * LiveView mount return type with full type safety
 * 
 * @param TAssigns The application-specific socket assigns structure type
 * 
 * ## Generic Usage Pattern
 * 
 * Define your assigns structure:
 * ```haxe
 * typedef MyAssigns = {
 *     var user: User;
 *     var todos: Array<Todo>;
 *     var filter: String;
 * }
 * ```
 * 
 * Use in mount function:
 * ```haxe
 * public static function mount(params, session, socket: Socket<MyAssigns>): MountResult<MyAssigns> {
 *     return Ok(socket.assign({user: currentUser, todos: [], filter: "all"}));
 * }
 * ```
 * 
 * ## Type Safety Benefits
 * 
 * - **Compile-time validation**: Invalid assign access caught at compile time
 * - **IntelliSense support**: Full autocomplete for socket.assigns.fieldName
 * - **Refactoring safety**: Rename assigns fields with confidence
 * - **Framework compatibility**: Compiles to standard Phoenix LiveView patterns
 */
enum MountResult<TAssigns> {
    Ok(socket: Socket<TAssigns>);
    OkWithTemporaryAssigns(socket: Socket<TAssigns>, temporary_assigns: Array<String>);
    Error(reason: String);
}

/**
 * Event handling return type with full type safety
 * 
 * @param TAssigns The application-specific socket assigns structure type
 * 
 * ## Generic Usage Pattern
 * 
 * ```haxe
 * public static function handleEvent(event: String, params: EventParams, socket: Socket<MyAssigns>): HandleEventResult<MyAssigns> {
 *     return switch (event) {
 *         case "create_todo":
 *             var updated_socket = socket.assign({todos: newTodos});
 *             NoReply(updated_socket);
 *         case "invalid_event":
 *             Error("Unknown event", socket);
 *         case _: 
 *             NoReply(socket);
 *     };
 * }
 * ```
 * 
 * ## Return Types
 * 
 * - **NoReply(socket)**: Update socket and continue (most common)
 * - **Reply(message, socket)**: Send reply to client and update socket
 * - **Error(reason, socket)**: Handle error with context
 * 
 * ## Type Safety Benefits
 * 
 * - **Exhaustive pattern matching**: All event cases must be handled
 * - **Socket consistency**: Input and output socket types must match
 * - **Compile-time validation**: Invalid socket operations caught early
 */
enum HandleEventResult<TAssigns> {
    NoReply(socket: Socket<TAssigns>);
    Reply(reply: String, socket: Socket<TAssigns>); // Phoenix expects string replies
    Error(reason: String, socket: Socket<TAssigns>);
}

/**
 * Info message handling return type with full type safety  
 * 
 * @param TAssigns The application-specific socket assigns structure type
 * 
 * ## Generic Usage Pattern
 * 
 * ```haxe
 * public static function handleInfo(info: PubSubMessage, socket: Socket<MyAssigns>): HandleInfoResult<MyAssigns> {
 *     return switch (parseMessage(info)) {
 *         case Some(TodoCreated(todo)):
 *             var updated_todos = [todo].concat(socket.assigns.todos);
 *             var updated_socket = socket.assign({todos: updated_todos});
 *             NoReply(updated_socket);
 *         case Some(SystemAlert(message)):
 *             var updated_socket = socket.put_flash("info", message);
 *             NoReply(updated_socket);
 *         case None:
 *             // Unknown message - log and ignore
 *             NoReply(socket);
 *     };
 * }
 * ```
 * 
 * ## Return Types
 * 
 * - **NoReply(socket)**: Update socket and continue (most common)
 * - **Error(reason, socket)**: Handle error with context
 * 
 * ## Type Safety Benefits
 * 
 * - **Message type safety**: Combined with type-safe PubSub for end-to-end safety
 * - **Socket consistency**: Input and output socket types must match  
 * - **Real-time validation**: PubSub message parsing errors caught at compile time
 */
enum HandleInfoResult<TAssigns> {
    NoReply(socket: Socket<TAssigns>);
    Error(reason: String, socket: Socket<TAssigns>);
}

// ============================================================================
// Phoenix LiveView Lifecycle Parameter Types
// ============================================================================

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

/**
 * Session data structure for LiveView mount
 */
typedef Session = {
    var ?user_id: Int;
    var ?token: String;
    var ?csrf_token: String;
    var ?locale: String;
    var ?timezone: String;
    var ?user_agent: String;
    var ?ip_address: String;
    var ?login_at: String; // ISO timestamp string
}

/**
 * Event parameters from client interactions
 */
typedef EventParams = {
    // Todo CRUD fields
    var ?id: Int;
    var ?title: String;
    var ?description: String;
    var ?priority: String;
    var ?due_date: String;
    var ?tags: String;
    var ?completed: Bool;
    
    // UI interaction fields
    var ?filter: String;
    var ?sort_by: String;
    var ?query: String;
    var ?tag: String;
    var ?action: String;
    
    // Form validation metadata
    var ?_target: Array<String>;
    var ?_csrf_token: String;
    
    // Additional fields for extensibility
    var ?value: String; // String representation of values
    var ?key: String;
    var ?index: Int;
}

/**
 * PubSub message type for real-time communication
 */
typedef PubSubMessage = {
    var type: String;
    var ?data: String; // JSON string payload for type-safe parsing
    var ?metadata: Map<String, String>;
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
// Phoenix Presence for Real-Time User Tracking
// ============================================================================

/**
 * Phoenix.Presence for real-time user tracking and awareness
 * 
 * Provides type-safe abstractions over Phoenix Presence, eliminating the need
 * for __elixir__() calls in application code.
 */
@:native("Phoenix.Presence")
// Presence functionality has been moved to the dedicated phoenix/Presence.hx module
// Import phoenix.Presence for Phoenix.Presence functionality

// Any/Dynamic types eliminated in favor of proper type-safe alternatives
// Use generics, enums, or specific types instead of Any/Dynamic
