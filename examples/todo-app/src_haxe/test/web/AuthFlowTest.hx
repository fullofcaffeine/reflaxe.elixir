package web;

import exunit.Assert.*;
import exunit.TestCase;
import phoenix.test.ConnTest;

/**
 * AuthFlowTest
 *
 * WHAT
 * - Smoke-test the optional login controller flow.
 *
 * WHY
 * - Ensures SessionController correctly persists `:user_id` in the Plug session,
 *   which is required for LiveView session propagation via TodoAppWeb.live_session/1.
 *
 * HOW
 * - POSTs to `/auth/login` and asserts a redirect plus presence of `:user_id` in session.
 */
@:exunit
class AuthFlowTest extends TestCase {
    @:test
    public function testLoginSetsSessionUserId(): Void {
        var conn = ConnTest.build_conn();
        conn = ConnTest.post(conn, "/auth/login", {name: "Alice Example", email: "alice@example.com"});

        assertEqual(302, conn.status);

        // Verify Plug session key was set during the controller action.
        var plugConn: plug.Conn<{}> = cast conn;
        var userId = plugConn.getSession("user_id");
        assertTrue(userId != null);
    }
}

