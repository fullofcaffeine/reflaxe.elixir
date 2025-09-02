import js.lib.Promise;

/**
 * Simple test to verify async/await type safety
 */
@:build(genes.AsyncMacro.build())
class TestAsyncSimple {
    
    @:async
    static function test1(): Promise<Int> {
        var num = @:await Promise.resolve(42);
        // Type check: num should be Int
        return Promise.resolve(num + 1);
    }
    
    @:async
    static function test2(): Promise<String> {
        var str = @:await Promise.resolve("hello");
        // Type check: str should be String
        return Promise.resolve(str.toUpperCase());
    }
    
    @:async
    static function testError(): Promise<String> {
        try {
            @:await Promise.reject("error");
            return Promise.resolve("not reached");
        } catch (e: Dynamic) {
            return Promise.resolve('Caught: $e');
        }
    }
    
    static function main() {
        trace("Tests compiled successfully");
    }
}