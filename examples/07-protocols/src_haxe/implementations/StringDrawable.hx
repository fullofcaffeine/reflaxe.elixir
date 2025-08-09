package implementations;

import protocols.Drawable;

/**
 * Protocol implementation for String types
 */
@:impl
class StringDrawable {
    
    public function draw(value: String): String {
        // In generated Elixir: "Drawing string: #{value}"
        return "Drawing string: " + value;
    }
    
    public function area(value: String): Float {
        // String length as "area"
        return value.length;
    }
}