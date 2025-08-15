package services;

import haxe.test.ExUnit.TestCase;
import haxe.test.Assert;
import haxe.ds.Option;
import haxe.functional.Result;
import services.ConfigManager;

using haxe.ds.OptionTools;
using haxe.functional.Result.ResultTools;

/**
 * ExUnit tests for ConfigManager demonstrating Option<T> configuration patterns.
 * 
 * These tests verify that configuration management correctly handles missing values,
 * invalid formats, and provides appropriate defaults and validation.
 */
@:exunit
class ConfigManagerTest extends TestCase {
    
    @:test
    function getReturnsValueForExistingKey() {
        var value = ConfigManager.get("app_name");
        Assert.isSome(value, "Should find existing configuration key");
        Assert.equals(Some("OptionPatterns"), value, "Should have correct value");
    }
    
    @:test
    function getReturnsNoneForMissingKey() {
        var value = ConfigManager.get("nonexistent_key");
        Assert.isNone(value, "Should not find missing configuration key");
    }
    
    @:test
    function getReturnsNoneForEmptyValue() {
        var value = ConfigManager.get("empty_value");
        Assert.isNone(value, "Should return None for empty configuration value");
    }
    
    @:test
    function getReturnsNoneForNullKey() {
        var value = ConfigManager.get(null);
        Assert.isNone(value, "Should return None for null key");
    }
    
    @:test
    function getReturnsNoneForEmptyKey() {
        var value = ConfigManager.get("");
        Assert.isNone(value, "Should return None for empty key");
    }
    
    @:test
    function getWithDefaultReturnsValueForExistingKey() {
        var value = ConfigManager.getWithDefault("app_name", "DefaultApp");
        Assert.equals("OptionPatterns", value, "Should return existing value");
    }
    
    @:test
    function getWithDefaultReturnsDefaultForMissingKey() {
        var value = ConfigManager.getWithDefault("missing_key", "DefaultValue");
        Assert.equals("DefaultValue", value, "Should return default value for missing key");
    }
    
    @:test
    function getRequiredReturnsOkForExistingKey() {
        var result = ConfigManager.getRequired("app_name");
        Assert.isOk(result, "Should successfully get required configuration");
        
        switch(result) {
            case Ok(value): 
                Assert.equals("OptionPatterns", value, "Should have correct value");
            case Error(msg): 
                Assert.fail('Unexpected error: ${msg}');
        }
    }
    
    @:test
    function getRequiredReturnsErrorForMissingKey() {
        var result = ConfigManager.getRequired("missing_key");
        Assert.isError(result, "Should fail for missing required configuration");
        
        switch(result) {
            case Error(msg): 
                Assert.isTrue(msg.indexOf("missing_key") >= 0, "Error should mention the missing key");
            case Ok(_): 
                Assert.fail("Expected error for missing required key");
        }
    }
    
    @:test
    function getIntReturnsValueForValidNumber() {
        var value = ConfigManager.getInt("timeout");
        Assert.isSome(value, "Should parse valid integer");
        Assert.equals(Some(30), value, "Should have correct integer value");
    }
    
    @:test
    function getIntReturnsNoneForInvalidNumber() {
        var value = ConfigManager.getInt("invalid_number");
        Assert.isNone(value, "Should return None for invalid number");
    }
    
    @:test
    function getIntReturnsNoneForMissingKey() {
        var value = ConfigManager.getInt("missing_key");
        Assert.isNone(value, "Should return None for missing key");
    }
    
    @:test
    function getBoolReturnsTrueForValidTrueValues() {
        var value = ConfigManager.getBool("debug");
        Assert.isSome(value, "Should parse valid boolean");
        Assert.equals(Some(true), value, "Should parse 'true' as true");
    }
    
    @:test
    function getBoolReturnsNoneForInvalidValue() {
        var value = ConfigManager.getBool("app_name"); // Contains "OptionPatterns", not a boolean
        Assert.isNone(value, "Should return None for non-boolean value");
    }
    
    @:test
    function getBoolReturnsNoneForMissingKey() {
        var value = ConfigManager.getBool("missing_key");
        Assert.isNone(value, "Should return None for missing key");
    }
    
    @:test
    function getIntWithRangeSucceedsForValidValue() {
        var result = ConfigManager.getIntWithRange("max_connections", 1, 1000);
        Assert.isOk(result, "Should succeed for value within range");
        
        switch(result) {
            case Ok(value): 
                Assert.equals(100, value, "Should have correct value");
            case Error(msg): 
                Assert.fail('Unexpected error: ${msg}');
        }
    }
    
    @:test
    function getIntWithRangeFailsForValueBelowMin() {
        var result = ConfigManager.getIntWithRange("timeout", 100, 1000);
        Assert.isError(result, "Should fail for value below minimum");
        
        switch(result) {
            case Error(msg): 
                Assert.isTrue(msg.indexOf("below minimum") >= 0, "Error should mention minimum value");
            case Ok(_): 
                Assert.fail("Expected error for value below minimum");
        }
    }
    
    @:test
    function getIntWithRangeFailsForValueAboveMax() {
        var result = ConfigManager.getIntWithRange("max_connections", 1, 50);
        Assert.isError(result, "Should fail for value above maximum");
        
        switch(result) {
            case Error(msg): 
                Assert.isTrue(msg.indexOf("above maximum") >= 0, "Error should mention maximum value");
            case Ok(_): 
                Assert.fail("Expected error for value above maximum");
        }
    }
    
    @:test
    function getIntWithRangeFailsForMissingKey() {
        var result = ConfigManager.getIntWithRange("missing_key", 1, 100);
        Assert.isError(result, "Should fail for missing key");
        
        switch(result) {
            case Error(msg): 
                Assert.isTrue(msg.indexOf("missing or not a valid number") >= 0, "Error should mention missing/invalid");
            case Ok(_): 
                Assert.fail("Expected error for missing key");
        }
    }
    
    @:test
    function getDatabaseUrlSucceedsForValidUrl() {
        var result = ConfigManager.getDatabaseUrl();
        Assert.isOk(result, "Should succeed for valid database URL");
        
        switch(result) {
            case Ok(url): 
                Assert.isTrue(url.indexOf("postgres://") >= 0, "Should contain protocol");
            case Error(msg): 
                Assert.fail('Unexpected error: ${msg}');
        }
    }
    
    @:test
    function getTimeoutReturnsValidValueWithinBounds() {
        var timeout = ConfigManager.getTimeout();
        Assert.isTrue(timeout >= 1 && timeout <= 300, "Timeout should be within valid bounds");
        Assert.equals(30, timeout, "Should return configured timeout value");
    }
    
    @:test
    function isDebugEnabledReturnsCorrectValue() {
        var debugEnabled = ConfigManager.isDebugEnabled();
        Assert.isTrue(debugEnabled, "Debug mode should be enabled in test config");
    }
    
    @:test
    function getAllSetValuesReturnsOnlyNonEmptyValues() {
        var allValues = ConfigManager.getAllSetValues();
        Assert.isTrue(allValues.exists("app_name"), "Should include app_name");
        Assert.isTrue(allValues.exists("timeout"), "Should include timeout");
        Assert.isFalse(allValues.exists("empty_value"), "Should not include empty values");
        
        // Verify all returned values are non-empty
        for (key in allValues.keys()) {
            var value = allValues.get(key);
            Assert.isTrue(value != null && value != "", 'Value for ${key} should not be empty');
        }
    }
    
    @:test
    function validateRequiredSucceedsWhenAllKeysPresent() {
        var result = ConfigManager.validateRequired(["app_name", "timeout", "debug"]);
        Assert.isOk(result, "Should succeed when all required keys are present");
        
        switch(result) {
            case Ok(valid): 
                Assert.isTrue(valid, "Should return true for valid configuration");
            case Error(msg): 
                Assert.fail('Unexpected error: ${msg}');
        }
    }
    
    @:test
    function validateRequiredFailsWhenKeysAreMissing() {
        var result = ConfigManager.validateRequired(["app_name", "missing_key1", "missing_key2"]);
        Assert.isError(result, "Should fail when required keys are missing");
        
        switch(result) {
            case Error(msg): 
                Assert.isTrue(msg.indexOf("missing_key1") >= 0, "Error should mention first missing key");
                Assert.isTrue(msg.indexOf("missing_key2") >= 0, "Error should mention second missing key");
            case Ok(_): 
                Assert.fail("Expected error for missing required keys");
        }
    }
    
    @:test
    function validateRequiredSucceedsForEmptyArray() {
        var result = ConfigManager.validateRequired([]);
        Assert.isOk(result, "Should succeed for empty required keys array");
    }
}