class Main {
    public static function main() {
        // Test variables with trailing digits
        var pos1 = 10;
        var pos2 = 20;
        var array1 = [1, 2, 3];
        var item123 = "test";
        var value99 = 99;
        
        // Use them to ensure they're not optimized away
        trace(pos1);
        trace(pos2);
        trace(array1);
        trace(item123);
        trace(value99);
        
        // Test in function parameters
        testParams(pos1, pos2);
        
        // Test camelCase with digits
        var userId1 = "user1";
        var userId2 = "user2";
        var htmlElement5 = "div";
        
        trace(userId1);
        trace(userId2);
        trace(htmlElement5);
    }
    
    static function testParams(pos1: Int, pos2: Int) {
        // These should remain distinct variables
        var sum = pos1 + pos2;
        trace('pos1: $pos1, pos2: $pos2, sum: $sum');
    }
}