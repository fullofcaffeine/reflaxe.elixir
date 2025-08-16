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
    public static function live(conn: Conn, path: String): LiveView;
    
    /**
     * Mount a LiveView with parameters.
     */
    public static function live(conn: Conn, path: String, params: Map<String, Dynamic>): LiveView;
    
    /**
     * Mount a LiveView with session and parameters.
     */
    public static function live(conn: Conn, path: String, session: Map<String, Dynamic>, params: Map<String, Dynamic>): LiveView;
    
    /**
     * Connect to an isolated LiveView component.
     */
    public static function live_component(module: String): LiveView;
    
    /**
     * Connect to a LiveView component with assigns.
     */
    public static function live_component(module: String, assigns: Map<String, Dynamic>): LiveView;
    
    /**
     * Render the current LiveView state.
     * Returns the HTML as a string.
     */
    public static function render(liveView: LiveView): String;
    
    /**
     * Simulate a click event on an element.
     */
    public static function render_click(liveView: LiveView, element: String): LiveView;
    
    /**
     * Simulate a click with custom value.
     */
    public static function render_click(liveView: LiveView, element: String, value: Dynamic): LiveView;
    
    /**
     * Simulate form submission.
     */
    public static function render_submit(liveView: LiveView, form: String): LiveView;
    
    /**
     * Simulate form submission with data.
     */
    public static function render_submit(liveView: LiveView, form: String, data: Map<String, Dynamic>): LiveView;
    
    /**
     * Simulate form change event (validation).
     */
    public static function render_change(liveView: LiveView, form: String): LiveView;
    
    /**
     * Simulate form change with data.
     */
    public static function render_change(liveView: LiveView, form: String, data: Map<String, Dynamic>): LiveView;
    
    /**
     * Simulate keydown event.
     */
    public static function render_keydown(liveView: LiveView, element: String, key: String): LiveView;
    
    /**
     * Simulate keydown with metadata.
     */
    public static function render_keydown(liveView: LiveView, element: String, key: String, meta: Map<String, Dynamic>): LiveView;
    
    /**
     * Simulate keyup event.
     */
    public static function render_keyup(liveView: LiveView, element: String, key: String): LiveView;
    
    /**
     * Simulate keyup with metadata.
     */
    public static function render_keyup(liveView: LiveView, element: String, key: String, meta: Map<String, Dynamic>): LiveView;
    
    /**
     * Simulate blur event (losing focus).
     */
    public static function render_blur(liveView: LiveView, element: String): LiveView;
    
    /**
     * Simulate blur with value.
     */
    public static function render_blur(liveView: LiveView, element: String, value: Dynamic): LiveView;
    
    /**
     * Simulate focus event.
     */
    public static function render_focus(liveView: LiveView, element: String): LiveView;
    
    /**
     * Simulate focus with value.
     */
    public static function render_focus(liveView: LiveView, element: String, value: Dynamic): LiveView;
    
    /**
     * Simulate hook event (JavaScript hooks).
     */
    public static function render_hook(liveView: LiveView, hook: String, event: String): LiveView;
    
    /**
     * Simulate hook event with data.
     */
    public static function render_hook(liveView: LiveView, hook: String, event: String, data: Map<String, Dynamic>): LiveView;
    
    /**
     * Send a message to the LiveView process.
     */
    public static function send_message(liveView: LiveView, message: Dynamic): LiveView;
    
    /**
     * Follow a redirect from the LiveView.
     */
    public static function follow_redirect(liveView: LiveView): LiveView;
    
    /**
     * Follow redirect to specific connection.
     */
    public static function follow_redirect(liveView: LiveView, conn: Conn): LiveView;
    
    /**
     * Follow redirect with max redirects.
     */
    public static function follow_redirect(liveView: LiveView, conn: Conn, maxRedirects: Int): LiveView;
    
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
    public static function get_flash(liveView: LiveView): Map<String, String>;
    
    /**
     * Get specific flash message.
     */
    public static function get_flash(liveView: LiveView, key: String): String;
    
    /**
     * Check if element exists in rendered HTML.
     */
    public static function has_element(liveView: LiveView, selector: String): Bool;
    
    /**
     * Check if element exists with specific text.
     */
    public static function has_element(liveView: LiveView, selector: String, text: String): Bool;
    
    /**
     * Find element in rendered HTML.
     */
    public static function element(liveView: LiveView, selector: String): Dynamic;
    
    /**
     * Find element with specific text.
     */
    public static function element(liveView: LiveView, selector: String, text: String): Dynamic;
    
    /**
     * Find all elements matching selector.
     */
    public static function all(liveView: LiveView, selector: String): Array<Dynamic>;
    
    /**
     * Open browser view for debugging (in test mode).
     */
    public static function open_browser(liveView: LiveView): Void;
}