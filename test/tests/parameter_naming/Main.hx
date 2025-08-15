// Test case to verify parameter names are preserved in generated Elixir
class Main {
    public function new() {}
    
    // Test basic function with meaningful parameter names
    public function greetUser(userName: String, message: String): String {
        return "Hello " + userName + ": " + message;
    }
    
    // Test function with multiple parameter types
    public function processOrder(orderId: Int, customerEmail: String, amount: Float): Bool {
        return orderId > 0 && customerEmail.length > 0 && amount > 0.0;
    }
    
    // Test static function
    public static function calculateDiscount(originalPrice: Float, discountPercent: Float): Float {
        return originalPrice * (1.0 - discountPercent / 100.0);
    }
    
    // Test function with single parameter
    public function validateEmail(emailAddress: String): Bool {
        return emailAddress.indexOf("@") > 0;
    }
}