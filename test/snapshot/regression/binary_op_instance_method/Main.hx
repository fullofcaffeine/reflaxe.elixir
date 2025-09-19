package;

class Calculator {
    public var base: Int;

    public function new(b: Int) {
        this.base = b;
    }

    public function add(x: Int): Int {
        return this.base + x;  // Binary operation using 'this'
    }

    public function multiply(x: Int): Int {
        return base * x;  // Binary operation without explicit 'this'
    }

    public function concatenate(str: String): String {
        return "Base: " + base + ", Input: " + str;  // String concatenation
    }
}

class Main {
    public static function main() {
        var calc = new Calculator(10);
        var result1 = calc.add(5);
        var result2 = calc.multiply(3);
        var result3 = calc.concatenate("test");
        trace('Results: $result1, $result2, $result3');
    }
}