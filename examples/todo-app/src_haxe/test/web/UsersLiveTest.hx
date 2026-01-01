package web;

import exunit.TestCase;
import exunit.Assert.*;
import phoenix.test.ConnTest;
import phoenix.test.LiveViewTest;
import phoenix.test.LiveView;
import elixir.types.Term;

/**
 * UsersLiveTest
 *
 * WHAT
 * - Smoke-test the Users directory LiveView.
 *
 * WHY
 * - Ensures the todo-app demo routes continue to mount after schema/context changes.
 *
 * HOW
 * - Uses Phoenix.LiveViewTest to mount `/users` and asserts basic render output.
 */
@:exunit
class UsersLiveTest extends TestCase {
    @:test
    public function testUsersPageMounts(): Void {
        var conn = ConnTest.build_conn();
        conn = ConnTest.post(conn, "/auth/login", {name: "Users Test", email: "users_live_test@example.com"});
        var lvTuple: Term = LiveViewTest.live(conn, "/users");
        var lv: LiveView = LiveViewTest.view(lvTuple);
        var html: String = LiveViewTest.render(lv);
        assertTrue(html.indexOf("Users") != -1);
    }
}
