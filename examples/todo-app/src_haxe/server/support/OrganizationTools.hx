package server.support;

import server.infrastructure.Repo;
import server.schemas.Organization;

typedef OrganizationInfo = {
    var id: Int;
    var slug: String;
    var name: String;
    var is_demo: Bool;
}

/**
 * OrganizationTools
 *
 * WHAT
 * - Helpers for displaying tenant/organization info in LiveView templates.
 *
 * WHY
 * - The todo-app uses `organization_id` for multi-tenant scoping (queries, PubSub topics, Presence),
 *   but the UI should also make the active tenant explicit for demo clarity.
 *
 * HOW
 * - `organization_id == 0` is reserved for anonymous/demo mode.
 * - For real tenants (id > 0), we fetch the `Organization` schema by id and expose {slug, name}.
 */
class OrganizationTools {
    public static inline var DEMO_ORG_ID: Int = 0;
    public static inline var DEMO_ORG_SLUG: String = "demo";
    public static inline var DEMO_ORG_NAME: String = "Demo";

    public static function infoForId(organizationId: Int): OrganizationInfo {
        if (organizationId == DEMO_ORG_ID) {
            return {
                id: DEMO_ORG_ID,
                slug: DEMO_ORG_SLUG,
                name: DEMO_ORG_NAME,
                is_demo: true
            };
        }

        var org = Repo.get(Organization, organizationId);
        if (org == null) {
            return {
                id: organizationId,
                slug: "unknown",
                name: "Unknown",
                is_demo: false
            };
        }

        return {
            id: org.id,
            slug: org.slug,
            name: org.name,
            is_demo: false
        };
    }
}

