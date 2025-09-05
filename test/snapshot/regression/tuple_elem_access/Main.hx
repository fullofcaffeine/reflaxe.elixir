class Main {
    public static function main() {
        // Test tuple element access patterns
        var tuple2 = {_1: "first", _2: 42};
        var tuple3 = {_1: true, _2: 3.14, _3: "third"};
        
        // Direct element access
        var first = tuple2._1;
        var second = tuple2._2;
        trace('Tuple2: first=$first, second=$second');
        
        // Access via variable
        var t = tuple3;
        var elem1 = t._1;
        var elem2 = t._2;
        var elem3 = t._3;
        trace('Tuple3: $elem1, $elem2, $elem3');
        
        // Nested tuple access
        var nested = {_1: {_1: "nested", _2: 99}, _2: "outer"};
        var innerFirst = nested._1._1;
        var innerSecond = nested._1._2;
        trace('Nested: inner=($innerFirst, $innerSecond)');
        
        // Function returning tuple
        var result = getTuple();
        trace('Result: ${result._1}, ${result._2}');
    }
    
    static function getTuple() {
        return {_1: "hello", _2: 123};
    }
}