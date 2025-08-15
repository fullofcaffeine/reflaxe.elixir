package services;

import haxe.ds.Option;
import haxe.ds.OptionTools;
import haxe.functional.Result;

using haxe.ds.OptionTools;
using haxe.functional.Result.ResultTools;

/**
 * Configuration manager demonstrating Option<T> patterns for safe config access.
 * 
 * This service shows how to use Option<T> for configuration values that may not exist,
 * providing type-safe access with default values and validation.
 * 
 * Key patterns demonstrated:
 * - Option<T> for nullable configuration values
 * - Conversion between Option and Result for error handling
 * - Safe parsing of configuration with fallbacks
 * - Type-safe validation chains
 */
class ConfigManager {
    // Simulated configuration store for demonstration
    static var config: Map<String, String> = [
        "app_name" => "OptionPatterns",
        "timeout" => "30",
        "max_connections" => "100",
        "debug" => "true",
        "database_url" => "postgres://localhost/option_patterns",
        "empty_value" => "",
        "invalid_number" => "not_a_number"
    ];
    
    /**
     * Get a configuration value as Option<String>.
     * 
     * Returns None for missing or empty values, making the absence explicit.
     * 
     * @param key Configuration key
     * @return Some(value) if exists and non-empty, None otherwise
     */
    public static function get(key: String): Option<String> {
        if (key == null || key == "") {
            return None;
        }
        
        var value = config.get(key);
        if (value == null || value == "") {
            return None;
        }
        
        return Some(value);
    }
    
    /**
     * Get a configuration value with a default.
     * 
     * Demonstrates using unwrap() to provide fallback values.
     * 
     * @param key Configuration key
     * @param defaultValue Default value if config is missing
     * @return Configuration value or default
     */
    public static function getWithDefault(key: String, defaultValue: String): String {
        return get(key).unwrap(defaultValue);
    }
    
    /**
     * Get a required configuration value as Result.
     * 
     * Converts Option to Result for error handling when a value is mandatory.
     * 
     * @param key Configuration key
     * @return Ok(value) if exists, Error(message) if missing
     */
    public static function getRequired(key: String): Result<String, String> {
        return get(key).toResult('Required configuration "${key}" is missing or empty');
    }
    
    /**
     * Get configuration value as integer.
     * 
     * Demonstrates safe parsing with Option return type.
     * 
     * @param key Configuration key
     * @return Some(number) if exists and valid, None otherwise
     */
    public static function getInt(key: String): Option<Int> {
        return get(key).flatMap(value -> {
            var parsed = Std.parseInt(value);
            return parsed != null ? Some(parsed) : None;
        });
    }
    
    /**
     * Get configuration value as boolean.
     * 
     * Demonstrates custom parsing logic with Option chaining.
     * 
     * @param key Configuration key
     * @return Some(boolean) if exists and valid, None otherwise
     */
    public static function getBool(key: String): Option<Bool> {
        return get(key).flatMap(value -> {
            return switch (value.toLowerCase()) {
                case "true" | "yes" | "1": Some(true);
                case "false" | "no" | "0": Some(false);
                case _: None;
            }
        });
    }
    
    /**
     * Get integer configuration with validation.
     * 
     * Demonstrates combining Option and Result for complex validation.
     * 
     * @param key Configuration key
     * @param min Minimum allowed value
     * @param max Maximum allowed value
     * @return Ok(value) if valid, Error(message) if invalid or missing
     */
    public static function getIntWithRange(key: String, min: Int, max: Int): Result<Int, String> {
        return getInt(key)
            .toResult('Configuration "${key}" is missing or not a valid number')
            .flatMap(value -> {
                if (value < min) {
                    return Error('Configuration "${key}" value ${value} is below minimum ${min}');
                }
                if (value > max) {
                    return Error('Configuration "${key}" value ${value} is above maximum ${max}');
                }
                return Ok(value);
            });
    }
    
    /**
     * Validate database URL configuration.
     * 
     * Shows complex validation using Option and Result together.
     * 
     * @return Ok(url) if valid, Error(message) if invalid
     */
    public static function getDatabaseUrl(): Result<String, String> {
        return getRequired("database_url")
            .flatMap(url -> {
                if (url.indexOf("://") <= 0) {
                    return Error("Database URL must contain protocol (e.g., postgres://)");
                }
                if (url.length < 10) {
                    return Error("Database URL appears to be too short");
                }
                return Ok(url);
            });
    }
    
    /**
     * Get application timeout with bounds checking.
     * 
     * Demonstrates practical configuration validation.
     * 
     * @return Timeout in seconds (between 1-300), or 30 as default
     */
    public static function getTimeout(): Int {
        return getIntWithRange("timeout", 1, 300).unwrapOr(30);
    }
    
    /**
     * Check if debug mode is enabled.
     * 
     * Shows boolean configuration with sensible default.
     * 
     * @return True if debug mode is enabled
     */
    public static function isDebugEnabled(): Bool {
        return getBool("debug").unwrap(false);
    }
    
    /**
     * Get all configuration values that are set.
     * 
     * Demonstrates filtering with Option integration.
     * 
     * @return Map of all non-empty configuration values
     */
    public static function getAllSetValues(): Map<String, String> {
        var result = new Map<String, String>();
        for (key in config.keys()) {
            switch (get(key)) {
                case Some(value): result.set(key, value);
                case None: // Skip empty/missing values
            }
        }
        return result;
    }
    
    /**
     * Validate all required configuration values.
     * 
     * Shows how to collect multiple validation results.
     * 
     * @param requiredKeys Array of keys that must be present
     * @return Ok(true) if all valid, Error(messages) listing all missing keys
     */
    public static function validateRequired(requiredKeys: Array<String>): Result<Bool, String> {
        var missing = [];
        
        for (key in requiredKeys) {
            switch (get(key)) {
                case None: missing.push(key);
                case Some(_): // Key is present
            }
        }
        
        if (missing.length > 0) {
            return Error('Missing required configuration: ${missing.join(", ")}');
        }
        
        return Ok(true);
    }
}