using ArrayTools;
import haxe.ds.Option;
import haxe.ds.OptionTools;
import haxe.functional.Result;

using haxe.ds.OptionTools;

/**
 * Comprehensive test for Option<T> type compilation
 * Tests idiomatic Haxe patterns compiling to BEAM-friendly Elixir
 */
class Main {
    
    public static function main() {
        testOptionConstruction();
        testPatternMatching();
        testFunctionalOperations();
        testBeamIntegration();
        testNullSafety();
        testCollectionOperations();
    }
    
    /**
     * Test basic Option construction patterns
     */
    static function testOptionConstruction() {
        // Basic constructors
        var someValue: Option<String> = Some("hello");
        var noneValue: Option<String> = None;
        
        // From nullable values
        var name: String = "world";
        var nullableName: Null<String> = null;
        
        var optionFromValue = OptionTools.fromNullable(name);
        var optionFromNull = OptionTools.fromNullable(nullableName);
        
        // Convenience constructors
        var somePerson = OptionTools.some("Alice");
        var noPerson = OptionTools.none();
    }
    
    /**
     * Test idiomatic Haxe pattern matching
     */
    static function testPatternMatching() {
        var user: Option<String> = Some("Bob");
        
        // Exhaustive pattern matching
        var result = switch (user) {
            case Some(name): 'Hello, ${name}';
            case None: "Hello, anonymous";
        };
        
        // Nested pattern matching
        var scores: Option<Array<Int>> = Some([1, 2, 3]);
        var total = switch (scores) {
            case Some(scoreList): scoreList.length;
            case None: 0;
        };
        
        // Pattern matching in function parameters
        processUser(Some("Charlie"));
        processUser(None);
    }
    
    static function processUser(user: Option<String>) {
        switch (user) {
            case Some(name): trace('Processing user: ${name}');
            case None: trace('No user to process');
        }
    }
    
    /**
     * Test functional operations (map, filter, flatMap, etc.)
     */
    static function testFunctionalOperations() {
        var user: Option<String> = Some("David");
        
        // Map operation
        var upperName = user.map(name -> name.toUpperCase());
        
        // Filter operation
        var longName = user.filter(name -> name.length > 3);
        
        // FlatMap / then operation (Gleam style)
        var processedUser = user.then(name -> {
            return name.length > 0 ? Some(name + "!") : None;
        });
        
        // Chaining operations
        var finalResult = user
            .map(name -> name.toUpperCase())
            .filter(name -> name.length > 2)
            .then(name -> Some(name + " [PROCESSED]"));
            
        // Unwrap with default
        var greeting = user.unwrap("Anonymous");
        
        // Lazy unwrap
        var expensiveDefault = user.lazyUnwrap(() -> {
            return "Computed default";
        });
        
        // Combination operations
        var first: Option<String> = Some("First");
        var second: Option<String> = None;
        var combined = first.or(second);
        
        var lazySecond = first.lazyOr(() -> Some("Lazy second"));
    }
    
    /**
     * Test BEAM/OTP integration patterns
     */
    static function testBeamIntegration() {
        var user: Option<String> = Some("Eve");
        
        // Convert to Result for error handling
        var userResult = user.toResult("User not found");
        
        // Convert Result back to Option
        var okResult: Result<String, String> = Ok("Frank");
        var errorResult: Result<String, String> = Error("Not found");
        
        var optionFromOk = okResult.fromResult();
        var optionFromError = errorResult.fromResult();
        
        // GenServer reply patterns (would compile to proper Elixir tuples)
        var reply = user.toReply();
        
        // Crash with clear message (Gleam-style expect)
        var validUser = Some("Grace");
        var confirmedUser = validUser.expect("Expected valid user");
    }
    
    /**
     * Test null safety guarantees
     */
    static function testNullSafety() {
        // Converting nullable to Option eliminates null references
        var maybeNull: Null<String> = null;
        var safeOption = OptionTools.fromNullable(maybeNull);
        
        // Safe operations that never throw
        var result = safeOption
            .map(s -> s.length)
            .unwrap(0);
            
        // Check presence
        var hasValue = safeOption.isSome();
        var isEmpty = safeOption.isNone();
        
        // Safe extraction to nullable (for interop)
        var backToNullable = safeOption.toNullable();
    }
    
    /**
     * Test collection operations with Option
     */
    static function testCollectionOperations() {
        // Array of Options
        var options: Array<Option<Int>> = [
            Some(1),
            None,
            Some(3),
            Some(4),
            None
        ];
        
        // Extract all Some values
        var values = OptionTools.values(options);
        
        // Combine all - succeeds only if all are Some
        var allOptions: Array<Option<Int>> = [Some(1), Some(2), Some(3)];
        var combined = OptionTools.all(allOptions);
        
        var mixedOptions: Array<Option<Int>> = [Some(1), None, Some(3)];
        var failedCombine = OptionTools.all(mixedOptions); // Should be None
        
        // Working with Option arrays in functional style
        var processedValues = options
            .map(opt -> opt.map(x -> x * 2))
            .filter(opt -> opt.isSome());
    }
}

/**
 * Example domain type for testing
 */
typedef User = {
    name: String,
    email: Option<String>
}

/**
 * Example service class showing Option usage patterns
 */
class UserService {
    
    static var users: Array<User> = [
        {name: "Alice", email: Some("alice@example.com")},
        {name: "Bob", email: None}
    ];
    
    public static function findUser(name: String): Option<User> {
        for (user in users) {
            if (user.name == name) {
                return Some(user);
            }
        }
        return None;
    }
    
    public static function getUserEmail(name: String): Option<String> {
        return findUser(name).then(user -> user.email);
    }
    
    public static function notifyUser(name: String, message: String): Bool {
        return getUserEmail(name)
            .map(email -> sendEmail(email, message))
            .unwrap(false);
    }
    
    static function sendEmail(email: String, message: String): Bool {
        trace('Sending email to ${email}: ${message}');
        return true;
    }
}