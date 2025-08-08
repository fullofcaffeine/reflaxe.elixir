
using StringTools;

/**
 * MathHelper - Demonstrates pipe operators and functional composition
 * 
 * This example showcases Elixir-style pipe operators (|>) for
 * functional composition, making code more readable and maintainable.
 */
@:module
class MathHelper {
    
    /**
     * Basic functional composition demonstration
     * Shows how data flows through a pipeline of transformations
     * Note: Pipe operators will be supported in future version
     */
    function processNumber(x: Float): Float {
        var step1 = multiplyByTwo(x);
        var step2 = addTen(step1);
        var step3 = Math.round(step2);
        return step3;
    }
    
    /**
     * Complex pipeline with conditional logic
     * Demonstrates functional composition with branching
     */
    function calculateDiscount(price: Float, customerType: String): Float {
        var step1 = applyBaseDiscount(price);
        var step2 = applyCustomerDiscount(step1, customerType);
        var step3 = applyMinimumPrice(step2);
        return Math.round(step3);
    }
    
    /**
     * String processing pipeline
     * Shows functional composition with different data types
     */
    function formatUserName(name: String): String {
        var step1 = StringTools.trim(name);
        var step2 = step1.toLowerCase();
        return capitalizeFirst(step2);
    }
    
    /**
     * Data validation pipeline
     * Common pattern in Elixir for validation chains
     */
    function validateAndProcess(input: String): String {
        var step1 = validateNotEmpty(input);
        var step2 = validateLength(step1);
        var step3 = sanitizeInput(step2);
        return processInput(step3);
    }
    
    // Helper functions used in pipelines
    
    function multiplyByTwo(x: Float): Float {
        return x * 2;
    }
    
    function addTen(x: Float): Float {
        return x + 10;
    }
    
    function applyBaseDiscount(price: Float): Float {
        return price * 0.9; // 10% discount
    }
    
    function applyCustomerDiscount(price: Float, customerType: String): Float {
        return switch (customerType) {
            case "premium": price * 0.8;
            case "regular": price * 0.95;
            case _: price;
        };
    }
    
    function applyMinimumPrice(price: Float): Float {
        return Math.max(price, 5.0);
    }
    
    function capitalizeFirst(str: String): String {
        if (str.length == 0) return str;
        return str.charAt(0).toUpperCase() + str.substr(1);
    }
    
    function validateNotEmpty(input: String): String {
        if (input == null || input.length == 0) {
            throw "Input cannot be empty";
        }
        return input;
    }
    
    function validateLength(input: String): String {
        if (input.length > 100) {
            throw "Input too long";
        }
        return input;
    }
    
    function sanitizeInput(input: String): String {
        // Simple sanitization - remove dangerous characters
        return StringTools.replace(input, "<", "");
    }
    
    function processInput(input: String): String {
        return "Processed: " + input;
    }
    
    /**
     * Main function for compilation testing
     */
    public static function main(): Void {
        trace("MathHelper example compiled successfully!");
        trace("This demonstrates functional composition patterns.");
        trace("In production, these functions would be called from other modules.");
    }
}