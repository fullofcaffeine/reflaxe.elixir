package phoenix_chat_hx.utils;

/**
 * Mathematical utility functions  
 * Generated example module
 */
@:module
class MathHelper {
    public static function clamp(value: Float, min: Float, max: Float): Float {
        if (value < min) return min;
        if (value > max) return max;
        return value;
    }
    
    public static function lerp(a: Float, b: Float, t: Float): Float {
        return a + (b - a) * t;
    }
    
    public static function isPrime(n: Int): Bool {
        if (n <= 1) return false;
        if (n <= 3) return true;
        if (n % 2 == 0 || n % 3 == 0) return false;
        
        var i = 5;
        while (i * i <= n) {
            if (n % i == 0 || n % (i + 2) == 0) return false;
            i += 6;
        }
        return true;
    }
}
