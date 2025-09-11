enum Color {
    RGB(r: Int, g: Int, b: Int);
}

class DebugEnumTest {
    static function test(c: Color): String {
        return switch(c) {
            case RGB(r, g, b): 'r=$r, g=$g, b=$b';
        }
    }
    
    static function main() {
        trace(test(RGB(255, 128, 0)));
    }
}