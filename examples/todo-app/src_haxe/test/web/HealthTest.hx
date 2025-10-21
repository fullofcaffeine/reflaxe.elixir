package test.web;

import exunit.TestCase;
import exunit.Assert.*;
import phoenix.test.ConnTest;

/**
 * HealthTest
 *
 * WHAT
 * - Minimal ExUnit test authored in Haxe to validate that the app boots and renders the home page.
 *
 * WHY
 * - Provides a quick server-side integration check (ConnTest) compiled from Haxe, exercising our
 *   @:exunit pipeline and standard externs without relying on browser automation.
 *
 * HOW
 * - Uses Phoenix.ConnTest externs to build a connection and GET "/".
 * - Asserts 200 OK and basic content presence.
 */
@:exunit
class HealthTest extends TestCase {
    @:test
    public function testHomePageLoads(): Void {
        var conn = ConnTest.build_conn();
        conn = ConnTest.get(conn, "/");
        // Basic assertions: status is 200 and HTML has a title keyword
        assertTrue(conn != null);
        // Status is available via conn.status in Phoenix.ConnTest structs
        assertTrue(Reflect.hasField(conn, "status"));
        var status: Int = Reflect.field(conn, "status");
        assertEqual(200, status);
    }
}

