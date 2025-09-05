package;

import exunit.TestCase;
import exunit.Assert.*;
import haxe.validation.Email;
import haxe.validation.UserId;
import haxe.validation.PositiveInt;
import haxe.validation.NonEmptyString;
import haxe.functional.Result;
import haxe.ds.Option;

using haxe.functional.ResultTools;
using haxe.ds.OptionTools;

/**
 * Comprehensive ExUnit tests for domain abstractions.
 * 
 * This test suite validates that our domain abstractions:
 * - Compile to proper Elixir ExUnit tests
 * - Provide type-safe validation and operations
 * - Generate idiomatic Elixir code with proper pattern matching
 * - Work correctly with Result and Option types
 * 
 * These tests are written in Haxe and compile to ExUnit tests,
 * maintaining the "write once in Haxe" philosophy.
 */
@:exunit
class Main extends TestCase {
    
    /**
     * Test Email domain abstraction validation and operations.
     */
    @:test
    function testEmailValidation() {
        // Test valid email parsing
        var validEmail = Email.parse("user@example.com");
        assertIsOk(validEmail, "Valid email should parse successfully");
        
        switch (validEmail) {
            case Ok(email):
                assertEqual("example.com", email.getDomain(), "Domain extraction should work");
                assertEqual("user", email.getLocalPart(), "Local part extraction should work");
                assertTrue(email.hasDomain("example.com"), "Domain check should return true");
                assertFalse(email.hasDomain("other.com"), "Domain check should return false for different domain");
                
                // Test email normalization
                var normalized = email.normalize();
                assertEqual("user@example.com", normalized.toString(), "Normalization should lowercase");
                
            case Error(reason):
                fail("Valid email should not fail: " + reason);
        }
        
        // Test invalid email rejection
        var invalidEmail = Email.parse("not-an-email");
        assertIsError(invalidEmail, "Invalid email should be rejected");
        
        // Test empty email rejection
        var emptyEmail = Email.parse("");
        assertIsError(emptyEmail, "Empty email should be rejected");
    }
    
    /**
     * Test UserId domain abstraction normalization and operations.
     */
    @:test
    function testUserIdValidation() {
        // Test valid user ID parsing
        var userId = UserId.parse("User123");
        assertIsOk(userId, "Valid user ID should parse");
        
        switch (userId) {
            case Ok(id):
                assertEqual("user123", id.normalize().toString(), "User ID should normalize to lowercase");
                assertTrue(id.startsWith("User"), "User ID should support startsWith check");
                assertTrue(id.startsWithIgnoreCase("user"), "User ID should support case-insensitive startsWith");
                assertEqual(7, id.length(), "User ID length should be preserved");
                
            case Error(reason):
                fail("Valid user ID should not fail: " + reason);
        }
        
        // Test invalid user ID rejection (empty)
        var emptyUserId = UserId.parse("");
        assertIsError(emptyUserId, "Empty user ID should be rejected");
        
        // Test invalid user ID rejection (special characters)
        var invalidUserId = UserId.parse("user@123");
        assertIsError(invalidUserId, "User ID with special characters should be rejected");
    }
    
    /**
     * Test PositiveInt domain abstraction arithmetic operations.
     */
    @:test
    function testPositiveIntArithmetic() {
        // Test valid positive int parsing
        var pos1 = PositiveInt.parse(5);
        var pos2 = PositiveInt.parse(3);
        
        assertIsOk(pos1, "Positive integer 5 should parse");
        assertIsOk(pos2, "Positive integer 3 should parse");
        
        switch ([pos1, pos2]) {
            case [Ok(a), Ok(b)]:
                // Test addition (always safe for positive integers)
                var sum = a.add(b);
                assertEqual(8, sum.toInt(), "5 + 3 should equal 8");
                
                // Test multiplication (always safe for positive integers)
                var product = a.multiply(b);
                assertEqual(15, product.toInt(), "5 * 3 should equal 15");
                
                // Test safe subtraction (returns Result)
                var diff = a.safeSub(b);
                assertIsOk(diff, "5 - 3 should succeed");
                switch (diff) {
                    case Ok(result):
                        assertEqual(2, result.toInt(), "5 - 3 should equal 2");
                    case Error(reason):
                        fail("Subtraction should not fail: " + reason);
                }
                
                // Test subtraction that would result in non-positive
                var invalidDiff = b.safeSub(a);
                assertIsError(invalidDiff, "3 - 5 should fail (non-positive result)");
                
            case _:
                fail("Valid positive integers should parse");
        }
        
        // Test invalid positive int rejection (zero)
        var zero = PositiveInt.parse(0);
        assertIsError(zero, "Zero should be rejected");
        
        // Test invalid positive int rejection (negative)
        var negative = PositiveInt.parse(-5);
        assertIsError(negative, "Negative number should be rejected");
    }
    
    /**
     * Test NonEmptyString domain abstraction operations.
     */
    @:test
    function testNonEmptyStringOperations() {
        // Test valid non-empty string parsing
        var str = NonEmptyString.parse("  hello world  ");
        assertIsOk(str, "Non-empty string should parse");
        
        switch (str) {
            case Ok(s):
                // Test safe trim operation
                var trimmed = s.safeTrim();
                assertIsOk(trimmed, "Trimming non-empty content should succeed");
                switch (trimmed) {
                    case Ok(trimmedStr):
                        assertEqual("hello world", trimmedStr.toString(), "Trim should remove whitespace");
                    case Error(reason):
                        fail("Trim should not fail: " + reason);
                }
                
                // Test case conversions (always safe)
                var upper = s.toUpperCase();
                assertEqual("  HELLO WORLD  ", upper.toString(), "toUpperCase should work");
                
                var lower = s.toLowerCase();
                assertEqual("  hello world  ", lower.toString(), "toLowerCase should work");
                
                // Test length
                assertEqual(15, s.length(), "Length should be preserved");
                
            case Error(reason):
                fail("Valid non-empty string should not fail: " + reason);
        }
        
        // Test empty string rejection
        var empty = NonEmptyString.parse("");
        assertIsError(empty, "Empty string should be rejected");
        
        // Test whitespace-only string handling
        var whitespaceOnly = NonEmptyString.parse("   ");
        assertIsOk(whitespaceOnly, "Whitespace-only string should parse");
        switch (whitespaceOnly) {
            case Ok(ws):
                var trimmed = ws.safeTrim();
                assertIsError(trimmed, "Trimming whitespace-only should fail");
            case Error(_):
                fail("Whitespace-only should parse");
        }
    }
    
    /**
     * Test functional composition with Result chaining.
     */
    @:test
    function testResultChaining() {
        // Test successful email domain extraction chain
        var domainResult = Email.parse("test@example.com")
            .map(email -> email.getDomain())
            .filter(domain -> domain == "example.com", "Wrong domain");
        
        assertIsOk(domainResult, "Email domain chain should succeed");
        switch (domainResult) {
            case Ok(domain):
                assertEqual("example.com", domain, "Domain should be extracted correctly");
            case Error(reason):
                fail("Domain extraction should not fail: " + reason);
        }
        
        // Test failed filter in chain
        var failedFilter = Email.parse("test@wrong.com")
            .map(email -> email.getDomain())
            .filter(domain -> domain == "example.com", "Wrong domain");
        
        assertIsError(failedFilter, "Filter should reject wrong domain");
    }
    
    /**
     * Test Option conversion and operations.
     */
    @:test
    function testOptionConversion() {
        // Test converting Result to Option
        var emailResult = Email.parse("user@example.com");
        var emailOption = emailResult.toOption();
        
        assertIsSome(emailOption, "Valid email should convert to Some");
        
        switch (emailOption) {
            case Some(email):
                assertEqual("example.com", email.getDomain(), "Option content should be preserved");
            case None:
                fail("Valid email should not be None");
        }
        
        // Test failed Result to None conversion
        var invalidEmailResult = Email.parse("invalid");
        var invalidEmailOption = invalidEmailResult.toOption();
        
        assertIsNone(invalidEmailOption, "Invalid email should convert to None");
    }
    
    /**
     * Test error handling and edge cases.
     */
    @:test
    function testErrorHandling() {
        // Test that validation errors provide meaningful messages
        var invalidEmail = Email.parse("invalid-email");
        switch (invalidEmail) {
            case Ok(_):
                fail("Invalid email should not parse");
            case Error(message):
                assertTrue(message.indexOf("Invalid email") >= 0, "Error message should be descriptive");
        }
        
        // Test arithmetic with large numbers
        var largeInt = PositiveInt.parse(1000000);
        assertIsOk(largeInt, "Large positive integer should parse");
        
        switch (largeInt) {
            case Ok(large):
                var doubled = large.multiply(large);
                assertTrue(doubled.toInt() > 0, "Large multiplication should remain positive");
            case Error(_):
                fail("Large integer should parse");
        }
    }
    
    /**
     * Test real-world composition scenario.
     */
    @:test
    function testRealWorldScenario() {
        // Simulate processing user registration data
        var userEmail = Email.parse("john.doe@company.com");
        var userId = UserId.parse("johndoe123");
        var userAge = PositiveInt.parse(25);
        var userName = NonEmptyString.parse("John Doe");
        
        // All should parse successfully
        assertIsOk(userEmail, "User email should be valid");
        assertIsOk(userId, "User ID should be valid");
        assertIsOk(userAge, "User age should be valid");
        assertIsOk(userName, "User name should be valid");
        
        // Test composition of successful results
        switch ([userEmail, userId, userAge, userName]) {
            case [Ok(email), Ok(id), Ok(age), Ok(name)]:
                // Simulate user profile creation
                var profile = {
                    email: email.toString(),
                    normalizedId: id.normalize().toString(),
                    isCompanyEmail: email.hasDomain("company.com"),
                    ageInMonths: age.toInt() * 12,
                    displayName: name.toString()
                };
                
                assertEqual("john.doe@company.com", profile.email, "Email should be preserved");
                assertEqual("johndoe123", profile.normalizedId, "ID should be normalized");
                assertTrue(profile.isCompanyEmail, "Company email should be detected");
                assertEqual("John Doe", profile.displayName, "Name should be preserved");
                
            case _:
                fail("All user data should be valid");
        }
    }
}