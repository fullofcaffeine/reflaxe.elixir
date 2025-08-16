import haxe.validation.Email;
import haxe.validation.UserId;
import haxe.validation.PositiveInt;
import haxe.validation.NonEmptyString;
import haxe.functional.Result;
import haxe.ds.Option;

using haxe.functional.ResultTools;
using haxe.ds.OptionTools;

/**
 * Comprehensive test for type-safe domain abstractions.
 * 
 * This test demonstrates the four domain abstractions inspired by 
 * Domain-Driven Design and Gleam's type philosophy:
 * - Email: Type-safe email validation with domain extraction
 * - UserId: Alphanumeric user identifiers with case handling
 * - PositiveInt: Integers guaranteed to be > 0 with safe arithmetic
 * - NonEmptyString: Strings guaranteed to have content with safe operations
 * 
 * All abstractions follow "Parse, Don't Validate" principle and provide
 * runtime validation with minimal performance impact.
 */
class Main {
    static function main() {
        trace("Testing domain abstractions with type safety...");
        
        testEmailValidation();
        testUserIdValidation();
        testPositiveIntArithmetic();
        testNonEmptyStringOperations();
        testFunctionalComposition();
        testErrorHandling();
        testRealWorldScenarios();
        
        trace("Domain abstraction tests completed!");
    }
    
    /**
     * Test Email domain abstraction with validation and extraction
     */
    static function testEmailValidation() {
        trace("=== Email Validation Tests ===");
        
        // Valid email construction
        var emailResult = Email.parse("user@example.com");
        switch (emailResult) {
            case Ok(email):
                var domain = email.getDomain();
                var localPart = email.getLocalPart();
                trace('Valid email - Domain: ${domain}, Local: ${localPart}');
                
                // Test domain checking
                var isExampleDomain = email.hasDomain("example.com");
                trace('Is example.com domain: ${isExampleDomain}');
                
                // Test normalization
                var normalized = email.normalize();
                trace('Normalized: ${normalized.toString()}');
                
            case Error(reason):
                trace('Unexpected email validation failure: ${reason}');
        }
        
        // Invalid email construction
        var invalidEmails = [
            "invalid-email",
            "@example.com",
            "user@",
            "user@@example.com",
            "",
            "user space@example.com"
        ];
        
        for (invalidEmail in invalidEmails) {
            switch (Email.parse(invalidEmail)) {
                case Ok(_):
                    trace('ERROR: Invalid email "${invalidEmail}" was accepted');
                case Error(reason):
                    trace('Correctly rejected "${invalidEmail}": ${reason}');
            }
        }
        
        // Email equality testing
        var email1Result = Email.parse("Test@Example.Com");
        var email2Result = Email.parse("test@example.com");
        
        if (email1Result.isOk() && email2Result.isOk()) {
            var email1 = email1Result.unwrap();
            var email2 = email2Result.unwrap();
            var areEqual = email1.equals(email2);
            trace('Case-insensitive equality: ${areEqual}');
        }
    }
    
    /**
     * Test UserId domain abstraction with alphanumeric validation
     */
    static function testUserIdValidation() {
        trace("=== UserId Validation Tests ===");
        
        // Valid UserId construction
        var validIds = ["user123", "Alice", "Bob42", "testUser"];
        
        for (validId in validIds) {
            switch (UserId.parse(validId)) {
                case Ok(userId):
                    var length = userId.length();
                    var normalized = userId.normalize();
                    trace('Valid UserId "${validId}" - Length: ${length}, Normalized: ${normalized.toString()}');
                    
                    // Test prefix checking
                    var startsWithUser = userId.startsWithIgnoreCase("user");
                    trace('Starts with "user" (case-insensitive): ${startsWithUser}');
                    
                case Error(reason):
                    trace('Unexpected UserId validation failure for "${validId}": ${reason}');
            }
        }
        
        // Invalid UserId construction
        var invalidIds = [
            "ab",           // Too short
            "user@123",     // Contains @
            "user 123",     // Contains space
            "user-123",     // Contains hyphen
            "",             // Empty
            "a".repeat(60)  // Too long (> 50 chars)
        ];
        
        for (invalidId in invalidIds) {
            switch (UserId.parse(invalidId)) {
                case Ok(_):
                    trace('ERROR: Invalid UserId "${invalidId}" was accepted');
                case Error(reason):
                    trace('Correctly rejected "${invalidId}": ${reason}');
            }
        }
        
        // UserId comparison testing
        var id1Result = UserId.parse("User123");
        var id2Result = UserId.parse("user123");
        
        if (id1Result.isOk() && id2Result.isOk()) {
            var id1 = id1Result.unwrap();
            var id2 = id2Result.unwrap();
            var exactEqual = id1.equals(id2);
            var caseInsensitiveEqual = id1.equalsIgnoreCase(id2);
            trace('Exact equality: ${exactEqual}, Case-insensitive: ${caseInsensitiveEqual}');
        }
    }
    
    /**
     * Test PositiveInt domain abstraction with safe arithmetic
     */
    static function testPositiveIntArithmetic() {
        trace("=== PositiveInt Arithmetic Tests ===");
        
        // Valid PositiveInt construction
        var validNumbers = [1, 5, 42, 100, 999];
        
        for (validNum in validNumbers) {
            switch (PositiveInt.parse(validNum)) {
                case Ok(posInt):
                    trace('Valid PositiveInt: ${posInt.toString()}');
                    
                    // Test safe arithmetic operations
                    var doubled = posInt * PositiveInt.parse(2).unwrap();
                    var added = posInt + PositiveInt.parse(10).unwrap();
                    trace('Doubled: ${doubled.toString()}, Added 10: ${added.toString()}');
                    
                    // Test safe subtraction
                    var subtractResult = posInt.safeSub(PositiveInt.parse(1).unwrap());
                    switch (subtractResult) {
                        case Ok(result):
                            trace('Safe subtraction result: ${result.toString()}');
                        case Error(reason):
                            trace('Safe subtraction failed: ${reason}');
                    }
                    
                    // Test comparison operations
                    var five = PositiveInt.parse(5).unwrap();
                    var isGreater = posInt > five;
                    var min = posInt.min(five);
                    var max = posInt.max(five);
                    trace('Greater than 5: ${isGreater}, Min with 5: ${min.toString()}, Max with 5: ${max.toString()}');
                    
                case Error(reason):
                    trace('Unexpected PositiveInt validation failure for ${validNum}: ${reason}');
            }
        }
        
        // Invalid PositiveInt construction
        var invalidNumbers = [0, -1, -42, -100];
        
        for (invalidNum in invalidNumbers) {
            switch (PositiveInt.parse(invalidNum)) {
                case Ok(_):
                    trace('ERROR: Invalid PositiveInt ${invalidNum} was accepted');
                case Error(reason):
                    trace('Correctly rejected ${invalidNum}: ${reason}');
            }
        }
        
        // Test safe operations that might fail
        var five = PositiveInt.parse(5).unwrap();
        var ten = PositiveInt.parse(10).unwrap();
        
        // This should fail - result would be negative
        switch (five.safeSub(ten)) {
            case Ok(_):
                trace('ERROR: Subtraction that should fail succeeded');
            case Error(reason):
                trace('Correctly prevented invalid subtraction: ${reason}');
        }
        
        // Test safe division
        var twenty = PositiveInt.parse(20).unwrap();
        var four = PositiveInt.parse(4).unwrap();
        var three = PositiveInt.parse(3).unwrap();
        
        switch (twenty.safeDiv(four)) {
            case Ok(result):
                trace('20 / 4 = ${result.toString()}');
            case Error(reason):
                trace('Division failed: ${reason}');
        }
        
        switch (twenty.safeDiv(three)) {
            case Ok(result):
                trace('20 / 3 = ${result.toString()} (unexpected success)');
            case Error(reason):
                trace('20 / 3 correctly failed (not exact): ${reason}');
        }
    }
    
    /**
     * Test NonEmptyString domain abstraction with safe operations
     */
    static function testNonEmptyStringOperations() {
        trace("=== NonEmptyString Operations Tests ===");
        
        // Valid NonEmptyString construction
        var validStrings = ["hello", "world", "test", "NonEmptyString"];
        
        for (validStr in validStrings) {
            switch (NonEmptyString.parse(validStr)) {
                case Ok(nonEmptyStr):
                    var length = nonEmptyStr.length();
                    var upper = nonEmptyStr.toUpperCase();
                    var lower = nonEmptyStr.toLowerCase();
                    trace('Valid NonEmptyString "${validStr}" - Length: ${length}, Upper: ${upper.toString()}, Lower: ${lower.toString()}');
                    
                    // Test safe concatenation (always succeeds)
                    var other = NonEmptyString.parse("!").unwrap();
                    var concatenated = nonEmptyStr.concat(other);
                    trace('Concatenated with "!": ${concatenated.toString()}');
                    
                    // Test character extraction
                    var firstChar = nonEmptyStr.firstChar();
                    var lastChar = nonEmptyStr.lastChar();
                    trace('First char: ${firstChar.toString()}, Last char: ${lastChar.toString()}');
                    
                    // Test safe substring
                    switch (nonEmptyStr.safeSubstring(1)) {
                        case Ok(substr):
                            trace('Substring from index 1: ${substr.toString()}');
                        case Error(reason):
                            trace('Substring failed: ${reason}');
                    }
                    
                case Error(reason):
                    trace('Unexpected NonEmptyString validation failure for "${validStr}": ${reason}');
            }
        }
        
        // Invalid NonEmptyString construction
        var invalidStrings = ["", "   ", "\t\n"];
        
        for (invalidStr in invalidStrings) {
            switch (NonEmptyString.parse(invalidStr)) {
                case Ok(_):
                    trace('ERROR: Invalid NonEmptyString "${invalidStr}" was accepted');
                case Error(reason):
                    trace('Correctly rejected "${invalidStr}": ${reason}');
            }
        }
        
        // Test parseAndTrim functionality
        var whitespaceStrings = ["  hello  ", "\tworld\n", "  test  "];
        
        for (whitespaceStr in whitespaceStrings) {
            switch (NonEmptyString.parseAndTrim(whitespaceStr)) {
                case Ok(trimmed):
                    trace('Trimmed "${whitespaceStr}" to "${trimmed.toString()}"');
                case Error(reason):
                    trace('Trim and parse failed for "${whitespaceStr}": ${reason}');
            }
        }
        
        // Test string operations
        var testStr = NonEmptyString.parse("Hello World").unwrap();
        var startsWithHello = testStr.startsWith("Hello");
        var endsWithWorld = testStr.endsWith("World");
        var containsSpace = testStr.contains(" ");
        trace('String operations - Starts with "Hello": ${startsWithHello}, Ends with "World": ${endsWithWorld}, Contains space: ${containsSpace}');
        
        // Test safe replacement
        switch (testStr.safeReplace("World", "Universe")) {
            case Ok(replaced):
                trace('Replaced "World" with "Universe": ${replaced.toString()}');
            case Error(reason):
                trace('Replacement failed: ${reason}');
        }
        
        // Test split operations
        var parts = testStr.splitNonEmpty(" ");
        trace('Split by space: ${parts.length} parts');
        for (part in parts) {
            trace('  Part: ${part.toString()}');
        }
    }
    
    /**
     * Test functional composition with domain abstractions
     */
    static function testFunctionalComposition() {
        trace("=== Functional Composition Tests ===");
        
        // Chain Email operations
        var emailChain = Email.parse("USER@EXAMPLE.COM")
            .map(email -> email.normalize())
            .map(email -> email.getDomain())
            .unwrapOr("unknown");
        trace('Email chain result: ${emailChain}');
        
        // Chain UserId operations  
        var userIdChain = UserId.parse("TestUser123")
            .map(userId -> userId.normalize())
            .filter(userId -> userId.startsWith("test"))
            .unwrapOr(UserId.parse("defaultuser").unwrap());
        trace('UserId chain result: ${userIdChain.toString()}');
        
        // Chain PositiveInt operations
        var mathChain = PositiveInt.parse(10)
            .flatMap(n -> n.safeSub(PositiveInt.parse(3).unwrap()))
            .map(n -> n * PositiveInt.parse(2).unwrap())
            .unwrapOr(PositiveInt.parse(1).unwrap());
        trace('Math chain result: ${mathChain.toString()}');
        
        // Chain NonEmptyString operations
        var stringChain = NonEmptyString.parseAndTrim("  hello world  ")
            .flatMap(s -> s.safeTrim())
            .map(s -> s.toUpperCase())
            .flatMap(s -> s.safeReplace("WORLD", "UNIVERSE"))
            .unwrapOr(NonEmptyString.parse("fallback").unwrap());
        trace('String chain result: ${stringChain.toString()}');
        
        // Complex composition example
        var compositionResult = buildUserProfile("user123", "  alice@example.com  ", "5");
        switch (compositionResult) {
            case Ok(profile):
                trace('User profile created successfully:');
                trace('  UserId: ${profile.userId.toString()}');
                trace('  Email: ${profile.email.toString()}');
                trace('  Score: ${profile.score.toString()}');
            case Error(reason):
                trace('User profile creation failed: ${reason}');
        }
    }
    
    /**
     * Test comprehensive error handling scenarios
     */
    static function testErrorHandling() {
        trace("=== Error Handling Tests ===");
        
        // Test multiple validation failures
        var invalidInputs = [
            {email: "invalid-email", userId: "ab", score: "0"},
            {email: "user@domain", userId: "user@123", score: "-5"},
            {email: "", userId: "", score: "not-a-number"}
        ];
        
        for (input in invalidInputs) {
            switch (buildUserProfile(input.userId, input.email, input.score)) {
                case Ok(_):
                    trace('ERROR: Invalid input was accepted');
                case Error(reason):
                    trace('Correctly rejected invalid input: ${reason}');
            }
        }
        
        // Test partial success scenarios
        trace("Testing edge cases that should succeed:");
        
        var edgeCases = [
            {email: "a@b.co", userId: "usr", score: "1"},
            {email: "very.long.email.address@very.long.domain.name.example.com", userId: "user123456789", score: "999"}
        ];
        
        for (edgeCase in edgeCases) {
            switch (buildUserProfile(edgeCase.userId, edgeCase.email, edgeCase.score)) {
                case Ok(profile):
                    trace('Edge case succeeded: UserId ${profile.userId.toString()}, Email ${profile.email.getDomain()}');
                case Error(reason):
                    trace('Edge case failed: ${reason}');
            }
        }
    }
    
    /**
     * Test real-world usage scenarios combining multiple abstractions
     */
    static function testRealWorldScenarios() {
        trace("=== Real-World Scenarios ===");
        
        // User registration scenario
        var registrationData = [
            {userId: "alice123", email: "alice@example.com", preferredName: "Alice Smith"},
            {userId: "bob456", email: "bob.jones@company.org", preferredName: "Bob"},
            {userId: "charlie", email: "charlie@test.dev", preferredName: "Charlie Brown"}
        ];
        
        var validUsers = [];
        
        for (userData in registrationData) {
            var userResult = createUser(userData.userId, userData.email, userData.preferredName);
            switch (userResult) {
                case Ok(user):
                    validUsers.push(user);
                    trace('User created: ${user.displayName.toString()} (${user.email.toString()})');
                case Error(reason):
                    trace('User creation failed: ${reason}');
            }
        }
        
        trace('Successfully created ${validUsers.length} users');
        
        // Configuration validation scenario
        var configData = [
            {timeout: "30", retries: "3", name: "production"},
            {timeout: "0", retries: "5", name: ""},  // Invalid: timeout 0, empty name
            {timeout: "60", retries: "-1", name: "test"}  // Invalid: negative retries
        ];
        
        for (config in configData) {
            var configResult = validateConfiguration(config.timeout, config.retries, config.name);
            switch (configResult) {
                case Ok(validConfig):
                    trace('Config valid: ${validConfig.name.toString()}, timeout: ${validConfig.timeout.toString()}s, retries: ${validConfig.retries.toString()}');
                case Error(reason):
                    trace('Config invalid: ${reason}');
            }
        }
    }
    
    /**
     * Helper function to build user profile combining multiple domain abstractions
     */
    static function buildUserProfile(userIdStr: String, emailStr: String, scoreStr: String): Result<UserProfile, String> {
        return UserId.parse(userIdStr)
            .mapError(e -> 'Invalid UserId: ${e}')
            .flatMap(userId -> {
                return Email.parse(emailStr.trim())
                    .mapError(e -> 'Invalid Email: ${e}')
                    .flatMap(email -> {
                        var scoreInt = Std.parseInt(scoreStr);
                        if (scoreInt == null) {
                            return Error('Invalid score: ${scoreStr}');
                        }
                        return PositiveInt.parse(scoreInt)
                            .mapError(e -> 'Invalid score: ${e}')
                            .map(score -> {
                                return {
                                    userId: userId,
                                    email: email,
                                    score: score
                                };
                            });
                    });
            });
    }
    
    /**
     * Helper function to create a user with validation
     */
    static function createUser(userIdStr: String, emailStr: String, nameStr: String): Result<User, String> {
        return UserId.parse(userIdStr)
            .mapError(e -> 'Invalid UserId: ${e}')
            .flatMap(userId -> {
                return Email.parse(emailStr)
                    .mapError(e -> 'Invalid Email: ${e}')
                    .flatMap(email -> {
                        return NonEmptyString.parseAndTrim(nameStr)
                            .mapError(e -> 'Invalid Name: ${e}')
                            .map(displayName -> {
                                return {
                                    userId: userId,
                                    email: email,
                                    displayName: displayName
                                };
                            });
                    });
            });
    }
    
    /**
     * Helper function to validate configuration with multiple constraints
     */
    static function validateConfiguration(timeoutStr: String, retriesStr: String, nameStr: String): Result<Configuration, String> {
        var timeoutInt = Std.parseInt(timeoutStr);
        var retriesInt = Std.parseInt(retriesStr);
        
        if (timeoutInt == null) {
            return Error('Timeout must be a number: ${timeoutStr}');
        }
        if (retriesInt == null) {
            return Error('Retries must be a number: ${retriesStr}');
        }
        
        return PositiveInt.parse(timeoutInt)
            .mapError(e -> 'Invalid timeout: ${e}')
            .flatMap(timeout -> {
                return PositiveInt.parse(retriesInt)
                    .mapError(e -> 'Invalid retries: ${e}')
                    .flatMap(retries -> {
                        return NonEmptyString.parseAndTrim(nameStr)
                            .mapError(e -> 'Invalid name: ${e}')
                            .map(name -> {
                                return {
                                    timeout: timeout,
                                    retries: retries,
                                    name: name
                                };
                            });
                    });
            });
    }
}

/**
 * Example domain types demonstrating practical usage
 */
typedef UserProfile = {
    userId: UserId,
    email: Email,
    score: PositiveInt
}

typedef User = {
    userId: UserId,
    email: Email,
    displayName: NonEmptyString
}

typedef Configuration = {
    timeout: PositiveInt,
    retries: PositiveInt,
    name: NonEmptyString
}