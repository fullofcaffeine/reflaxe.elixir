package web;

import exunit.Assert.*;
import exunit.TestCase;
import phoenix.test.ConnTest;
import phoenix.test.LiveViewTest;
import phoenix.test.LiveView;
import elixir.types.Term;

/**
 * TenancyTest
 *
 * WHAT
 * - Ensures todo visibility is scoped to the signed-in user's organization.
 *
 * WHY
 * - Demonstrates multi-tenant safety: users in different orgs must not see each other's todos,
 *   even when both are connected to the same LiveView route.
 *
 * HOW
 * - Create a todo as a user in org A, then mount /todos as a user in org B and assert the title
 *   does not render.
 */
@:exunit
class TenancyTest extends TestCase {
    @:test
    public function testTodosAreScopedToOrganization(): Void {
        var runId = Std.string(Std.int(Date.now().getTime()));
        var orgA = 'org-a-${runId}.example.com';
        var orgB = 'org-b-${runId}.example.com';
        var title = 'Tenancy ${runId}';

        var connA = ConnTest.build_conn();
        connA = ConnTest.post(connA, "/auth/login", {name: "Org A User", email: 'a@${orgA}'});

        var lvTupleA: Term = LiveViewTest.live(connA, "/todos");
        var lvA: LiveView = LiveViewTest.view(lvTupleA);
        LiveViewTest.render_click(LiveViewTest.element(lvA, "button[phx-click='toggle_form']"));
        LiveViewTest.render_submit(LiveViewTest.element(lvA, "form[phx-submit='create_todo']"), {title: title});
        var htmlA = LiveViewTest.render(lvA);
        assertTrue(htmlA.indexOf(title) != -1);

        var connB = ConnTest.build_conn();
        connB = ConnTest.post(connB, "/auth/login", {name: "Org B User", email: 'b@${orgB}'});

        var lvTupleB: Term = LiveViewTest.live(connB, "/todos");
        var lvB: LiveView = LiveViewTest.view(lvTupleB);
        var htmlB = LiveViewTest.render(lvB);
        assertTrue(htmlB.indexOf(title) == -1);
    }
}

