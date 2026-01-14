package web;

import exunit.Assert.*;
import exunit.TestCase;
import phoenix.test.ConnTest;
import phoenix.test.Conn;
import StringTools;

/**
 * UsersApiTest
 *
 * WHAT
 * - Verifies the `/api/users` JSON endpoints are protected and tenant-scoped.
 *
 * WHY
 * - These routes are a showcase for cookie/session-backed auth + organization scoping.
 * - They must not leak users across orgs and must reject non-admins.
 *
 * HOW
 * - Uses the existing `/auth/login` demo controller to create users and set Plug session.
 * - Calls the JSON API with `accept: application/json`.
 */
@:exunit
class UsersApiTest extends TestCase {
    static function acceptJson(conn: Conn): Conn {
        return ConnTest.put_req_header(conn, "accept", "application/json");
    }

    @:test
    public function testApiUsersRequiresAuth(): Void {
        var conn = ConnTest.build_conn();
        conn = acceptJson(conn);
        conn = ConnTest.get(conn, "/api/users");
        assertEqual(401, conn.status);
    }

    @:test
    public function testApiUsersRejectsNonAdmin(): Void {
        var domain = "api_users_forbidden.test";

        // First user in org becomes admin.
        var adminConn = ConnTest.build_conn();
        adminConn = ConnTest.post(adminConn, "/auth/login", {name: "Admin", email: 'admin@${domain}'});

        // Second user in same org is a regular user.
        var userConn = ConnTest.build_conn();
        userConn = ConnTest.post(userConn, "/auth/login", {name: "User", email: 'user@${domain}'});
        userConn = ConnTest.recycle(userConn);

        userConn = acceptJson(userConn);
        userConn = ConnTest.get(userConn, "/api/users");
        assertEqual(403, userConn.status);

        // Keep adminConn "used" so generated Elixir compiles under --warnings-as-errors.
        assertTrue(adminConn.status > 0);
    }

    @:test
    public function testApiUsersIsOrganizationScoped(): Void {
        var org1Domain = "api_users_org1.test";
        var org2Domain = "api_users_org2.test";

        var org1AdminEmail = 'admin@${org1Domain}';
        var org2UserEmail = 'user@${org2Domain}';

        var org1Conn = ConnTest.build_conn();
        org1Conn = ConnTest.post(org1Conn, "/auth/login", {name: "Org1 Admin", email: org1AdminEmail});
        org1Conn = ConnTest.recycle(org1Conn);

        var org2Conn = ConnTest.build_conn();
        org2Conn = ConnTest.post(org2Conn, "/auth/login", {name: "Org2 User", email: org2UserEmail});

        org1Conn = acceptJson(org1Conn);
        org1Conn = ConnTest.get(org1Conn, "/api/users");
        assertEqual(200, org1Conn.status);

        assertTrue(StringTools.contains(org1Conn.resp_body, org1AdminEmail));
        assertTrue(!StringTools.contains(org1Conn.resp_body, org2UserEmail));
    }

    @:test
    public function testApiUsersCreateDoesNotLeakPasswordHash(): Void {
        var domain = "api_users_create.test";
        var adminEmail = 'admin@${domain}';
        var createdEmail = 'created@${domain}';

        var conn = ConnTest.build_conn();
        conn = ConnTest.post(conn, "/auth/login", {name: "Admin", email: adminEmail});
        conn = ConnTest.recycle(conn);

        conn = acceptJson(conn);
        conn = ConnTest.post(conn, "/api/users", {name: "Created", email: createdEmail});
        assertEqual(201, conn.status);

        assertTrue(StringTools.contains(conn.resp_body, createdEmail));
        assertTrue(!StringTools.contains(conn.resp_body, "password"));
        assertTrue(!StringTools.contains(conn.resp_body, "password_hash"));
    }
}

