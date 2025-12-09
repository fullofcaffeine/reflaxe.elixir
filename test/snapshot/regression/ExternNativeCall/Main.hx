package;

import phoenix.Component;

/**
 * Test that extern classes with @:native annotations compile correctly
 *
 * The Phoenix.Component extern class has @:native("Phoenix.Component")
 * Static method calls should compile to Phoenix.Component.assign(...)
 * not to something like TodoApp.phoenix.component.assign(...)
 */
@:nullSafety(Off)
class Main {
    static function main() {
        var socket: Dynamic = null;
        var assigns = {test: "value"};

        // This should generate: Phoenix.Component.assign(socket, assigns)
        var result = Component.assign(socket, assigns);

        trace("Test completed");
    }
}
