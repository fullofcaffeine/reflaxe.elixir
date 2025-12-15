package services;

import haxe.ds.Option;
import haxe.ds.OptionTools;
import haxe.functional.Result;
import models.User;
import repositories.UserRepository;

using haxe.ds.OptionTools;
using haxe.functional.ResultTools;

/**
 * Notification service demonstrating advanced Option<T> and Result<T,E> patterns.
 * 
 * This service shows real-world business logic that combines Option and Result types
 * for robust error handling and null safety in notification operations.
 * 
 * Key patterns demonstrated:
 * - Option<T> and Result<T,E> composition in business logic
 * - Safe service integration with external dependencies
 * - Error accumulation and validation chains
 * - Type-safe notification preferences and delivery
 */
class NotificationService {
    // Simulated notification preferences and delivery log
    static var preferences: Map<Int, NotificationPreferences> = [
        1 => new NotificationPreferences(true, true, false),
        2 => new NotificationPreferences(true, false, true),
        3 => new NotificationPreferences(false, false, false),
        4 => new NotificationPreferences(true, true, true)
    ];
    
    static var deliveryLog: Array<NotificationRecord> = [];
    
    /**
     * Send a notification to a user by ID.
     * 
     * Demonstrates chaining Option and Result operations for complex business logic.
     * 
     * @param userId Target user ID
     * @param message Notification message
     * @param type Type of notification (email, sms, push)
     * @return Ok(record) if sent successfully, Error(reason) if failed
     */
    public static function sendToUser(userId: Int, message: String, type: NotificationType): Result<NotificationRecord, String> {
        if (message == null || message.length == 0) {
            return Error("Message cannot be empty");
        }
        
        return UserRepository.find(userId)
            .toResult("User not found")
            .flatMap(user -> {
                if (!user.active) {
                    return Error("Cannot send notifications to inactive users");
                }
                return Ok(user);
            })
            .flatMap(user -> checkUserPreferences(user.id, type))
            .flatMap(user -> deliverNotification(user, message, type));
    }
    
    /**
     * Send a notification to a user by email address.
     * 
     * Shows email-based lookup with Option/Result integration.
     * 
     * @param email Target email address
     * @param message Notification message
     * @param type Type of notification
     * @return Ok(record) if sent successfully, Error(reason) if failed
     */
    public static function sendToEmail(email: String, message: String, type: NotificationType): Result<NotificationRecord, String> {
        return UserRepository.findByEmail(email)
            .toResult("No user found with email: " + email)
            .flatMap(user -> sendToUser(user.id, message, type));
    }
    
    /**
     * Get user notification preferences safely.
     * 
     * Demonstrates Option return for nullable preference data.
     * 
     * @param userId User ID
     * @return Some(preferences) if set, None if not configured
     */
    public static function getUserPreferences(userId: Int): Option<NotificationPreferences> {
        var prefs = preferences.get(userId);
        return prefs != null ? Some(prefs) : None;
    }
    
    /**
     * Check if user allows a specific notification type.
     * 
     * Shows Option chaining with boolean logic and defaults.
     * 
     * @param userId User ID
     * @param type Notification type to check
     * @return True if allowed (or no preferences set), false if explicitly disabled
     */
    public static function isNotificationAllowed(userId: Int, type: NotificationType): Bool {
        return getUserPreferences(userId)
            .map(prefs -> prefs.isAllowed(type))
            .unwrap(true); // Default to allowed if no preferences set
    }
    
    /**
     * Bulk send notifications to multiple users.
     * 
     * Demonstrates processing arrays with Option/Result accumulation.
     * 
     * @param userIds Array of user IDs
     * @param message Notification message
     * @param type Notification type
     * @return Result with success count and failure details
     */
    public static function sendBulk(userIds: Array<Int>, message: String, type: NotificationType): BulkNotificationResult {
        var successful = [];
        var failed = [];
        
        for (userId in userIds) {
            switch (sendToUser(userId, message, type)) {
                case Ok(record): 
                    successful.push(record);
                case Error(reason): 
                    failed.push({userId: userId, reason: reason});
            }
        }
        
        return new BulkNotificationResult(successful, failed);
    }
    
    /**
     * Get notification history for a user.
     * 
     * Shows filtering with Option integration.
     * 
     * @param userId User ID
     * @return Array of notification records for the user
     */
    public static function getUserNotificationHistory(userId: Int): Array<NotificationRecord> {
        var result = [];
        for (record in deliveryLog) {
            if (record.userId == userId) {
                result.push(record);
            }
        }
        return result;
    }
    
    /**
     * Get the most recent notification for a user.
     * 
     * Demonstrates Option return for potentially missing data.
     * 
     * @param userId User ID
     * @return Some(record) if user has notifications, None otherwise
     */
    public static function getMostRecentNotification(userId: Int): Option<NotificationRecord> {
        var userNotifications = getUserNotificationHistory(userId);
        if (userNotifications.length == 0) {
            return None;
        }
        
        // Find most recent (highest timestamp)
        var mostRecent = userNotifications[0];
        for (i in 1...userNotifications.length) {
            if (userNotifications[i].timestamp > mostRecent.timestamp) {
                mostRecent = userNotifications[i];
            }
        }
        
        return Some(mostRecent);
    }
    
    /**
     * Set user notification preferences.
     * 
     * Shows Result return for operations that can fail validation.
     * 
     * @param userId User ID
     * @param emailEnabled Whether email notifications are enabled
     * @param smsEnabled Whether SMS notifications are enabled
     * @param pushEnabled Whether push notifications are enabled
     * @return Ok(preferences) if set successfully, Error(reason) if failed
     */
    public static function setUserPreferences(userId: Int, emailEnabled: Bool, smsEnabled: Bool, pushEnabled: Bool): Result<NotificationPreferences, String> {
        return UserRepository.find(userId)
            .toResult("User not found")
            .map(user -> {
                var prefs = new NotificationPreferences(emailEnabled, smsEnabled, pushEnabled);
                preferences.set(userId, prefs);
                return prefs;
            });
    }
    
    // Private helper methods
    
    /**
     * Check user preferences for notification type.
     * 
     * Internal helper showing Option/Result integration.
     */
    static function checkUserPreferences(userId: Int, type: NotificationType): Result<User, String> {
        if (!isNotificationAllowed(userId, type)) {
            return Error('User has disabled ${type} notifications');
        }
        
        return UserRepository.find(userId).toResult("User not found during preference check");
    }
    
    /**
     * Actually deliver the notification.
     * 
     * Simulates external service integration with error handling.
     */
    static function deliverNotification(user: User, message: String, type: NotificationType): Result<NotificationRecord, String> {
        // Simulate delivery validation
        if (!user.hasValidEmail() && type == Email) {
            return Error("User has invalid email address");
        }
        
        // Simulate external service call that might fail
        if (message.indexOf("FAIL") >= 0) {
            return Error("Simulated delivery failure");
        }
        
        // Create delivery record
        var record = new NotificationRecord(
            user.id,
            message,
            type,
            Sys.time(),
            true
        );
        
        deliveryLog.push(record);
        return Ok(record);
    }
}

/**
 * Notification preferences data structure.
 */
class NotificationPreferences {
    public var emailEnabled: Bool;
    public var smsEnabled: Bool;
    public var pushEnabled: Bool;
    
    public function new(emailEnabled: Bool, smsEnabled: Bool, pushEnabled: Bool) {
        this.emailEnabled = emailEnabled;
        this.smsEnabled = smsEnabled;
        this.pushEnabled = pushEnabled;
    }
    
    public function isAllowed(type: NotificationType): Bool {
        return switch (type) {
            case Email: emailEnabled;
            case SMS: smsEnabled;
            case Push: pushEnabled;
        }
    }
}

/**
 * Notification delivery record.
 */
class NotificationRecord {
    public var userId: Int;
    public var message: String;
    public var type: NotificationType;
    public var timestamp: Float;
    public var delivered: Bool;
    
    public function new(userId: Int, message: String, type: NotificationType, timestamp: Float, delivered: Bool) {
        this.userId = userId;
        this.message = message;
        this.type = type;
        this.timestamp = timestamp;
        this.delivered = delivered;
    }
}

/**
 * Bulk notification result containing success and failure information.
 */
class BulkNotificationResult {
    public var successful: Array<NotificationRecord>;
    public var failed: Array<{userId: Int, reason: String}>;
    
    public function new(successful: Array<NotificationRecord>, failed: Array<{userId: Int, reason: String}>) {
        this.successful = successful;
        this.failed = failed;
    }
    
    public function getSuccessCount(): Int {
        return successful.length;
    }
    
    public function getFailureCount(): Int {
        return failed.length;
    }
    
    public function getTotalCount(): Int {
        return getSuccessCount() + getFailureCount();
    }
    
    public function getSuccessRate(): Float {
        var total = getTotalCount();
        return total > 0 ? getSuccessCount() / total : 0.0;
    }
}

/**
 * Types of notifications supported.
 */
enum NotificationType {
    Email;
    SMS;
    Push;
}
