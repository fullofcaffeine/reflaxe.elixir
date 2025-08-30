abstract TestAbstract(String) from String to String {
    public function new(s: String) {
        this = s;
    }
    
    public function getValue(): String {
        return this;
    }
    
    public static function staticTest(value: TestAbstract): String {
        return value;
    }
}

class TestMain {
    static function main() {
        var t = new TestAbstract("test");
        trace(t.getValue());
    }
}