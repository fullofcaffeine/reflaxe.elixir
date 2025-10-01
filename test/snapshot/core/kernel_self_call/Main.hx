/**
 * Baseline Test for Kernel.self() Generation
 *
 * PURPOSE: Establishes correct self() syntax as baseline
 *
 * CONTEXT: This test uses __elixir__() which BYPASSES CallExprBuilder
 * and generates correct self() output. The ACTUAL BUG is in CallExprBuilder's
 * handlePhoenixCall() method (lines 489, 510) which creates:
 *   ECall(EVar("self"), "", [])  <- WRONG: generates self.()
 * Instead of:
 *   ECall(null, "self", [])     <- RIGHT: generates self()
 *
 * BUG LOCATION: examples/todo-app/lib/phoenix/safe_pub_sub.ex:5
 *   PubSub.subscribe(self.(), pubsub_module, topic_string)  <- WRONG
 * Should be:
 *   PubSub.subscribe(self(), pubsub_module, topic_string)   <- RIGHT
 *
 * This test shows CORRECT generation. After fixing CallExprBuilder,
 * SafePubSub should generate self() like this test does.
 */
class Main {
    static function main() {
        // Correct kernel function call - generates self() properly
        var myPid = untyped __elixir__('self()');
        trace('Current PID: ${myPid}');
    }
}
