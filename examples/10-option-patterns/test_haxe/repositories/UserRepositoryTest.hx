package repositories;

import haxe.test.ExUnit.TestCase;
import haxe.test.Assert;
import haxe.ds.Option;
import haxe.functional.Result;
import models.User;
import repositories.UserRepository;

using haxe.ds.OptionTools;
using haxe.functional.Result.ResultTools;

/**
 * ExUnit tests for UserRepository demonstrating Option<T> testing patterns.
 * 
 * This test class shows how to write type-safe tests for Option and Result types,
 * verifying that the repository correctly handles null safety and error conditions.
 */
@:exunit
class UserRepositoryTest extends TestCase {
    
    @:test
    function findReturnsOptionForValidId() {
        var user = UserRepository.find(1);
        Assert.isSome(user, "Should find user with ID 1");
        
        switch(user) {
            case Some(u): 
                Assert.equals("Alice Johnson", u.name, "Should have correct name");
                Assert.equals("alice@example.com", u.email, "Should have correct email");
                Assert.isTrue(u.active, "Should be active");
            case None: 
                Assert.fail("Expected to find user with ID 1");
        }
    }
    
    @:test
    function findReturnsNoneForInvalidId() {
        var user = UserRepository.find(999);
        Assert.isNone(user, "Should not find user with invalid ID");
    }
    
    @:test
    function findReturnsNoneForNegativeId() {
        var user = UserRepository.find(-1);
        Assert.isNone(user, "Should not find user with negative ID");
    }
    
    @:test
    function findReturnsNoneForZeroId() {
        var user = UserRepository.find(0);
        Assert.isNone(user, "Should not find user with zero ID");
    }
    
    @:test
    function findByEmailReturnsOptionForValidEmail() {
        var user = UserRepository.findByEmail("bob@example.com");
        Assert.isSome(user, "Should find user with valid email");
        
        switch(user) {
            case Some(u): 
                Assert.equals(2, u.id, "Should have correct ID");
                Assert.equals("Bob Smith", u.name, "Should have correct name");
            case None: 
                Assert.fail("Expected to find user with email bob@example.com");
        }
    }
    
    @:test
    function findByEmailReturnsNoneForInvalidEmail() {
        var user = UserRepository.findByEmail("nonexistent@example.com");
        Assert.isNone(user, "Should not find user with invalid email");
    }
    
    @:test
    function findByEmailReturnsNoneForEmptyEmail() {
        var user = UserRepository.findByEmail("");
        Assert.isNone(user, "Should not find user with empty email");
    }
    
    @:test
    function findByEmailReturnsNoneForNullEmail() {
        var user = UserRepository.findByEmail(null);
        Assert.isNone(user, "Should not find user with null email");
    }
    
    @:test
    function findFirstActiveReturnsActiveUser() {
        var user = UserRepository.findFirstActive();
        Assert.isSome(user, "Should find an active user");
        
        switch(user) {
            case Some(u): 
                Assert.isTrue(u.active, "Found user should be active");
            case None: 
                Assert.fail("Expected to find an active user");
        }
    }
    
    @:test
    function getUserEmailReturnsEmailForValidUser() {
        var email = UserRepository.getUserEmail(1);
        Assert.isSome(email, "Should get email for valid user");
        Assert.equals(Some("alice@example.com"), email, "Should have correct email");
    }
    
    @:test
    function getUserEmailReturnsNoneForInvalidUser() {
        var email = UserRepository.getUserEmail(999);
        Assert.isNone(email, "Should not get email for invalid user");
    }
    
    @:test
    function getUserDisplayNameReturnsNameForValidUser() {
        var displayName = UserRepository.getUserDisplayName(1);
        Assert.equals("Alice Johnson", displayName, "Should return user's display name");
    }
    
    @:test
    function getUserDisplayNameReturnsFallbackForInvalidUser() {
        var displayName = UserRepository.getUserDisplayName(999);
        Assert.equals("Unknown User", displayName, "Should return fallback for invalid user");
    }
    
    @:test
    function isUserActiveReturnsTrueForActiveUser() {
        var isActive = UserRepository.isUserActive(1);
        Assert.isTrue(isActive, "User 1 should be active");
    }
    
    @:test
    function isUserActiveReturnsFalseForInactiveUser() {
        var isActive = UserRepository.isUserActive(3);
        Assert.isFalse(isActive, "User 3 should be inactive");
    }
    
    @:test
    function isUserActiveReturnsFalseForInvalidUser() {
        var isActive = UserRepository.isUserActive(999);
        Assert.isFalse(isActive, "Invalid user should return false");
    }
    
    @:test
    function updateEmailSucceedsForValidUser() {
        var result = UserRepository.updateEmail(1, "newalice@example.com");
        Assert.isOk(result, "Should successfully update email for valid user");
        
        switch(result) {
            case Ok(user): 
                Assert.equals("newalice@example.com", user.email, "Should have updated email");
            case Error(msg): 
                Assert.fail('Unexpected error: ${msg}');
        }
    }
    
    @:test
    function updateEmailFailsForInvalidUser() {
        var result = UserRepository.updateEmail(999, "test@example.com");
        Assert.isError(result, "Should fail to update email for invalid user");
        
        switch(result) {
            case Error(msg): 
                Assert.equals("User not found", msg, "Should have correct error message");
            case Ok(_): 
                Assert.fail("Expected error for invalid user");
        }
    }
    
    @:test
    function updateEmailFailsForInvalidEmailFormat() {
        var result = UserRepository.updateEmail(1, "invalid-email");
        Assert.isError(result, "Should fail for invalid email format");
        
        switch(result) {
            case Error(msg): 
                Assert.equals("Invalid email format", msg, "Should have correct error message");
            case Ok(_): 
                Assert.fail("Expected error for invalid email");
        }
    }
    
    @:test
    function getUsersByStatusReturnsActiveUsers() {
        var activeUsers = UserRepository.getUsersByStatus(true);
        Assert.isTrue(activeUsers.length >= 3, "Should have at least 3 active users");
        
        for (user in activeUsers) {
            Assert.isTrue(user.active, "All returned users should be active");
        }
    }
    
    @:test
    function getUsersByStatusReturnsInactiveUsers() {
        var inactiveUsers = UserRepository.getUsersByStatus(false);
        Assert.isTrue(inactiveUsers.length >= 1, "Should have at least 1 inactive user");
        
        for (user in inactiveUsers) {
            Assert.isFalse(user.active, "All returned users should be inactive");
        }
    }
    
    @:test
    function createSucceedsForValidData() {
        var result = UserRepository.create("Test User", "test@example.com");
        Assert.isOk(result, "Should successfully create user with valid data");
        
        switch(result) {
            case Ok(user): 
                Assert.equals("Test User", user.name, "Should have correct name");
                Assert.equals("test@example.com", user.email, "Should have correct email");
                Assert.isTrue(user.active, "New user should be active");
            case Error(msg): 
                Assert.fail('Unexpected error: ${msg}');
        }
    }
    
    @:test
    function createFailsForEmptyName() {
        var result = UserRepository.create("", "test@example.com");
        Assert.isError(result, "Should fail for empty name");
        
        switch(result) {
            case Error(msg): 
                Assert.equals("Name is required", msg, "Should have correct error message");
            case Ok(_): 
                Assert.fail("Expected error for empty name");
        }
    }
    
    @:test
    function createFailsForInvalidEmail() {
        var result = UserRepository.create("Test User", "invalid-email");
        Assert.isError(result, "Should fail for invalid email");
        
        switch(result) {
            case Error(msg): 
                Assert.equals("Valid email is required", msg, "Should have correct error message");
            case Ok(_): 
                Assert.fail("Expected error for invalid email");
        }
    }
    
    @:test
    function createFailsForDuplicateEmail() {
        var result = UserRepository.create("Test User", "alice@example.com");
        Assert.isError(result, "Should fail for duplicate email");
        
        switch(result) {
            case Error(msg): 
                Assert.equals("Email already exists", msg, "Should have correct error message");
            case Ok(_): 
                Assert.fail("Expected error for duplicate email");
        }
    }
}