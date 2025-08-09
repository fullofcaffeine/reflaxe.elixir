package protocols;

/**
 * Example protocol for drawable objects
 */
@:protocol
class Drawable {
    
    /**
     * Draw a visual representation of the object
     */
    public function draw(value: Dynamic): String {
        throw "Protocol method should be implemented";
    }
    
    /**
     * Calculate the "area" or size metric of the object
     */
    public function area(value: Dynamic): Float {
        throw "Protocol method should be implemented";
    }
}