import haxe.ds.Option;
import haxe.ds.OptionTools;
import haxe.functional.Result;
import models.User;
import repositories.UserRepository;
import services.ConfigManager;
import services.NotificationService;

using haxe.ds.OptionTools;
using haxe.functional.ResultTools;

/**
 * Main demonstration of Option<T> patterns in real-world scenarios.
 * 
 * This class showcases how Option<T> and Result<T,E> types work together
 * to create robust, type-safe applications that eliminate null pointer exceptions.
 */
class Main {
    public static function main() {
        trace("=== Option<T> Patterns Demo ===\n");
        
        demonstrateRepositoryPatterns();
        demonstrateConfigurationManagement();
        demonstrateNotificationService();
        demonstrateErrorHandling();
        demonstrateFunctionalComposition();
        
        trace("\n=== Demo Complete ===");
        trace("All operations completed without null pointer exceptions!");
    }
    
    /**
     * Demonstrate safe repository access patterns.
     */
    static function demonstrateRepositoryPatterns() {
        trace("1. Repository Patterns with Option<T>");
        trace("=====================================");
        
        // Safe user lookup - no null checks needed
        var user = UserRepository.find(1);
        switch (user) {
            case Some(u): trace('Found user: ${u.getDisplayName()}');
            case None: trace("User not found");
        }
        
        // Chain operations safely
        var emailDisplay = UserRepository.find(2)
            .map(u -> u.email)
            .map(email -> 'Email: ${email}')
            .unwrap("No email available");
        trace(emailDisplay);
        
        // Find with fallback
        var displayName = UserRepository.getUserDisplayName(999);
        trace('Display name: ${displayName}'); // Will be "Unknown User"
        
        // Check user status safely
        var isActive = UserRepository.isUserActive(3);
        trace('User 3 is active: ${isActive}');
        
        trace("");
    }
    
    /**
     * Demonstrate configuration management with defaults and validation.
     */
    static function demonstrateConfigurationManagement() {
        trace("2. Configuration Management");
        trace("===========================");
        
        // Get config with default
        var appName = ConfigManager.getWithDefault("app_name", "DefaultApp");
        trace('App name: ${appName}');
        
        // Safe integer parsing
        var timeout = ConfigManager.getInt("timeout").unwrap(30);
        trace('Timeout: ${timeout}s');
        
        // Boolean config with fallback
        var debugMode = ConfigManager.isDebugEnabled();
        trace('Debug mode: ${debugMode}');
        
        // Validation with range checking
        switch (ConfigManager.getIntWithRange("max_connections", 1, 1000)) {
            case Ok(value): trace('Max connections: ${value}');
            case Error(msg): trace('Config error: ${msg}');
        }
        
        // Required configuration
        switch (ConfigManager.getDatabaseUrl()) {
            case Ok(url): trace('Database URL validated successfully');
            case Error(msg): trace('Database config error: ${msg}');
        }
        
        trace("");
    }
    
    /**
     * Demonstrate notification service with complex business logic.
     */
    static function demonstrateNotificationService() {
        trace("3. Notification Service Integration");
        trace("==================================");
        
        // Send notification with full validation chain
        switch (NotificationService.sendToUser(1, "Welcome to our service!", Email)) {
            case Ok(record): trace('Notification sent successfully to user ${record.userId}');
            case Error(reason): trace('Failed to send notification: ${reason}');
        }
        
        // Send to inactive user (should fail)
        switch (NotificationService.sendToUser(3, "Test message", Email)) {
            case Ok(record): trace("Unexpected success");
            case Error(reason): trace('Expected failure: ${reason}');
        }
        
        // Email-based lookup and send
        switch (NotificationService.sendToEmail("alice@example.com", "Email notification", Email)) {
            case Ok(record): trace('Email notification sent successfully');
            case Error(reason): trace('Email send failed: ${reason}');
        }
        
        // Check notification preferences
        var prefsAllowed = NotificationService.isNotificationAllowed(1, Push);
        trace('User 1 allows push notifications: ${prefsAllowed}');
        
        // Bulk notifications
        var bulkResult = NotificationService.sendBulk([1, 2, 3, 4], "Bulk message", Email);
        trace('Bulk send: ${bulkResult.getSuccessCount()}/${bulkResult.getTotalCount()} successful');
        
        trace("");
    }
    
    /**
     * Demonstrate error handling patterns with Option and Result.
     */
    static function demonstrateErrorHandling() {
        trace("4. Error Handling Patterns");
        trace("==========================");
        
        // Option to Result conversion
        var userResult = UserRepository.find(999)
            .toResult("User 999 not found")
            .flatMap(user -> {
                if (!user.hasValidEmail()) {
                    return Error("User has invalid email");
                }
                return Ok(user);
            });
            
        switch (userResult) {
            case Ok(user): trace('User validated: ${user.email}');
            case Error(msg): trace('Validation failed: ${msg}');
        }
        
        // Result to Option conversion
        var createResult = UserRepository.create("New User", "new@example.com");
        var userOption = createResult.toOption();
        switch (userOption) {
            case Some(user): trace('Created user: ${user.name}');
            case None: trace("User creation failed");
        }
        
        // Chaining validations
        var validationChain = ConfigManager.getRequired("timeout")
            .flatMap(timeoutStr -> {
                var timeout = Std.parseInt(timeoutStr);
                return timeout != null ? Ok(timeout) : Error("Invalid timeout format");
            })
            .flatMap(timeout -> {
                if (timeout < 1 || timeout > 300) {
                    return Error("Timeout must be between 1 and 300 seconds");
                }
                return Ok(timeout);
            });
            
        switch (validationChain) {
            case Ok(timeout): trace('Validated timeout: ${timeout}s');
            case Error(msg): trace('Validation error: ${msg}');
        }
        
        trace("");
    }
    
    /**
     * Demonstrate functional composition patterns.
     */
    static function demonstrateFunctionalComposition() {
        trace("5. Functional Composition");
        trace("=========================");
        
        // Complex chaining example
        var composedOperation = UserRepository.find(1)
            .flatMap(user -> {
                // Only proceed if user is active
                return user.active ? Some(user) : None;
            })
            .map(user -> user.email)
            .flatMap(email -> {
                // Validate email format
                return email.indexOf("@") > 0 ? Some(email) : None;
            })
            .map(email -> email.toUpperCase());
            
        switch (composedOperation) {
            case Some(result): trace('Composed result: ${result}');
            case None: trace("Composition chain failed at some point");
        }
        
        // Working with arrays of Options
        var userIds = [1, 2, 999, 4];
        var validUsers = [];
        
        for (id in userIds) {
            switch (UserRepository.find(id)) {
                case Some(user): validUsers.push(user);
                case None: // Skip invalid users
            }
        }
        
        trace('Found ${validUsers.length}/${userIds.length} valid users');
        
        // Map over array with Option handling
        var userEmails = [];
        for (id in userIds) {
            var email = UserRepository.getUserEmail(id);
            switch (email) {
                case Some(e): userEmails.push(e);
                case None: userEmails.push("no-email");
            }
        }
        
        trace('User emails: ${userEmails.join(", ")}');
        
        // Filter and transform
        var activeUserNames = [];
        for (id in userIds) {
            UserRepository.find(id)
                .filter(user -> user.active)
                .map(user -> user.name)
                .apply(name -> activeUserNames.push(name));
        }
        
        trace('Active user names: ${activeUserNames.join(", ")}');
        
        trace("");
    }
}
