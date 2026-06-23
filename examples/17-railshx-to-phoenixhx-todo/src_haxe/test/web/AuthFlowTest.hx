package web;

import exunit.Assert.*;
import exunit.TestCase;
import phoenix.test.ConnTest;

@:exunit
class AuthFlowTest extends TestCase {
	@:test
	public function testDemoLoginSetsSessionUserId():Void {
		var conn = ConnTest.build_conn();
		conn = ConnTest.post(conn, "/auth/demo", {name: "Guest Workspace", email: "guest@example.test"});

		assertEqual(302, conn.status);

		var plugConn:plug.Conn<{}> = cast conn;
		var userId = plugConn.getSession("user_id");
		assertTrue(userId != null);
	}
}
