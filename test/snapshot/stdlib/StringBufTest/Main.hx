class Main {
    public static function main() {
        testBasicOperations();
        testAddChar();
        testAddSub();
        testComplexBuilding();
    }
    
    static function testBasicOperations() {
        var buf = new StringBuf();
        buf.add("Hello");
        buf.add(" ");
        buf.add("World");
        
        var result = buf.toString();
        trace('Basic: $result'); // Should be "Hello World"
        
        // Test null handling
        var buf2 = new StringBuf();
        buf2.add(null);
        buf2.add(" test");
        trace('Null handling: ${buf2.toString()}'); // Should be "null test"
        
        // Test numbers
        var buf3 = new StringBuf();
        buf3.add(42);
        buf3.add(" is the answer");
        trace('Numbers: ${buf3.toString()}'); // Should be "42 is the answer"
    }
    
    static function testAddChar() {
        var buf = new StringBuf();
        buf.addChar(72); // H
        buf.addChar(105); // i
        buf.addChar(33); // !
        
        trace('AddChar: ${buf.toString()}'); // Should be "Hi!"
    }
    
    static function testAddSub() {
        var buf = new StringBuf();
        var source = "Hello World";
        
        buf.addSub(source, 0, 5); // "Hello"
        buf.add("-");
        buf.addSub(source, 6); // "World"
        
        trace('AddSub: ${buf.toString()}'); // Should be "Hello-World"
    }
    
    static function testComplexBuilding() {
        var buf = new StringBuf();
        
        // Build a complex string
        buf.add("List: [");
        for (i in 0...5) {
            if (i > 0) buf.add(", ");
            buf.add(i);
        }
        buf.add("]");
        
        trace('Complex: ${buf.toString()}'); // Should be "List: [0, 1, 2, 3, 4]"
        
        // Test length property
        trace('Length: ${buf.length}'); // Should calculate total length
    }
}