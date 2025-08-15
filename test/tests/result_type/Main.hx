import haxe.functional.Result;
import haxe.functional.Result.ResultTools;

using haxe.functional.Result.ResultTools;

/**
 * Test case for Universal Result<T,E> type compilation
 * 
 * This test validates:
 * - Basic Result enum compilation
 * - Pattern matching on Result values
 * - ResultTools functional operations
 * - Type safety across success and error cases
 * - Proper Elixir tuple generation for {:ok, _} and {:error, _}
 */
class Main {
    
    /**
     * Demonstrate basic Result usage with string operations
     */
    public static function parseNumber(input: String): Result<Int, String> {
        var parsed = Std.parseInt(input);
        if (parsed != null) {
            return Ok(parsed);
        } else {
            return Error('Invalid number: ${input}');
        }
    }
    
    /**
     * Chain Result operations using flatMap
     */
    public static function divideNumbers(a: String, b: String): Result<Float, String> {
        return ResultTools.flatMap(parseNumber(a), function(numA) {
            return ResultTools.flatMap(parseNumber(b), function(numB) {
                if (numB == 0) {
                    return Error("Division by zero");
                } else {
                    return Ok(numA / numB);
                }
            });
        });
    }
    
    /**
     * Transform Result values using map (with extension syntax)
     */
    public static function doubleIfValid(input: String): Result<Int, String> {
        return parseNumber(input).map(function(num) {
            return num * 2;
        });
    }
    
    /**
     * Handle Result using pattern matching
     */
    public static function handleResult(result: Result<Int, String>): String {
        return switch (result) {
            case Ok(value): 'Success: ${value}';
            case Error(message): 'Error: ${message}';
        }
    }
    
    /**
     * Use fold to extract values safely
     */
    public static function getValueOrDefault(result: Result<Int, String>): Int {
        return ResultTools.fold(result, 
            function(value) return value,
            function(error) return -1
        );
    }
    
    /**
     * Demonstrate extension method chaining (similar to Option)
     */
    public static function testExtensionMethods() {
        var result: Result<String, String> = Ok("hello");
        
        // Test map with extension syntax
        var upperResult = result.map(s -> s.toUpperCase());
        
        // Test flatMap with extension syntax
        var chainedResult = result.flatMap(s -> s.length > 0 ? Ok(s + "!") : Error("empty"));
        
        // Test isOk/isError
        var isValid = result.isOk();
        var hasError = result.isError();
        
        // Test unwrapOr
        var value = result.unwrapOr("default");
    }
    
    
    /**
     * Work with complex Result types (nested data)
     */
    public static function processUser(userData: {name: String, age: String}): Result<{name: String, age: Int}, String> {
        return ResultTools.map(parseNumber(userData.age), function(parsedAge) {
            return {name: userData.name, age: parsedAge};
        });
    }
    
    /**
     * Demonstrate Result utilities
     */
    public static function demonstrateUtilities() {
        var success = Ok(42);
        var failure = Error("Something went wrong");
        
        // Test utility functions
        var isSuccessOk = ResultTools.isOk(success);     // Should be true
        var isFailureOk = ResultTools.isOk(failure);     // Should be false
        var isSuccessError = ResultTools.isError(success); // Should be false
        var isFailureError = ResultTools.isError(failure); // Should be true
        
        // Test unwrapOr
        var successValue = ResultTools.unwrapOr(success, 0);  // Should be 42
        var failureValue = ResultTools.unwrapOr(failure, 0);  // Should be 0
        
        // Test mapError
        var mappedError = ResultTools.mapError(failure, function(err) {
            return 'Mapped: ${err}';
        });
        
        return {
            isSuccessOk: isSuccessOk,
            isFailureOk: isFailureOk,
            isSuccessError: isSuccessError,
            isFailureError: isFailureError,
            successValue: successValue,
            failureValue: failureValue,
            mappedError: mappedError
        };
    }
    
    /**
     * Demonstrate sequence operation for collecting Results
     */
    public static function processMultipleNumbers(inputs: Array<String>): Result<Array<Int>, String> {
        var results = inputs.map(parseNumber);
        return ResultTools.sequence(results);
    }
    
    /**
     * Demonstrate traverse operation
     */
    public static function validateAndDouble(inputs: Array<String>): Result<Array<Int>, String> {
        return ResultTools.traverse(inputs, function(input) {
            return ResultTools.map(parseNumber(input), function(num) return num * 2);
        });
    }
    
    /**
     * Main function demonstrating all Result patterns
     */
    public static function main() {
        // Basic usage
        var result1 = parseNumber("123");    // Ok(123)
        var result2 = parseNumber("abc");    // Error("Invalid number: abc")
        
        // Chaining operations
        var divResult = divideNumbers("10", "2");  // Ok(5.0)
        var divError = divideNumbers("10", "0");   // Error("Division by zero")
        
        // Transformation
        var doubled = doubleIfValid("21");  // Ok(42)
        
        // Pattern matching
        var message1 = handleResult(result1);
        var message2 = handleResult(result2);
        
        // Safe extraction
        var value1 = getValueOrDefault(result1);  // 123
        var value2 = getValueOrDefault(result2);  // -1
        
        // Complex types
        var user = processUser({name: "Alice", age: "25"});
        
        // Utilities
        var utils = demonstrateUtilities();
        
        // Sequence operations
        var numbers = processMultipleNumbers(["1", "2", "3"]);     // Ok([1, 2, 3])
        var numbersError = processMultipleNumbers(["1", "x", "3"]); // Error("Invalid number: x")
        
        // Traverse operations
        var doubled_numbers = validateAndDouble(["5", "10", "15"]); // Ok([10, 20, 30])
        
        trace('Parse "123": ${message1}');
        trace('Parse "abc": ${message2}');
        trace('Divide 10/2: ${divResult}');
        trace('Double 21: ${doubled}');
        trace('Numbers [1,2,3]: ${numbers}');
        trace('Utilities test completed');
    }
}