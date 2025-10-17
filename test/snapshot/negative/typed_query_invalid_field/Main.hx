package;

import ecto.TypedQuery;

class Main {
    public static function main() {
        // Use typed query API to enable compile-time field validation
        var query = TypedQuery.from(User);
        var value = 123;
        // Intentionally invalid field: noSuchField does not exist on User
        // This must fail at macro time via SchemaIntrospection.hasField()
        var q2 = query.where(u -> u.noSuchField == value);
        untyped __elixir__('{0}', q2);
    }
}
