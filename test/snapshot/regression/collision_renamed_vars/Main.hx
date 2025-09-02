class Main {
    static function compareParams(p1:Array<Int>, p2:Array<Int>):Int {
        // Haxe may rename p1/p2 to avoid collision with local variables
        var p = p1;  // This might cause p1 to be renamed to p_1
        var p = p2;  // This might cause p2 to be renamed to p_2
        
        // Now references to the original parameters should use renamed versions
        if (p1.length == 0 && p2.length == 0) return 0;
        return compareArrays(p1, p2);
    }
    
    static function compareArrays(a1:Array<Int>, a2:Array<Int>):Int {
        return a1.length - a2.length;
    }
    
    static function main() {
        var result = compareParams([1, 2], [3, 4, 5]);
        trace('Result: $result');
    }
}