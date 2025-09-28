// Test for guard condition grouping in switch statements
// This test validates that multiple guard conditions compile to idiomatic Elixir cond expressions

enum Color {
    RGB(r: Int, g: Int, b: Int);
    HSL(h: Float, s: Float, l: Float);
    Named(name: String);
    Hex(value: String);
}

class Main {
    static function main() {
        // Test simple guard conditions
        var color1 = RGB(255, 128, 0);
        trace(categorizeRGB(color1));
        
        // Test nested guard conditions
        var color2 = RGB(0, 0, 0);
        trace(categorizeRGB(color2));
        
        // Test multiple constructors with guards
        var color3 = HSL(180.0, 0.5, 0.5);
        trace(categorizeColor(color3));
        
        // Test with string patterns
        var color4 = Named("red");
        trace(categorizeColor(color4));
        
        // Test complex nested patterns
        var color5 = Hex("#FF0000");
        trace(processHexColor(color5));
    }
    
    // Test case 1: Multiple guard conditions on same constructor
    static function categorizeRGB(color: Color): String {
        switch(color) {
            case RGB(r, g, b) if (r > 200 && g < 100 && b < 100):
                return "Mostly Red";
            case RGB(r, g, b) if (g > 200 && r < 100 && b < 100):
                return "Mostly Green";
            case RGB(r, g, b) if (b > 200 && r < 100 && g < 100):
                return "Mostly Blue";
            case RGB(r, g, b) if (r == 0 && g == 0 && b == 0):
                return "Black";
            case RGB(r, g, b) if (r == 255 && g == 255 && b == 255):
                return "White";
            case RGB(r, g, b):
                return "Mixed Color: " + r + "," + g + "," + b;
            case _:
                return "Not RGB";
        }
    }
    
    // Test case 2: Mixed constructors with guards
    static function categorizeColor(color: Color): String {
        switch(color) {
            case RGB(r, g, b) if (r == g && g == b):
                return "Grayscale RGB";
            case RGB(r, g, b) if (r > 200):
                return "Red-ish";
            case HSL(h, s, l) if (s < 0.1):
                return "Desaturated";
            case HSL(h, s, l) if (l > 0.9):
                return "Very Light";
            case HSL(h, s, l) if (l < 0.1):
                return "Very Dark";
            case Named(name) if (name == "red" || name == "green" || name == "blue"):
                return "Primary Color: " + name;
            case Named(name):
                return "Named Color: " + name;
            case _:
                return "Unknown";
        }
    }
    
    // Test case 3: Complex nested guard patterns
    static function processHexColor(color: Color): String {
        switch(color) {
            case Hex(value) if (value.length == 7 && value.charAt(0) == "#"):
                return "Valid 6-digit hex: " + value;
            case Hex(value) if (value.length == 4 && value.charAt(0) == "#"):
                return "Valid 3-digit hex: " + value;
            case Hex(value) if (value.charAt(0) != "#"):
                return "Missing hash prefix: " + value;
            case Hex(value):
                return "Invalid hex format: " + value;
            case _:
                return "Not a hex color";
        }
    }
    
    // Test case 4: Deep nesting with multiple guard levels
    static function analyzeColorDepth(colors: Array<Color>): String {
        if (colors.length == 0) {
            return "Empty";
        }
        
        var first = colors[0];
        switch(first) {
            case RGB(r1, g1, b1) if (r1 > 128):
                var second = colors.length > 1 ? colors[1] : null;
                if (second != null) {
                    switch(second) {
                        case RGB(r2, g2, b2) if (r2 > 128 && g2 > 128):
                            return "Both have high red, second has high green";
                        case RGB(r2, g2, b2) if (b2 > 200):
                            return "First red, second blue";
                        case RGB(r2, g2, b2):
                            return "First red, second mixed";
                        case _:
                            return "First red, second not RGB";
                    }
                }
                return "Single red-dominant color";
            case RGB(r1, g1, b1):
                return "RGB with low red";
            case _:
                return "Not RGB";
        }
    }
}
