class TestStringBuf {
    public static function test(): String {
        var buf = new StringBuf();
        buf.add("Testing ");
        buf.add("StringBuf ");
        buf.add("in todo-app");
        
        var result = buf.toString();
        trace('StringBuf test: $result');
        
        // Test with numbers
        var buf2 = new StringBuf();
        buf2.add("Count: ");
        for (i in 1...4) {
            buf2.add(i);
            buf2.add(" ");
        }
        trace('Numbers: ${buf2.toString()}');
        
        return result;
    }
}
