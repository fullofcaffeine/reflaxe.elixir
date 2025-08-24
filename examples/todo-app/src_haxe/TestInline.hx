package;

import phoenix.Phoenix.LiveView;
import phoenix.Phoenix.Socket;

class TestInline {
    public static function testBoth() {
        var socket: Socket<{name: String}> = null;
        
        // Test inline function - should expand at compile time
        var s1 = LiveView.assign_multiple(socket, {name: "Test"});
        
        // Test direct function
        var s2 = LiveView.assign(socket, {name: "Test2"});
        
        return s1;
    }
}
