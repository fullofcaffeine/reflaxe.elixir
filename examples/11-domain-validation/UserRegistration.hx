import haxe.validation.Email;
import haxe.validation.UserId;
import haxe.validation.PositiveInt;
import haxe.validation.NonEmptyString;
import haxe.functional.Result;
import haxe.ds.Option;

using haxe.functional.ResultTools;
using haxe.ds.OptionTools;
using ArrayTools;

/**
 * Real-world user registration system demonstrating type-safe domain abstractions.
 * 
 * This example shows how Haxe enhances Elixir development by providing:
 * - Compile-time type safety with runtime validation
 * - Functional composition with Result/Option types
 * - Idiomatic Elixir code generation ({:ok, value} / :error patterns)
 * - Zero boilerplate validation logic
 * - LLM-friendly deterministic domain vocabulary
 */
class UserRegistration {
    
    /**
     * Main entry point demonstrating the user registration system
     */
    static function main() {
        trace("🚀 Type-Safe User Registration System");
        trace("=====================================");
        
        // Demonstrate successful user registrations
        var validUsers = [
            {userId: "alice123", email: "alice@example.com", displayName: "Alice Smith", age: "28"},
            {userId: "bob456", email: "bob.jones@company.org", displayName: "Bob Jones", age: "35"},
            {userId: "charlie", email: "charlie@startup.dev", displayName: "Charlie Brown", age: "22"}
        ];
        
        trace("✅ Valid User Registrations:");
        for (userData in validUsers) {
            switch (registerUser(userData.userId, userData.email, userData.displayName, userData.age)) {
                case Ok(user):
                    trace('  ✓ ${user.displayName.toString()} (${user.userId.toString()}) - ${user.email.toString()}');
                    
                    // Demonstrate domain-specific operations
                    var emailDomain = user.email.getDomain();
                    var isExampleDomain = user.email.hasDomain("example.com");
                    var normalizedUserId = user.userId.normalize();
                    
                    trace('    Domain: ${emailDomain}, Is example.com: ${isExampleDomain}');
                    trace('    Normalized ID: ${normalizedUserId.toString()}');
                    
                case Error(reason):
                    trace('  ✗ Registration failed: ${reason}');
            }
        }
        
        trace("");
        
        // Demonstrate validation failures
        var invalidUsers = [
            {userId: "ab", email: "invalid-email", displayName: "", age: "0"},
            {userId: "user@123", email: "user@", displayName: "   ", age: "-5"},
            {userId: "toolongusername123456789012345678901234567890", email: "test@@example.com", displayName: "Valid Name", age: "not-a-number"}
        ];
        
        trace("❌ Invalid User Registrations (showing validation):");
        for (userData in invalidUsers) {
            switch (registerUser(userData.userId, userData.email, userData.displayName, userData.age)) {
                case Ok(_):
                    trace('  ✗ ERROR: Invalid data was accepted!');
                case Error(reason):
                    trace('  ✓ Correctly rejected: ${reason}');
            }
        }
        
        trace("");
        
        // Demonstrate functional composition and bulk operations
        demonstrateBulkOperations();
        
        // Demonstrate user profile updates
        demonstrateProfileUpdates();
        
        // Demonstrate advanced domain operations
        demonstrateAdvancedOperations();
        
        trace("🎯 Registration system demonstration complete!");
    }
    
    /**
     * Core user registration function with comprehensive validation
     */
    public static function registerUser(userIdStr: String, emailStr: String, displayNameStr: String, ageStr: String): Result<RegisteredUser, String> {
        // Chain validations using functional composition
        return UserId.parse(userIdStr)
            .mapError(e -> 'Invalid User ID: ${e}')
            .flatMap(userId -> {
                return Email.parse(StringTools.trim(emailStr))
                    .mapError(e -> 'Invalid Email: ${e}')
                    .flatMap(email -> {
                        return NonEmptyString.parseAndTrim(displayNameStr)
                            .mapError(e -> 'Invalid Display Name: ${e}')
                            .flatMap(displayName -> {
                                var ageInt = Std.parseInt(ageStr);
                                if (ageInt == null) {
                                    return Error('Invalid Age: "${ageStr}" is not a number');
                                }
                                
                                return PositiveInt.parse(ageInt)
                                    .mapError(e -> 'Invalid Age: ${e}')
                                    .map(age -> {
                                        return {
                                            userId: userId,
                                            email: email,
                                            displayName: displayName,
                                            age: age,
                                            registrationDate: getCurrentDate()
                                        };
                                    });
                            });
                    });
            });
    }
    
    /**
     * Demonstrate bulk user operations with functional composition
     */
    static function demonstrateBulkOperations() {
        trace("📊 Bulk Operations with Functional Composition:");
        
        var userDataList = [
            {userId: "user001", email: "john@tech.com", displayName: "John Doe", age: "30"},
            {userId: "user002", email: "jane@design.com", displayName: "Jane Smith", age: "25"},
            {userId: "user003", email: "invalid-email", displayName: "Invalid User", age: "35"}, // This will fail
            {userId: "user004", email: "mike@startup.io", displayName: "Mike Johnson", age: "28"}
        ];
        
        // Process all registrations and collect results
        var results = userDataList.map(userData -> registerUser(userData.userId, userData.email, userData.displayName, userData.age));
        
        // Extract successful registrations
        var successfulUsers = [];
        var failedRegistrations = [];
        
        for (result in results) {
            switch (result) {
                case Ok(user):
                    successfulUsers.push(user);
                case Error(reason):
                    failedRegistrations.push(reason);
            }
        }
        
        trace('  ✓ Successful registrations: ${successfulUsers.length}');
        trace('  ✗ Failed registrations: ${failedRegistrations.length}');
        
        // Demonstrate domain-specific aggregations
        if (successfulUsers.length > 0) {
            var totalAge = successfulUsers.map(user -> user.age.toInt()).reduce((acc, age) -> acc + age, 0);
            var averageAge = totalAge / successfulUsers.length;
            trace('  📈 Average age: ${averageAge}');
            
            var domainCounts = aggregateByEmailDomain(successfulUsers);
            trace('  🌐 Email domains:');
            for (domain in domainCounts.keys()) {
                trace('    ${domain}: ${domainCounts.get(domain)} users');
            }
        }
    }
    
    /**
     * Demonstrate user profile updates with validation
     */
    static function demonstrateProfileUpdates() {
        trace("🔄 Profile Update Operations:");
        
        // Create a user to update
        var baseUser = registerUser("alice789", "alice@example.com", "Alice Cooper", "30").unwrap();
        trace('  Original: ${baseUser.displayName.toString()} (${baseUser.email.toString()})');
        
        // Demonstrate safe profile updates
        var updates = [
            {type: "email", value: "alice.cooper@newcompany.com"},
            {type: "displayName", value: "Alice Cooper-Smith"},
            {type: "email", value: "invalid-email-format"}, // This should fail
            {type: "displayName", value: ""}  // This should fail
        ];
        
        var currentUser = baseUser;
        
        for (update in updates) {
            var updateResult = switch (update.type) {
                case "email":
                    updateUserEmail(currentUser, update.value);
                case "displayName":
                    updateUserDisplayName(currentUser, update.value);
                case _:
                    Error('Unknown update type: ${update.type}');
            }
            
            switch (updateResult) {
                case Ok(updatedUser):
                    currentUser = updatedUser;
                    trace('  ✓ Updated ${update.type} to: ${update.value}');
                case Error(reason):
                    trace('  ✗ Failed to update ${update.type}: ${reason}');
            }
        }
        
        trace('  Final: ${currentUser.displayName.toString()} (${currentUser.email.toString()})');
    }
    
    /**
     * Demonstrate advanced domain operations
     */
    static function demonstrateAdvancedOperations() {
        trace("🎯 Advanced Domain Operations:");
        
        // Create some test users
        var users = [
            registerUser("admin001", "admin@company.com", "Admin User", "35").unwrap(),
            registerUser("dev123", "developer@company.com", "Developer", "28").unwrap(),
            registerUser("designer", "creative@agency.co", "Designer", "26").unwrap()
        ];
        
        // Demonstrate user filtering and search
        trace("  🔍 Search Operations:");
        
        // Find users by domain
        var companyUsers = filterUsersByDomain(users, "company.com");
        trace('    Company users: ${companyUsers.length}');
        
        // Find users by age range
        var youngUsers = filterUsersByAgeRange(users, 20, 30);
        trace('    Users aged 20-30: ${youngUsers.length}');
        
        // Find users by name pattern
        var devUsers = filterUsersByNamePattern(users, "dev");
        trace('    Users with "dev" in name: ${devUsers.length}');
        
        // Demonstrate user comparison and sorting
        trace("  📊 Comparison Operations:");
        
        for (i in 0...users.length) {
            for (j in (i + 1)...users.length) {
                var user1 = users[i];
                var user2 = users[j];
                
                var emailComparison = user1.email.getDomain() == user2.email.getDomain() ? "same domain" : "different domains";
                var ageComparison = user1.age > user2.age ? "older" : user1.age < user2.age ? "younger" : "same age";
                
                trace('    ${user1.displayName.toString()} vs ${user2.displayName.toString()}: ${emailComparison}, ${ageComparison}');
            }
        }
    }
    
    /**
     * Update user email with validation
     */
    static function updateUserEmail(user: RegisteredUser, newEmailStr: String): Result<RegisteredUser, String> {
        return Email.parse(newEmailStr)
            .mapError(e -> 'Invalid new email: ${e}')
            .map(newEmail -> {
                return {
                    userId: user.userId,
                    email: newEmail,
                    displayName: user.displayName,
                    age: user.age,
                    registrationDate: user.registrationDate
                };
            });
    }
    
    /**
     * Update user display name with validation
     */
    static function updateUserDisplayName(user: RegisteredUser, newDisplayNameStr: String): Result<RegisteredUser, String> {
        return NonEmptyString.parseAndTrim(newDisplayNameStr)
            .mapError(e -> 'Invalid new display name: ${e}')
            .map(newDisplayName -> {
                return {
                    userId: user.userId,
                    email: user.email,
                    displayName: newDisplayName,
                    age: user.age,
                    registrationDate: user.registrationDate
                };
            });
    }
    
    /**
     * Aggregate users by email domain
     */
    public static function aggregateByEmailDomain(users: Array<RegisteredUser>): Map<String, Int> {
        var domainCounts = new Map<String, Int>();
        
        for (user in users) {
            var domain = user.email.getDomain();
            var currentCount = domainCounts.exists(domain) ? domainCounts.get(domain) : 0;
            domainCounts.set(domain, currentCount + 1);
        }
        
        return domainCounts;
    }
    
    /**
     * Filter users by email domain
     */
    static function filterUsersByDomain(users: Array<RegisteredUser>, domain: String): Array<RegisteredUser> {
        return users.filter(user -> user.email.hasDomain(domain));
    }
    
    /**
     * Filter users by age range (inclusive)
     */
    static function filterUsersByAgeRange(users: Array<RegisteredUser>, minAge: Int, maxAge: Int): Array<RegisteredUser> {
        return users.filter(user -> {
            var age = user.age.toInt();
            return age >= minAge && age <= maxAge;
        });
    }
    
    /**
     * Filter users by name pattern (case-insensitive)
     */
    static function filterUsersByNamePattern(users: Array<RegisteredUser>, pattern: String): Array<RegisteredUser> {
        return users.filter(user -> {
            var name = user.displayName.toString().toLowerCase();
            var searchPattern = pattern.toLowerCase();
            return name.indexOf(searchPattern) != -1;
        });
    }
    
    /**
     * Get current date (simplified for demo)
     */
    static function getCurrentDate(): NonEmptyString {
        return NonEmptyString.parse("2025-08-16").unwrap(); // Simplified for demo
    }
}

/**
 * Domain type representing a fully validated registered user
 */
typedef RegisteredUser = {
    userId: UserId,
    email: Email,
    displayName: NonEmptyString,
    age: PositiveInt,
    registrationDate: NonEmptyString
}

typedef UserBatchRow = {
    var userId: String;
    var email: String;
    var displayName: String;
    var age: String;
}

/**
 * Service class demonstrating business logic with domain abstractions
 */
class UserService {
    
    /**
     * Validate and normalize user input for batch processing
     */
    public static function validateUserBatch(userData: Array<UserBatchRow>): Result<Array<RegisteredUser>, Array<String>> {
        var validUsers: Array<RegisteredUser> = [];
        var errors: Array<String> = [];
        
        for (i in 0...userData.length) {
            var data = userData[i];
            switch (UserRegistration.registerUser(data.userId, data.email, data.displayName, data.age)) {
                case Ok(user):
                    validUsers.push(user);
                case Error(reason):
                    errors.push('Row ${i + 1}: ${reason}');
            }
        }
        
        return errors.length > 0 ? Error(errors) : Ok(validUsers);
    }
    
    /**
     * Generate user statistics with type-safe aggregations
     */
    public static function generateUserStats(users: Array<RegisteredUser>): UserStatistics {
        if (users.length == 0) {
            return {
                totalUsers: PositiveInt.parse(1).unwrap(), // At least 1 for division safety
                averageAge: PositiveInt.parse(1).unwrap(),
                mostCommonDomain: NonEmptyString.parse("unknown").unwrap(),
                oldestUser: NonEmptyString.parse("unknown").unwrap(),
                youngestUser: NonEmptyString.parse("unknown").unwrap()
            };
        }
        
        var totalUsers = PositiveInt.parse(users.length).unwrap();
        
        // Calculate average age
        var totalAge = users.map(user -> user.age.toInt()).reduce((acc, age) -> acc + age, 0);
        var averageAge = PositiveInt.parse(Math.round(totalAge / users.length)).unwrap();
        
        // Find most common domain
        var domainCounts = UserRegistration.aggregateByEmailDomain(users);
        var mostCommonDomain = "unknown";
        var maxCount = 0;
        
        for (domain in domainCounts.keys()) {
            var count = domainCounts.get(domain);
            if (count > maxCount) {
                maxCount = count;
                mostCommonDomain = domain;
            }
        }
        
        // Find oldest and youngest users
        var oldestUser = users[0];
        var youngestUser = users[0];
        
        for (user in users) {
            if (user.age > oldestUser.age) {
                oldestUser = user;
            }
            if (user.age < youngestUser.age) {
                youngestUser = user;
            }
        }
        
        return {
            totalUsers: totalUsers,
            averageAge: averageAge,
            mostCommonDomain: NonEmptyString.parse(mostCommonDomain).unwrap(),
            oldestUser: oldestUser.displayName,
            youngestUser: youngestUser.displayName
        };
    }
}

/**
 * Statistics aggregation demonstrating complex domain operations
 */
typedef UserStatistics = {
    totalUsers: PositiveInt,
    averageAge: PositiveInt,
    mostCommonDomain: NonEmptyString,
    oldestUser: NonEmptyString,
    youngestUser: NonEmptyString
}
