package;

enum Color {
    RGB(r: Int, g: Int, b: Int);
    HSL(h: Float, s: Float, l: Float);
    Named(name: String);
}

class Main {
    /**
     * Test multiple cases with same pattern but different guards.
     * This should compile to a single case clause with a cond expression.
     */
    static function describeColor(color: Color): String {
        return switch(color) {
            case RGB(r, g, b) if (r > 200 && g < 50 && b < 50): "mostly red";
            case RGB(r, g, b) if (g > 200 && r < 50 && b < 50): "mostly green";
            case RGB(r, g, b) if (b > 200 && r < 50 && g < 50): "mostly blue";
            case RGB(r, g, b) if (r > 100 && g > 100 && b > 100): "bright";
            case RGB(r, g, b): "mixed color";
            case HSL(h, s, l) if (s < 0.1): "grayscale";
            case HSL(h, s, l) if (l > 0.9): "very light";
            case HSL(h, s, l): "normal HSL";
            case Named(name): 'named: $name';
        }
    }
    
    /**
     * Test with simpler pattern for clarity.
     */
    static function categorizeRGB(color: Color): String {
        return switch(color) {
            case RGB(r, g, b) if (r > 200): "high red";
            case RGB(r, g, b) if (g > 200): "high green";
            case RGB(r, g, b) if (b > 200): "high blue";
            case RGB(r, g, b): "normal";
            case _: "not RGB";
        }
    }
    
    /**
     * Test mixed patterns - not all should be grouped.
     */
    static function processColor(color: Color): Int {
        return switch(color) {
            case RGB(r, g, b) if (r + g + b > 500): 3;  // bright
            case RGB(r, g, b) if (r + g + b > 300): 2;  // medium
            case HSL(h, s, l): Math.round(h * 360);      // different pattern - should not group
            case RGB(r, g, b): 1;                        // dim (default for RGB)
            case Named(_): 0;
        }
    }
    
    static function main() {
        // Test the functions with various colors
        var red = RGB(250, 30, 30);
        var green = RGB(30, 250, 30);
        var blue = RGB(30, 30, 250);
        var gray = RGB(128, 128, 128);
        var bright = RGB(200, 200, 200);
        var hsl = HSL(0.5, 0.8, 0.5);
        var named = Named("crimson");
        
        trace(describeColor(red));    // Should output: "mostly red"
        trace(describeColor(green));  // Should output: "mostly green"
        trace(describeColor(blue));   // Should output: "mostly blue"
        trace(describeColor(gray));   // Should output: "mixed color"
        trace(describeColor(bright)); // Should output: "bright"
        
        trace(categorizeRGB(red));    // Should output: "high red"
        trace(categorizeRGB(green));  // Should output: "high green"
        trace(categorizeRGB(blue));   // Should output: "high blue"
        trace(categorizeRGB(gray));   // Should output: "normal"
        trace(categorizeRGB(hsl));    // Should output: "not RGB"
        
        trace(processColor(bright));  // Should output: 2
        trace(processColor(gray));    // Should output: 1
        trace(processColor(hsl));     // Should output: 180
        trace(processColor(named));   // Should output: 0
    }
}