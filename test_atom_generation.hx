class TestAtomGen {
    static function main() {
        // Test atom generation with dots
        var spec = {
            id: "Phoenix.PubSub",
            start: {
                module: "Phoenix.PubSub",
                func: "start_link",
                args: [{name: "TestApp.PubSub"}]
            },
            restart: "permanent",
            type: "worker"
        };
        
        // Also test with atoms that don't have dots
        var simple = {
            id: "worker",
            type: "supervisor"
        };
    }
}