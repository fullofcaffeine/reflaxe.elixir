package services;

import haxe.test.ExUnit.TestCase;
import haxe.test.Assert;
import haxe.ds.Option;
import haxe.functional.Result;
import models.User;
import services.NotificationService;

using haxe.ds.OptionTools;
using haxe.functional.ResultTools;

/**
 * ExUnit tests for NotificationService demonstrating complex Option<T> and Result<T,E> patterns.
 * 
 * These tests verify that the notification service correctly handles business logic,
 * user preferences, error conditions, and bulk operations with type safety.
 */
@:exunit
class NotificationServiceTest extends TestCase {
    
    @:test
    function sendToUserSucceedsForValidActiveUser() {
        var result = NotificationService.sendToUser(1, "Test message", Email);
        Assert.isOk(result, "Should successfully send notification to active user");
        
        switch(result) {
            case Ok(record): 
                Assert.equals(1, record.userId, "Should have correct user ID");
                Assert.equals("Test message", record.message, "Should have correct message");
                Assert.equals(Email, record.type, "Should have correct notification type");
                Assert.isTrue(record.delivered, "Should be marked as delivered");
            case Error(msg): 
                Assert.fail('Unexpected error: ${msg}');
        }
    }
    
    @:test
    function sendToUserFailsForInactiveUser() {
        var result = NotificationService.sendToUser(3, "Test message", Email);
        Assert.isError(result, "Should fail to send notification to inactive user");
        
        switch(result) {
            case Error(msg): 
                Assert.equals("Cannot send notifications to inactive users", msg, "Should have correct error message");
            case Ok(_): 
                Assert.fail("Expected error for inactive user");
        }
    }
    
    @:test
    function sendToUserFailsForNonexistentUser() {
        var result = NotificationService.sendToUser(999, "Test message", Email);
        Assert.isError(result, "Should fail to send notification to nonexistent user");
        
        switch(result) {
            case Error(msg): 
                Assert.equals("User not found", msg, "Should have correct error message");
            case Ok(_): 
                Assert.fail("Expected error for nonexistent user");
        }
    }
    
    @:test
    function sendToUserFailsForEmptyMessage() {
        var result = NotificationService.sendToUser(1, "", Email);
        Assert.isError(result, "Should fail for empty message");
        
        switch(result) {
            case Error(msg): 
                Assert.equals("Message cannot be empty", msg, "Should have correct error message");
            case Ok(_): 
                Assert.fail("Expected error for empty message");
        }
    }
    
    @:test
    function sendToUserFailsForNullMessage() {
        var result = NotificationService.sendToUser(1, null, Email);
        Assert.isError(result, "Should fail for null message");
        
        switch(result) {
            case Error(msg): 
                Assert.equals("Message cannot be empty", msg, "Should have correct error message");
            case Ok(_): 
                Assert.fail("Expected error for null message");
        }
    }
    
    @:test
    function sendToEmailSucceedsForValidEmail() {
        var result = NotificationService.sendToEmail("alice@example.com", "Email test", Email);
        Assert.isOk(result, "Should successfully send notification by email");
        
        switch(result) {
            case Ok(record): 
                Assert.equals(1, record.userId, "Should send to correct user (Alice has ID 1)");
                Assert.equals("Email test", record.message, "Should have correct message");
            case Error(msg): 
                Assert.fail('Unexpected error: ${msg}');
        }
    }
    
    @:test
    function sendToEmailFailsForNonexistentEmail() {
        var result = NotificationService.sendToEmail("nonexistent@example.com", "Test", Email);
        Assert.isError(result, "Should fail for nonexistent email");
        
        switch(result) {
            case Error(msg): 
                Assert.isTrue(msg.indexOf("No user found with email") >= 0, "Should mention email not found");
            case Ok(_): 
                Assert.fail("Expected error for nonexistent email");
        }
    }
    
    @:test
    function getUserPreferencesReturnsPreferencesForConfiguredUser() {
        var prefs = NotificationService.getUserPreferences(1);
        Assert.isSome(prefs, "Should find preferences for user 1");
        
        switch(prefs) {
            case Some(p): 
                Assert.isTrue(p.emailEnabled, "User 1 should have email enabled");
                Assert.isTrue(p.smsEnabled, "User 1 should have SMS enabled");
                Assert.isFalse(p.pushEnabled, "User 1 should have push disabled");
            case None: 
                Assert.fail("Expected to find preferences for user 1");
        }
    }
    
    @:test
    function getUserPreferencesReturnsNoneForUnconfiguredUser() {
        var prefs = NotificationService.getUserPreferences(999);
        Assert.isNone(prefs, "Should not find preferences for unconfigured user");
    }
    
    @:test
    function isNotificationAllowedReturnsTrueForEnabledType() {
        var allowed = NotificationService.isNotificationAllowed(1, Email);
        Assert.isTrue(allowed, "Email should be allowed for user 1");
    }
    
    @:test
    function isNotificationAllowedReturnsFalseForDisabledType() {
        var allowed = NotificationService.isNotificationAllowed(1, Push);
        Assert.isFalse(allowed, "Push should be disabled for user 1");
    }
    
    @:test
    function isNotificationAllowedReturnsTrueForUserWithoutPreferences() {
        var allowed = NotificationService.isNotificationAllowed(999, Email);
        Assert.isTrue(allowed, "Should default to allowed for users without preferences");
    }
    
    @:test
    function sendBulkReturnsCorrectSuccessAndFailureCounts() {
        var result = NotificationService.sendBulk([1, 2, 3, 999], "Bulk test", Email);
        
        // User 1: Should succeed (active, email enabled)
        // User 2: Should succeed (active, email enabled)  
        // User 3: Should fail (inactive)
        // User 999: Should fail (doesn't exist)
        
        Assert.equals(2, result.getSuccessCount(), "Should have 2 successful sends");
        Assert.equals(2, result.getFailureCount(), "Should have 2 failed sends");
        Assert.equals(4, result.getTotalCount(), "Should have 4 total sends");
        
        // Check success rate
        var expectedRate = 2.0 / 4.0; // 50%
        Assert.equals(expectedRate, result.getSuccessRate(), "Should have correct success rate");
    }
    
    @:test
    function sendBulkHandlesEmptyArray() {
        var result = NotificationService.sendBulk([], "Test", Email);
        
        Assert.equals(0, result.getSuccessCount(), "Should have 0 successful sends");
        Assert.equals(0, result.getFailureCount(), "Should have 0 failed sends");
        Assert.equals(0, result.getTotalCount(), "Should have 0 total sends");
        Assert.equals(0.0, result.getSuccessRate(), "Should have 0% success rate");
    }
    
    @:test
    function getUserNotificationHistoryReturnsCorrectRecords() {
        // First send a notification to create history
        NotificationService.sendToUser(1, "History test", Email);
        
        var history = NotificationService.getUserNotificationHistory(1);
        Assert.isTrue(history.length >= 1, "Should have at least 1 notification in history");
        
        // Verify all records are for the correct user
        for (record in history) {
            Assert.equals(1, record.userId, "All history records should be for user 1");
        }
    }
    
    @:test
    function getUserNotificationHistoryReturnsEmptyForUserWithoutHistory() {
        var history = NotificationService.getUserNotificationHistory(999);
        Assert.equals(0, history.length, "Should have empty history for user without notifications");
    }
    
    @:test
    function getMostRecentNotificationReturnsLatestRecord() {
        // Send multiple notifications to ensure we get the most recent
        NotificationService.sendToUser(2, "First message", Email);
        NotificationService.sendToUser(2, "Second message", SMS);
        
        var recent = NotificationService.getMostRecentNotification(2);
        Assert.isSome(recent, "Should find most recent notification");
        
        switch(recent) {
            case Some(record): 
                Assert.equals(2, record.userId, "Should be for correct user");
                Assert.equals("Second message", record.message, "Should be the most recent message");
            case None: 
                Assert.fail("Expected to find recent notification");
        }
    }
    
    @:test
    function getMostRecentNotificationReturnsNoneForUserWithoutHistory() {
        var recent = NotificationService.getMostRecentNotification(999);
        Assert.isNone(recent, "Should not find notification for user without history");
    }
    
    @:test
    function setUserPreferencesSucceedsForValidUser() {
        var result = NotificationService.setUserPreferences(2, false, true, true);
        Assert.isOk(result, "Should successfully set preferences for valid user");
        
        switch(result) {
            case Ok(prefs): 
                Assert.isFalse(prefs.emailEnabled, "Should have updated email preference");
                Assert.isTrue(prefs.smsEnabled, "Should have updated SMS preference");
                Assert.isTrue(prefs.pushEnabled, "Should have updated push preference");
            case Error(msg): 
                Assert.fail('Unexpected error: ${msg}');
        }
        
        // Verify preferences are actually saved
        var savedPrefs = NotificationService.getUserPreferences(2);
        switch(savedPrefs) {
            case Some(p): 
                Assert.isFalse(p.emailEnabled, "Saved preferences should match");
            case None: 
                Assert.fail("Preferences should be saved");
        }
    }
    
    @:test
    function setUserPreferencesFailsForNonexistentUser() {
        var result = NotificationService.setUserPreferences(999, true, true, true);
        Assert.isError(result, "Should fail to set preferences for nonexistent user");
        
        switch(result) {
            case Error(msg): 
                Assert.equals("User not found", msg, "Should have correct error message");
            case Ok(_): 
                Assert.fail("Expected error for nonexistent user");
        }
    }
    
    @:test
    function sendFailsWhenUserDisablesNotificationType() {
        // First set user 4 to disable email notifications
        NotificationService.setUserPreferences(4, false, true, true);
        
        // Then try to send email notification
        var result = NotificationService.sendToUser(4, "Test", Email);
        Assert.isError(result, "Should fail when user has disabled notification type");
        
        switch(result) {
            case Error(msg): 
                Assert.isTrue(msg.indexOf("disabled Email notifications") >= 0, "Should mention disabled notification type");
            case Ok(_): 
                Assert.fail("Expected error for disabled notification type");
        }
    }
    
    @:test
    function simulatedDeliveryFailureIsHandled() {
        // Messages containing "FAIL" simulate delivery failures
        var result = NotificationService.sendToUser(1, "This will FAIL", Email);
        Assert.isError(result, "Should handle simulated delivery failure");
        
        switch(result) {
            case Error(msg): 
                Assert.equals("Simulated delivery failure", msg, "Should have correct error message");
            case Ok(_): 
                Assert.fail("Expected simulated delivery failure");
        }
    }
}
