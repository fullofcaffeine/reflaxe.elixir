package haxe.test.phoenix;

import haxe.test.phoenix.DataCase;
import phoenix.test.Conn;
import phoenix.test.ConnTest;
import phoenix.test.LiveView;
import phoenix.test.LiveViewTest;

/**
 * Base class for controller and LiveView integration tests.
 * 
 * Provides foundation for testing HTTP endpoints, LiveView interactions,
 * and web-layer functionality with proper connection handling.
 * 
 * ## Usage
 * 
 * ```haxe
 * import haxe.test.phoenix.ConnCase;
 * import phoenix.test.Conn;
 * 
 * @:exunit
 * class UserControllerTest extends ConnCase {
 *     @:test
 *     function testUserIndex(): Void {
 *         var conn = build_conn();
 *         conn = get(conn, "/users");
 *         assertResponse(conn, 200);
 *     }
 * }
 * ```
 */
@:exunit
class ConnCase extends DataCase {
    /**
     * Phoenix endpoint to use for testing.
     * Override this in your test class to specify your app's endpoint.
     */
    public static var endpoint(default, null): String = "MyAppWeb.Endpoint";
    
    /**
     * Setup method called before each test.
     * Creates a test connection and sets up the test environment.
     */
    override public function setup(context: TestContext): TestContext {
        // Setup Ecto sandbox for isolated test data
        super.setup(context);
        
        // Add connection to context
        var conn = build_conn();
        context.data = context.data ?? new Map<String, Dynamic>();
        context.data.set("conn", conn);
        
        return context;
    }
    
    // Connection building helpers
    
    /**
     * Build a test connection.
     * Uses Phoenix.ConnTest.build_conn/0.
     */
    public static function build_conn(): Conn {
        return ConnTest.build_conn();
    }
    
    /**
     * Build a connection with custom method and path.
     */
    public static function build_conn(method: String, path: String): Conn {
        return ConnTest.build_conn(method, path);
    }
    
    /**
     * Build a connection with method, path, and parameters.
     */
    public static function build_conn(method: String, path: String, params: Dynamic): Conn {
        return ConnTest.build_conn(method, path, params);
    }
    
    // HTTP request helpers
    
    /**
     * Make a GET request.
     */
    public static function get(conn: Conn, path: String): Conn {
        return ConnTest.get(conn, path);
    }
    
    /**
     * Make a GET request with parameters.
     */
    public static function getWithParams(conn: Conn, path: String, params: Dynamic): Conn {
        return ConnTest.get(conn, path, params);
    }
    
    /**
     * Make a POST request.
     */
    public static function post(conn: Conn, path: String): Conn {
        return ConnTest.post(conn, path);
    }
    
    /**
     * Make a POST request with parameters.
     */
    public static function postWithParams(conn: Conn, path: String, params: Dynamic): Conn {
        return ConnTest.post(conn, path, params);
    }
    
    /**
     * Make a PUT request.
     */
    public static function put(conn: Conn, path: String): Conn {
        return ConnTest.put(conn, path);
    }
    
    /**
     * Make a PUT request with parameters.
     */
    public static function putWithParams(conn: Conn, path: String, params: Dynamic): Conn {
        return ConnTest.put(conn, path, params);
    }
    
    /**
     * Make a PATCH request.
     */
    public static function patch(conn: Conn, path: String): Conn {
        return ConnTest.patch(conn, path);
    }
    
    /**
     * Make a PATCH request with parameters.
     */
    public static function patchWithParams(conn: Conn, path: String, params: Dynamic): Conn {
        return ConnTest.patch(conn, path, params);
    }
    
    /**
     * Make a DELETE request.
     */
    public static function delete(conn: Conn, path: String): Conn {
        return ConnTest.delete(conn, path);
    }
    
    /**
     * Make a DELETE request with parameters.
     */
    public static function deleteWithParams(conn: Conn, path: String, params: Dynamic): Conn {
        return ConnTest.delete(conn, path, params);
    }
    
    // LiveView helpers
    
    /**
     * Mount a LiveView for testing.
     */
    public static function live(conn: Conn, path: String): LiveView {
        return LiveViewTest.live(conn, path);
    }
    
    /**
     * Mount a LiveView with parameters.
     */
    public static function liveWithParams(conn: Conn, path: String, params: Dynamic): LiveView {
        return LiveViewTest.live(conn, path, params);
    }
    
    /**
     * Render current LiveView state.
     */
    public static function render(liveView: LiveView): String {
        return LiveViewTest.render(liveView);
    }
    
    /**
     * Simulate click event on LiveView element.
     */
    public static function clickElement(liveView: LiveView, selector: String): LiveView {
        return LiveViewTest.render_click(liveView, selector);
    }
    
    /**
     * Simulate click event with custom value.
     */
    public static function clickElementWithValue(liveView: LiveView, selector: String, value: Dynamic): LiveView {
        return LiveViewTest.render_click(liveView, selector, value);
    }
    
    /**
     * Submit form in LiveView.
     */
    public static function submitForm(liveView: LiveView, formSelector: String): LiveView {
        return LiveViewTest.render_submit(liveView, formSelector);
    }
    
    /**
     * Submit form with data in LiveView.
     */
    public static function submitFormWithData(liveView: LiveView, formSelector: String, data: Dynamic): LiveView {
        return LiveViewTest.render_submit(liveView, formSelector, data);
    }
    
    // Response assertion helpers
    
    /**
     * Assert response has specific status code.
     */
    public static function assertResponse(conn: Conn, expectedStatus: Int): Void {
        if (conn.status != expectedStatus) {
            throw 'Expected response status ${expectedStatus}, but got ${conn.status}';
        }
    }
    
    /**
     * Assert response is successful (2xx status).
     */
    public static function assertSuccessResponse(conn: Conn): Void {
        if (conn.status < 200 || conn.status >= 300) {
            throw 'Expected successful response (2xx), but got ${conn.status}';
        }
    }
    
    /**
     * Assert response contains specific text.
     */
    public static function assertResponseContains(conn: Conn, text: String): Void {
        if (conn.resp_body.indexOf(text) == -1) {
            throw 'Expected response to contain "${text}", but it did not. Response: ${conn.resp_body}';
        }
    }
    
    /**
     * Assert response does not contain specific text.
     */
    public static function assertResponseNotContains(conn: Conn, text: String): Void {
        if (conn.resp_body.indexOf(text) != -1) {
            throw 'Expected response to not contain "${text}", but it did. Response: ${conn.resp_body}';
        }
    }
    
    /**
     * Assert response redirects to specific path.
     */
    public static function assertRedirect(conn: Conn, expectedPath: String): Void {
        if (conn.status < 300 || conn.status >= 400) {
            throw 'Expected redirect status (3xx), but got ${conn.status}';
        }
        
        var location = getLocationHeader(conn);
        if (location != expectedPath) {
            throw 'Expected redirect to "${expectedPath}", but got "${location}"';
        }
    }
    
    /**
     * Assert LiveView contains specific text.
     */
    public static function assertLiveViewContains(liveView: LiveView, text: String): Void {
        var html = liveView.html();
        if (html.indexOf(text) == -1) {
            throw 'Expected LiveView to contain "${text}", but it did not. HTML: ${html}';
        }
    }
    
    /**
     * Assert LiveView has specific element.
     */
    public static function assertLiveViewHasElement(liveView: LiveView, selector: String): Void {
        if (!LiveViewTest.has_element(liveView, selector)) {
            throw 'Expected LiveView to have element "${selector}", but it did not. HTML: ${liveView.html()}';
        }
    }
    
    /**
     * Assert LiveView does not have specific element.
     */
    public static function assertLiveViewNotHasElement(liveView: LiveView, selector: String): Void {
        if (LiveViewTest.has_element(liveView, selector)) {
            throw 'Expected LiveView to not have element "${selector}", but it did. HTML: ${liveView.html()}';
        }
    }
    
    /**
     * Assert LiveView redirected to specific path.
     */
    public static function assertLiveViewRedirect(liveView: LiveView, expectedPath: String): Void {
        LiveViewTest.assert_redirect(liveView, expectedPath);
    }
    
    /**
     * Assert LiveView has flash message.
     */
    public static function assertFlash(liveView: LiveView, type: String, message: String): Void {
        LiveViewTest.assert_has_flash(liveView, type, message);
    }
    
    // Session and authentication helpers
    
    /**
     * Initialize test session with data.
     */
    public static function initSession(conn: Conn, sessionData: Dynamic): Conn {
        return ConnTest.init_test_session(conn, sessionData);
    }
    
    /**
     * Login user for testing (creates session).
     */
    public static function loginUser(conn: Conn, user: Dynamic): Conn {
        var sessionData = new Map<String, Dynamic>();
        sessionData.set("current_user_id", user.id);
        sessionData.set("current_user", user);
        return initSession(conn, sessionData);
    }
    
    /**
     * Clear session data.
     */
    public static function clearSession(conn: Conn): Conn {
        return ConnTest.clear_session(conn);
    }
    
    /**
     * Add flash message to connection.
     */
    public static function putFlash(conn: Conn, type: String, message: String): Conn {
        return ConnTest.put_flash(conn, type, message);
    }
    
    // Private helper methods
    
    /**
     * Extract Location header from redirect response.
     */
    private static function getLocationHeader(conn: Conn): String {
        for (header in conn.resp_headers) {
            if (header.name.toLowerCase() == "location") {
                return header.value;
            }
        }
        return "";
    }
}