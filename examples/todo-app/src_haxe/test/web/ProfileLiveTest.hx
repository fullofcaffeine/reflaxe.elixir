package web;

import exunit.TestCase;
import exunit.Assert.*;
import phoenix.test.ConnTest;
import phoenix.test.LiveViewTest;
import phoenix.test.LiveView;
import elixir.types.Term;
import server.infrastructure.Repo;

/**
 * ProfileLiveTest
 *
 * WHAT
 * - Verifies the Profile LiveView can update a user's name + bio.
 *
 * WHY
 * - Guards the Ecto changeset + Repo.update path and ensures profile fields are persisted.
 *
 * HOW
 * - Creates a user via the demo login controller, mounts `/profile`, submits the form, then
 *   loads the user from the DB to assert updates were applied.
 */
@:exunit
class ProfileLiveTest extends TestCase {
    @:test
    public function testProfileUpdatePersistsBio(): Void {
        var conn = ConnTest.build_conn();
        conn = ConnTest.post(conn, "/auth/login", {name: "Alice Example", email: "alice_profile@example.com"});
        assertEqual(302, conn.status);

        var plugConn: plug.Conn<{}> = cast conn;
        var userIdTerm: Term = plugConn.getSession("user_id");
        assertTrue(userIdTerm != null);
        var userId: Int = cast userIdTerm;

        var lvTuple: Term = LiveViewTest.live(conn, "/profile");
        var lv: LiveView = LiveViewTest.view(lvTuple);

        var formEl: Term = LiveViewTest.element(lv, "form[phx-submit='save_profile']");
        LiveViewTest.render_submit(formEl, {name: "Alice Updated", bio: "Hello from Haxe"});

        var html: String = LiveViewTest.render(lv);
        assertTrue(html.indexOf("Profile updated.") != -1);
        assertTrue(html.indexOf("Alice Updated") != -1);

        var user = Repo.get(server.schemas.User, userId);
        assertTrue(user != null);
        assertEqual("Hello from Haxe", user.bio);
    }
}

