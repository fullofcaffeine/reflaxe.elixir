/**
 * Enhanced Pattern Matching Test
 * Tests advanced pattern matching features including:
 * - Exhaustive checking with compile-time warnings
 * - Nested patterns with proper destructuring
 * - Complex guards with multiple conditions
 * - With statements for Result pattern handling
 * - Binary patterns for data processing
 */

// Define comprehensive enum for exhaustive testing
enum Status {
    Idle;
    Working(task: String);
    Completed(result: String, duration: Int);
    Failed(error: String, retries: Int);
}

// Define nested data structure for complex patterns
enum DataResult<T, E> {
    Success(value: T);
    Error(error: E, context: String);
}

enum ValidationState {
    Valid;
    Invalid(errors: Array<String>);
    Pending(validator: String);
}

// Abstract for Result type with enhanced pattern matching
abstract Result<T, E>(DataResult<T, E>) from DataResult<T, E> to DataResult<T, E> {
    public inline function new(result: DataResult<T, E>) {
        this = result;
    }

    public static inline function success<T, E>(value: T): Result<T, E> {
        return new Result(Success(value));
    }

    public static inline function error<T, E>(error: E, context: String = ""): Result<T, E> {
        return new Result(Error(error, context));
    }
}

class EnhancedPatternMatchingTest {

    /**
     * Test exhaustive pattern matching with all enum cases
     * Should generate all possible case clauses
     */
    public static function matchStatus(status: Status): String {
        return switch (status) {
            case Idle: "Currently idle";
            case Working(task): 'Working on: $task';
            case Completed(result, duration): 'Completed "$result" in ${duration}ms';
            case Failed(error, retries): 'Failed with "$error" after $retries retries';
        };
    }

    /**
     * Test partial pattern matching (missing cases) - should generate warning
     * Intentionally incomplete for exhaustive checking test
     */
    public static function incompleteMatch(status: Status): String {
        return switch (status) {
            case Idle: "idle";
            case Working(task): 'working: $task';
            // Missing Completed and Failed cases - should warn
            case _: "unknown";
        };
    }

    /**
     * Test nested pattern matching with complex destructuring
     */
    public static function matchNestedResult<T>(result: Result<Result<T, String>, String>): String {
        return switch (result) {
            case Success(Success(value)): 'Double success: ${Std.string(value)}';
            case Success(Error(innerError, innerContext)): 'Outer success, inner error: $innerError (context: $innerContext)';
            case Error(outerError, outerContext): 'Outer error: $outerError (context: $outerContext)';
        };
    }

    /**
     * Test complex guards with multiple conditions and logical operators
     */
    public static function matchWithComplexGuards(status: Status, priority: Int, isUrgent: Bool): String {
        return switch (status) {
            case Working(task) if (priority > 5 && isUrgent): 'High priority urgent task: $task';
            case Working(task) if (priority > 3 && !isUrgent): 'High priority normal task: $task';
            case Working(task) if (priority <= 3 && isUrgent): 'Low priority urgent task: $task';
            case Working(task): 'Normal task: $task';
            case Completed(result, duration) if (duration < 1000): 'Fast completion: $result';
            case Completed(result, duration) if (duration >= 1000 && duration < 5000): 'Normal completion: $result';
            case Completed(result, duration): 'Slow completion: $result';
            case Failed(error, retries) if (retries < 3): 'Recoverable failure: $error';
            case Failed(error, retries): 'Permanent failure: $error';
            case Idle: "idle";
        };
    }

    /**
     * Test range guards and membership tests
     */
    public static function matchWithRangeGuards(value: Int, category: String): String {
        return switch ([value, category]) {
            case [n, "score"] if (n >= 90): "Excellent score";
            case [n, "score"] if (n >= 70 && n < 90): "Good score";
            case [n, "score"] if (n >= 50 && n < 70): "Average score";
            case [n, "score"] if (n < 50): "Poor score";
            case [n, "temperature"] if (n >= 30): "Hot";
            case [n, "temperature"] if (n >= 20 && n < 30): "Warm";
            case [n, "temperature"] if (n >= 10 && n < 20): "Cool";
            case [n, "temperature"] if (n < 10): "Cold";
            case [n, cat]: 'Unknown category "$cat" with value $n';
        };
    }

    /**
     * Test Result patterns that should generate with statements
     * This should demonstrate Elixir's with statement generation
     */
    public static function chainResultOperations(input: String): Result<String, String> {
        var step1 = validateInput(input);
        var step2 = switch (step1) {
            case Success(validated): processData(validated);
            case Error(error, context): Result.error(error, context);
        };
        var step3 = switch (step2) {
            case Success(processed): formatOutput(processed);
            case Error(error, context): Result.error(error, context);
        };
        return step3;
    }

    /**
     * Test array patterns with length-based matching
     */
    public static function matchArrayPatterns(arr: Array<Int>): String {
        return switch (arr) {
            case []: "empty array";
            case [x]: 'single element: $x';
            case [x, y]: 'pair: [$x, $y]';
            case [x, y, z]: 'triple: [$x, $y, $z]';
            case a if (a.length > 3): 'starts with ${a[0]}, has ${a.length - 1} more elements';
            case _: "other array pattern";
        };
    }

    /**
     * Test string patterns with complex conditions
     */
    public static function matchStringPatterns(input: String): String {
        return switch (input) {
            case "": "empty string";
            case s if (s.length == 1): 'single character: "$s"';
            case s if (s.substr(0, 7) == "prefix_"): 'has prefix: "$s"';
            case s if (s.substr(s.length - 7) == "_suffix"): 'has suffix: "$s"';
            case s if (s.indexOf("@") > -1): 'contains @: "$s"';
            case s if (s.length > 100): "very long string";
            case s: 'regular string: "$s"';
        };
    }

    /**
     * Test tuple/object patterns with field matching
     */
    public static function matchObjectPatterns(data: {name: String, age: Int, active: Bool}): String {
        return switch ([data.name, data.age, data.active]) {
            case [name, age, true] if (age >= 18): 'Active adult: $name ($age)';
            case [name, age, true] if (age < 18): 'Active minor: $name ($age)';
            case [name, age, false]: 'Inactive user: $name ($age)';
            case _: "unknown pattern";
        };
    }

    /**
     * Test enum patterns with validation state
     */
    public static function matchValidationState(state: ValidationState): String {
        return switch (state) {
            case Valid: "Data is valid";
            case Invalid(errors) if (errors.length == 1): 'Single error: ${errors[0]}';
            case Invalid(errors) if (errors.length > 1): 'Multiple errors: ${errors.length} issues';
            case Invalid(errors): "No specific errors";
            case Pending(validator): 'Validation pending by: $validator';
        };
    }

    /**
     * Test binary patterns for byte matching (if supported)
     */
    public static function matchBinaryPattern(data: String): String {
        // This tests binary pattern matching capabilities
        var bytes = haxe.io.Bytes.ofString(data);
        return switch (bytes.length) {
            case 0: "empty";
            case 1: 'single byte: ${bytes.get(0)}';
            case n if (n <= 4): 'small data: $n bytes';
            case n: 'large data: $n bytes';
        };
    }

    // Helper functions for Result chaining test
    private static function validateInput(input: String): Result<String, String> {
        if (input.length == 0) {
            return Result.error("Empty input", "validation");
        }
        if (input.length > 1000) {
            return Result.error("Input too long", "validation");
        }
        return Result.success(input.toLowerCase());
    }

    private static function processData(data: String): Result<String, String> {
        if (data.indexOf("error") >= 0) {
            return Result.error("Data contains error keyword", "processing");
        }
        return Result.success(data.toUpperCase());
    }

    private static function formatOutput(data: String): Result<String, String> {
        if (data.length == 0) {
            return Result.error("No data to format", "formatting");
        }
        return Result.success('Formatted: [$data]');
    }

    public static function main() {
        trace("Enhanced pattern matching compilation test");
        
        // Test basic patterns
        trace(matchStatus(Working("compile")));
        trace(matchStatus(Completed("success", 1500)));
        
        // Test incomplete patterns (should generate warning)
        trace(incompleteMatch(Failed("timeout", 2)));
        
        // Test nested patterns
        var nestedSuccess = Result.success(Result.success("deep value"));
        trace(matchNestedResult(nestedSuccess));
        
        // Test complex guards
        trace(matchWithComplexGuards(Working("urgent task"), 8, true));
        
        // Test range guards
        trace(matchWithRangeGuards(85, "score"));
        trace(matchWithRangeGuards(25, "temperature"));
        
        // Test Result chaining (with statements)
        trace(chainResultOperations("valid input"));
        trace(chainResultOperations(""));
        
        // Test array patterns
        trace(matchArrayPatterns([1, 2, 3, 4, 5]));
        trace(matchArrayPatterns([]));
        
        // Test string patterns
        trace(matchStringPatterns("prefix_test"));
        trace(matchStringPatterns("test@example.com"));
        
        // Test object patterns
        trace(matchObjectPatterns({name: "Alice", age: 25, active: true}));
        trace(matchObjectPatterns({name: "Bob", age: 16, active: true}));
        
        // Test validation state
        trace(matchValidationState(Invalid(["Required field missing", "Invalid format"])));
        trace(matchValidationState(Pending("security_validator")));
        
        // Test binary patterns
        trace(matchBinaryPattern("test"));
        trace(matchBinaryPattern(""));
    }
}