package phoenix.test;

import phoenix.test.Conn;

/**
 * Phoenix LiveView testing harness.
 * 
 * Represents a LiveView test session for testing real-time UI interactions.
 * Provides type-safe access to LiveView state, events, and HTML rendering.
 * 
 * ## Usage
 * 
 * ```haxe
 * import phoenix.test.LiveView;
 * import phoenix.test.LiveViewTest;
 * 
 * @:test
 * function testLiveViewMount(conn: Conn): Void {
 *     var liveView: LiveView = LiveViewTest.live(conn, "/todos");
 *     Assert.contains(liveView.html(), "Todo List");
 * }
 * ```
 * 
 * @see https://hexdocs.pm/phoenix_live_view/Phoenix.LiveViewTest.html
 */
typedef LiveView = {
    /** Current HTML content of the LiveView */
    function html(): String;
    
    /** Current assigns (LiveView state) */
    var assigns: Map<String, Dynamic>;
    
    /** Flash messages */
    var flash: Map<String, String>;
    
    /** LiveView module name */
    var module: String;
    
    /** LiveView process ID */
    var pid: String;
    
    /** Current LiveView view state */
    var view: LiveViewState;
    
    /** Connection used for this LiveView */
    var conn: Conn;
    
    /** LiveView endpoint */
    var endpoint: String;
    
    /** Current route */
    var route: String;
    
    /** Socket assigns */
    var socket_assigns: Map<String, Dynamic>;
}

/**
 * LiveView state tracking.
 */
enum LiveViewState {
    /** LiveView is mounted and active */
    Mounted;
    
    /** LiveView is disconnected */
    Disconnected;
    
    /** LiveView encountered an error */
    Error(reason: String);
    
    /** LiveView is redirecting */
    Redirecting(to: String);
}

/**
 * LiveView event data structure.
 * Used for form submissions and custom events.
 */
typedef LiveViewEvent = {
    /** Event name (e.g., "save", "delete", "toggle") */
    var event: String;
    
    /** Event payload data */
    var value: Map<String, Dynamic>;
    
    /** Target element (if applicable) */
    @:optional var target: String;
    
    /** Event type (click, submit, keyup, etc.) */
    @:optional var type: String;
}

/**
 * Form data structure for LiveView form testing.
 */
typedef LiveViewForm = {
    /** Form field values */
    var fields: Map<String, Dynamic>;
    
    /** Form action (submit event name) */
    var action: String;
    
    /** Form target (phx-target) */
    @:optional var target: String;
    
    /** Form validation trigger */
    @:optional var trigger: String;
}

/**
 * LiveView hook data for JavaScript integration testing.
 */
typedef LiveViewHook = {
    /** Hook name */
    var name: String;
    
    /** Hook element selector */
    var selector: String;
    
    /** Hook data attributes */
    var data: Map<String, String>;
    
    /** Hook event handlers */
    var events: Array<String>;
}

/**
 * LiveView component testing structure.
 */
typedef LiveViewComponent = {
    /** Component module name */
    var module: String;
    
    /** Component ID */
    var id: String;
    
    /** Component assigns */
    var assigns: Map<String, Dynamic>;
    
    /** Whether component can handle events */
    var stateful: Bool;
}

/**
 * LiveView navigation helpers.
 */
class LiveViewNavigation {
    /** Navigate to a new route within the LiveView */
    public static inline var PUSH_NAVIGATE = "push_navigate";
    
    /** Patch the current route (preserves LiveView state) */
    public static inline var PUSH_PATCH = "push_patch";
    
    /** Replace current route in history */
    public static inline var PUSH_REPLACE = "push_replace";
    
    /** External redirect (leaves LiveView) */
    public static inline var REDIRECT = "redirect";
}

/**
 * Common LiveView events for testing.
 */
class LiveViewEvents {
    public static inline var MOUNT = "mount";
    public static inline var UPDATE = "update";
    public static inline var HANDLE_EVENT = "handle_event";
    public static inline var HANDLE_INFO = "handle_info";
    public static inline var HANDLE_PARAMS = "handle_params";
    public static inline var TERMINATE = "terminate";
}