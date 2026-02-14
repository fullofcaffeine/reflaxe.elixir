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
// @:exunit: marks this class as an ExUnit test module.
@:exunit
class AuthFlowTest extends TestCase {
	// @:test: marks this function as an executable ExUnit test case.
	@:test
	public function testLoginSetsSessionUserId():Void {
		var conn = ConnTest.build_conn();
		conn = ConnTest.post(conn, "/auth/login", {name: "Alice Example", email: "alice@example.com"});

		assertEqual(302, conn.status);

		// Verify Plug session key was set during the controller action.
		var plugConn:plug.Conn<{}> = cast conn;
		var userId = plugConn.getSession("user_id");
		assertTrue(userId != null);
	}

	@:test
	public function testLoginWithSameEmailKeepsSameUserId():Void {
		var runId = Std.string(Std.random(1000000000));
		var email = 'same-email-${runId}@example.com';

		var connA = ConnTest.build_conn();
		connA = ConnTest.post(connA, "/auth/login", {name: "Original Name", email: email});
		assertEqual(302, connA.status);

		var plugConnA:plug.Conn<{}> = cast connA;
		var userIdA = plugConnA.getSession("user_id");
		assertTrue(userIdA != null);

		var connB = ConnTest.build_conn();
		connB = ConnTest.post(connB, "/auth/login", {name: "Different Name", email: email});
		assertEqual(302, connB.status);

		var plugConnB:plug.Conn<{}> = cast connB;
		var userIdB = plugConnB.getSession("user_id");
		assertTrue(userIdB != null);
		assertEqual(userIdA, userIdB);
	}
}
