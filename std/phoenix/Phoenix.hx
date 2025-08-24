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
    static function put_status(conn: Conn, status: HttpStatus): Conn;
    
    /**
     * Put response header with validation
     */
    static function put_resp_header(conn: Conn, key: String, value: String): Conn;
    
    /**
     * Put flash message with type-safe message types
     */
    static function put_flash(conn: Conn, type: FlashType, message: String): Conn;
    
    /**
     * Get flash message with optional type filter
     */
    static function get_flash(conn: Conn, ?type: FlashType): Option<String>;
    
    /**
     * Assign values to the connection for templates
     */
    static function assign<T>(conn: Conn, key: String, value: T): Conn;
    
    /**
     * Assign multiple values at once
     */
    static function assign_multiple<T>(conn: Conn, assigns: T): Conn;
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
extern class LiveView<T> {
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
    static function handle_event<TAssigns>(event: String, params: EventParams, socket: Socket<TAssigns>): HandleEventResult<TAssigns>;
    
    /**
     * Handle info messages from processes
     * 
     * @param TAssigns The type of socket assigns structure for this info operation
     */
    static function handle_info<TAssigns>(info: PubSubMessage, socket: Socket<TAssigns>): HandleInfoResult<TAssigns>;
    
    /**
     * Render the LiveView template with typed assigns
     */
    static function render<T>(assigns: T): String;
    
    /**
     * Assign single value to the socket
     * 
     * @param TAssigns The type of socket assigns structure
     */
    static function assign<TAssigns>(socket: Socket<TAssigns>, key: String, value: TAssigns): Socket<TAssigns>;
    
    /**
     * Assign multiple values to the socket using a map of assigns
     * 
     * NOTE: This maps to Phoenix.LiveView.assign/2 with a map in Elixir
     * 
     * @param TAssigns The type of socket assigns structure
     */
    @:native("assign")
    static function assign_multiple<TAssigns>(socket: Socket<TAssigns>, assigns: TAssigns): Socket<TAssigns>;
    
    /**
     * Assign new values only if not already present
     * 
     * @param TAssigns The type of socket assigns structure
     * @param TValue The type of the value being assigned
     */
    static function assign_new<TAssigns, TValue>(socket: Socket<TAssigns>, key: String, func: () -> TValue): Socket<TAssigns>;
    
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
    static function push_patch<TAssigns>(socket: Socket<TAssigns>, options: PatchOptions): Socket<TAssigns>;
    
    /**
     * Push a redirect to the client
     * 
     * @param TAssigns The type of socket assigns structure
     */
    static function push_redirect<TAssigns>(socket: Socket<TAssigns>, options: RedirectOptions): Socket<TAssigns>;
    
    /**
     * Push an event to the client-side hooks
     * 
     * @param TAssigns The type of socket assigns structure
     * @param TPayload The type of the event payload
     */
    static function push_event<TAssigns, TPayload>(socket: Socket<TAssigns>, event: String, payload: TPayload): Socket<TAssigns>;
    
    /**
     * Put flash message for LiveView
     * 
     * @param TAssigns The type of socket assigns structure
     */
    static function put_flash<TAssigns>(socket: Socket<TAssigns>, type: FlashType, message: String): Socket<TAssigns>;
    
    /**
     * Put temporary flash (cleared after next render)
     * 
     * @param TAssigns The type of socket assigns structure
     */
    static function put_temp_flash<TAssigns>(socket: Socket<TAssigns>, type: FlashType, message: String): Socket<TAssigns>;
    
    /**
     * Clear flash messages
     * 
     * @param TAssigns The type of socket assigns structure
     */
    static function clear_flash<TAssigns>(socket: Socket<TAssigns>, ?type: FlashType): Socket<TAssigns>;
    
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
    static function get_assign<TAssigns, TValue>(socket: Socket<TAssigns>, key: String): Option<TValue>;
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
    static function form_for<T>(changeset: Changeset<T>, action: String, options: FormOptions, content: Form<T> -> String): String;
    
    /**
     * Generate form inputs with proper typing
     */
    static function text_input<T>(form: Form<T>, field: String, options: InputOptions): String;
    static function email_input<T>(form: Form<T>, field: String, options: InputOptions): String;
    static function password_input<T>(form: Form<T>, field: String, options: InputOptions): String;
    static function textarea<T>(form: Form<T>, field: String, options: TextareaOptions): String;
    static function select<T>(form: Form<T>, field: String, options: Array<SelectOption>, inputOptions: InputOptions): String;
    static function checkbox<T>(form: Form<T>, field: String, options: CheckboxOptions): String;
    static function hidden_input<T>(form: Form<T>, field: String, options: InputOptions): String;
    
    /**
     * Form labels and validation display
     */
    static function label<T>(form: Form<T>, field: String, options: LabelOptions): String;
    static function error_tag<T>(form: Form<T>, field: String): String;
    
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
    static function html_escape(text: String): String;
    
    /**
     * Generate CSRF token
     */
    static function csrf_meta_tag(): String;
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
    static function current_path(conn: Conn): String;
    
    /**
     * Get current URL from connection
     */
    static function current_url(conn: Conn): String;
    
    /**
     * Get current route from connection
     */
    static function current_route(conn: Conn): Option<String>;
    
    /**
     * Check if current route matches pattern
     */
    static function route_matches(conn: Conn, pattern: String): Bool;
}

/**
 * Phoenix.LiveView.Socket with complete type safety
 * 
 * @param T The application-specific assigns structure type
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
 */
@:native("Phoenix.PubSub")
extern class PubSub {
    /**
     * Subscribe to a topic for real-time updates
     */
    static function subscribe(topic: String, options: PubSubOptions): Result<Void, String>;
    
    /**
     * Subscribe with specific PubSub server name
     */
    static function subscribe_to(pubsub: PubSubServer, topic: String, options: PubSubOptions): Result<Void, String>;
    
    /**
     * Broadcast a typed message to all subscribers
     */
    static function broadcast<T>(topic: String, message: T): Result<Void, String>;
    
    /**
     * Broadcast with specific PubSub server
     */
    static function broadcast_to<T>(pubsub: PubSubServer, topic: String, message: T): Result<Void, String>;
    
    /**
     * Broadcast from a specific process (excludes sender)
     */
    static function broadcast_from<T>(from: ProcessId, topic: String, message: T): Result<Void, String>;
    
    /**
     * Unsubscribe from a topic
     */
    static function unsubscribe(topic: String): Result<Void, String>;
    
    /**
     * Unsubscribe with specific PubSub server
     */
    static function unsubscribe_from(pubsub: PubSubServer, topic: String): Result<Void, String>;
    
    /**
     * Get subscribers for a topic
     */
    static function subscribers(topic: String): Array<ProcessId>;
    
    /**
     * Local broadcast (single node only)
     */
    static function local_broadcast<T>(topic: String, message: T): Result<Void, String>;
    
    /**
     * Get subscription count for a topic
     */
    static function subscription_count(topic: String): Int;
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
 * public static function handle_event(event: String, params: EventParams, socket: Socket<MyAssigns>): HandleEventResult<MyAssigns> {
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
 * public static function handle_info(info: PubSubMessage, socket: Socket<MyAssigns>): HandleInfoResult<MyAssigns> {
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

// Any/Dynamic types eliminated in favor of proper type-safe alternatives
// Use generics, enums, or specific types instead of Any/Dynamic