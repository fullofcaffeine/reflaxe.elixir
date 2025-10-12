@:presence
@:native("AppWeb.Presence")
class PresenceTestModule {
    public static function exercise() {
        var presences: Dynamic = untyped __elixir__('Phoenix.Presence.list("users")');
        // Using Reflect.fields would expand to Enum.map(Map.keys(..), &Atom.to_string/1)
        // Presence transform should collapse this to Map.keys(..)
        for (k in Reflect.fields(presences)) {
            var _ = k; // no-op
        }
    }
}

class Main {
    static function main() {
        // Ensure module is retained and compiled
        PresenceTestModule.exercise();
    }
}
