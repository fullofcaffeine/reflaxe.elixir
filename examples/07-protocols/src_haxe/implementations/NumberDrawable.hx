package implementations;

import protocols.Drawable;

/**
 * Protocol implementation for Integer types
 */
@:impl
class IntDrawable {
    
    public function draw(value: Int): String {
        return "Drawing integer: " + value;
    }
    
    public function area(value: Int): Float {
        // Square the number for "area"
        return value * value;
    }
}

/**
 * Protocol implementation for Float types  
 */
@:impl
class FloatDrawable {
    
    public function draw(value: Float): String {
        return "Drawing float: " + value;
    }
    
    public function area(value: Float): Float {
        // Use the float value as its own area
        return value;
    }
}