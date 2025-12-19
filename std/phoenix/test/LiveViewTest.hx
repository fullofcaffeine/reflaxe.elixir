package phoenix.test;

import phoenix.test.Conn;
import phoenix.test.LiveView;
import elixir.types.Term;

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
 *     var result = LiveViewTest.live(conn, "/todos");
 *     var liveView = LiveViewTest.view(result);
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
    @:overload(function(conn: Conn, path: String, params: Map<String, Term>): Term {})
    @:overload(function(conn: Conn, path: String, session: Map<String, Term>, params: Map<String, Term>): Term {})
    public static function live(conn: Conn, path: String): Term;
    
    /**
     * Connect to an isolated LiveView component.
     */
    @:overload(function(module: String, assigns: Map<String, Term>): Term {})
    public static function live_component(module: String): Term;

    /**
     * Extract the LiveView handle from a successful `live/2` or `live_component/2` result.
     *
     * Phoenix returns `{:ok, view, html}`. Keeping the raw return as `Term` avoids inventing
     * tuple shapes in app/test code while still eliminating `Dynamic` from APIs.
     */
    public static inline function view(result: Term): LiveView {
        return cast elixir.Tuple.elem(result, 1);
    }

    /**
     * Extract the initial rendered HTML from a successful `live/2` result tuple.
     */
    public static inline function initial_html(result: Term): String {
        return cast elixir.Tuple.elem(result, 2);
    }
    
    /**
     * Render the current LiveView state.
     * Returns the HTML as a string.
     */
    public static function render(liveView: LiveView): String;
    
    /**
     * Simulate a click event on an element.
     */
    // Phoenix API: render_click(element_or_view, value \\ %{})
    @:overload(function(element: Term, value: Term): LiveView {})
    @:overload(function(element: Term): LiveView {})
    @:overload(function(liveView: LiveView, element: String, value: Term): LiveView {})
    public static function render_click(liveView: LiveView, element: String): LiveView;
    
    /**
     * Simulate form submission.
     */
    @:overload(function(element: Term, data: Term): LiveView {})
    @:overload(function(liveView: LiveView, form: String, data: Term): LiveView {})
    @:overload(function(liveView: LiveView, form: String, data: Map<String, Term>): LiveView {})
    public static function render_submit(liveView: LiveView, form: String): LiveView;
    
    /**
     * Simulate form change event (validation).
     */
    @:overload(function(liveView: LiveView, form: String, data: Term): LiveView {})
    @:overload(function(liveView: LiveView, form: String, data: Map<String, Term>): LiveView {})
    public static function render_change(liveView: LiveView, form: String): LiveView;
    
    /**
     * Simulate keydown event.
     */
    @:overload(function(liveView: LiveView, element: String, key: String, meta: Map<String, Term>): LiveView {})
    public static function render_keydown(liveView: LiveView, element: String, key: String): LiveView;
    
    /**
     * Simulate keyup event.
     */
    @:overload(function(liveView: LiveView, element: String, key: String, meta: Map<String, Term>): LiveView {})
    public static function render_keyup(liveView: LiveView, element: String, key: String): LiveView;
    
    /**
     * Simulate blur event (losing focus).
     */
    @:overload(function(liveView: LiveView, element: String, value: Term): LiveView {})
    public static function render_blur(liveView: LiveView, element: String): LiveView;
    
    /**
     * Simulate focus event.
     */
    @:overload(function(liveView: LiveView, element: String, value: Term): LiveView {})
    public static function render_focus(liveView: LiveView, element: String): LiveView;
    
    /**
     * Simulate hook event (JavaScript hooks).
     */
    @:overload(function(liveView: LiveView, hook: String, event: String, data: Map<String, Term>): LiveView {})
    public static function render_hook(liveView: LiveView, hook: String, event: String): LiveView;
    
    /**
     * Send a message to the LiveView process.
     */
    public static function send_message(liveView: LiveView, message: Term): LiveView;
    
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
    public static function get_assigns(liveView: LiveView): Map<String, Term>;
    
    /**
     * Get specific assign value.
     */
    public static function get_assign(liveView: LiveView, key: String): Term;
    
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
    @:overload(function(liveView: LiveView, selector: String, text: String): Term {})
    public static function element(liveView: LiveView, selector: String): Term;
    
    /**
     * Find all elements matching selector.
     */
    public static function all(liveView: LiveView, selector: String): Array<Term>;
    
    /**
     * Open browser view for debugging (in test mode).
     */
    public static function open_browser(liveView: LiveView): Void;
}
