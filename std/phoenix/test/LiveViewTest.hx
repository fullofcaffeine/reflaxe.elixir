package phoenix.test;

import phoenix.test.Conn;
import phoenix.test.LiveView;

/**
 * Phoenix.LiveViewTest extern definitions for LiveView testing.
 * 
 * Provides Haxe extern declarations for Phoenix.LiveViewTest functions,
 * enabling type-safe LiveView testing with proper LiveView types.
 * 
 * ## Usage
 * 
 * ```haxe
 * import phoenix.test.LiveView;
 * import phoenix.test.LiveViewTest;
 * 
 * @:test
 * function testLiveViewInteraction(): Void {
 *     var conn = ConnTest.build_conn();
 *     var liveView = LiveViewTest.live(conn, "/todos");
 *     liveView = LiveViewTest.render_click(liveView, "add-todo");
 *     Assert.contains(liveView.html(), "New todo");
 * }
 * ```
 * 
 * @see https://hexdocs.pm/phoenix_live_view/Phoenix.LiveViewTest.html
 */
@:native("Phoenix.LiveViewTest")
extern class LiveViewTest {
    /**
     * Mount a LiveView for testing.
     * Connects to the LiveView and returns a test harness.
     */
    @:overload(function(conn: Conn, path: String, params: Map<String, Dynamic>): LiveView {})
    @:overload(function(conn: Conn, path: String, session: Map<String, Dynamic>, params: Map<String, Dynamic>): LiveView {})
    public static function live(conn: Conn, path: String): LiveView;
    
    /**
     * Connect to an isolated LiveView component.
     */
    @:overload(function(module: String, assigns: Map<String, Dynamic>): LiveView {})
    public static function live_component(module: String): LiveView;
    
    /**
     * Render the current LiveView state.
     * Returns the HTML as a string.
     */
    public static function render(liveView: LiveView): String;
    
    /**
     * Simulate a click event on an element.
     */
    // Phoenix API: render_click(element_or_view, value \\ %{})
    @:overload(function(element: Dynamic, value: Dynamic): LiveView {})
    @:overload(function(element: Dynamic): LiveView {})
    @:overload(function(liveView: LiveView, element: String, value: Dynamic): LiveView {})
    public static function render_click(liveView: LiveView, element: String): LiveView;
    
    /**
     * Simulate form submission.
     */
    @:overload(function(element: Dynamic, data: Dynamic): LiveView {})
    @:overload(function(liveView: LiveView, form: String, data: Map<String, Dynamic>): LiveView {})
    public static function render_submit(liveView: LiveView, form: String): LiveView;
    
    /**
     * Simulate form change event (validation).
     */
    @:overload(function(liveView: LiveView, form: String, data: Map<String, Dynamic>): LiveView {})
    public static function render_change(liveView: LiveView, form: String): LiveView;
    
    /**
     * Simulate keydown event.
     */
    @:overload(function(liveView: LiveView, element: String, key: String, meta: Map<String, Dynamic>): LiveView {})
    public static function render_keydown(liveView: LiveView, element: String, key: String): LiveView;
    
    /**
     * Simulate keyup event.
     */
    @:overload(function(liveView: LiveView, element: String, key: String, meta: Map<String, Dynamic>): LiveView {})
    public static function render_keyup(liveView: LiveView, element: String, key: String): LiveView;
    
    /**
     * Simulate blur event (losing focus).
     */
    @:overload(function(liveView: LiveView, element: String, value: Dynamic): LiveView {})
    public static function render_blur(liveView: LiveView, element: String): LiveView;
    
    /**
     * Simulate focus event.
     */
    @:overload(function(liveView: LiveView, element: String, value: Dynamic): LiveView {})
    public static function render_focus(liveView: LiveView, element: String): LiveView;
    
    /**
     * Simulate hook event (JavaScript hooks).
     */
    @:overload(function(liveView: LiveView, hook: String, event: String, data: Map<String, Dynamic>): LiveView {})
    public static function render_hook(liveView: LiveView, hook: String, event: String): LiveView;
    
    /**
     * Send a message to the LiveView process.
     */
    public static function send_message(liveView: LiveView, message: Dynamic): LiveView;
    
    /**
     * Follow a redirect from the LiveView.
     */
    @:overload(function(liveView: LiveView, conn: Conn): LiveView {})
    @:overload(function(liveView: LiveView, conn: Conn, maxRedirects: Int): LiveView {})
    public static function follow_redirect(liveView: LiveView): LiveView;
    
    /**
     * Assert that a redirect occurred.
     */
    public static function assert_redirect(liveView: LiveView, to: String): Void;
    
    /**
     * Assert that a patch redirect occurred.
     */
    public static function assert_patch(liveView: LiveView, to: String): Void;
    
    /**
     * Assert LiveView was patched with assigns.
     */
    public static function assert_patched(liveView: LiveView, to: String): Void;
    
    /**
     * Assert flash message exists.
     */
    public static function assert_has_flash(liveView: LiveView, kind: String, message: String): Void;
    
    /**
     * Refute flash message exists.
     */
    public static function refute_has_flash(liveView: LiveView, kind: String): Void;
    
    /**
     * Get current LiveView assigns.
     */
    public static function get_assigns(liveView: LiveView): Map<String, Dynamic>;
    
    /**
     * Get specific assign value.
     */
    public static function get_assign(liveView: LiveView, key: String): Dynamic;
    
    /**
     * Check if LiveView has specific assign.
     */
    public static function has_assign(liveView: LiveView, key: String): Bool;
    
    /**
     * Get LiveView flash messages.
     */
    @:overload(function(liveView: LiveView, key: String): String {})
    public static function get_flash(liveView: LiveView): Map<String, String>;
    
    /**
     * Check if element exists in rendered HTML.
     */
    @:overload(function(liveView: LiveView, selector: String, text: String): Bool {})
    public static function has_element(liveView: LiveView, selector: String): Bool;
    
    /**
     * Find element in rendered HTML.
     */
    @:overload(function(liveView: LiveView, selector: String, text: String): Dynamic {})
    public static function element(liveView: LiveView, selector: String): Dynamic;
    
    /**
     * Find all elements matching selector.
     */
    public static function all(liveView: LiveView, selector: String): Array<Dynamic>;
    
    /**
     * Open browser view for debugging (in test mode).
     */
    public static function open_browser(liveView: LiveView): Void;
}
