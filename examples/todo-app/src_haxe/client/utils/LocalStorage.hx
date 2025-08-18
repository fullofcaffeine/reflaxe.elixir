package client.utils;

import js.Browser;
import js.html.Storage;

/**
 * Type-safe localStorage utility wrapper around js.Browser.getLocalStorage()
 * 
 * Provides convenient methods for storing and retrieving data with
 * proper error handling and type conversions.
 * 
 * Uses Haxe's built-in js.html.Storage API for maximum compatibility
 * and type safety.
 */
class LocalStorage {
    
    private static var storage: Null<Storage> = Browser.getLocalStorage();
    
    /**
     * Initialize localStorage utilities
     */
    public static function initialize(): Void {
        // Check if localStorage is available
        if (!isAvailable()) {
            trace("Warning: localStorage is not available");
        }
    }
    
    /**
     * Check if localStorage is available in the browser
     */
    public static function isAvailable(): Bool {
        try {
            var test = "test";
            storage.setItem(test, test);
            storage.removeItem(test);
            return true;
        } catch (e: Dynamic) {
            return false;
        }
    }
    
    /**
     * Store a string value
     */
    public static function setString(key: String, value: String): Void {
        if (!isAvailable()) return;
        
        try {
            storage.setItem(key, value);
        } catch (e: Dynamic) {
            trace('Failed to store string in localStorage: $e');
        }
    }
    
    /**
     * Retrieve a string value
     */
    public static function getString(key: String, ?defaultValue: String): Null<String> {
        if (!isAvailable()) return defaultValue;
        
        try {
            var value = storage.getItem(key);
            return value != null ? value : defaultValue;
        } catch (e: Dynamic) {
            trace('Failed to retrieve string from localStorage: $e');
            return defaultValue;
        }
    }
    
    /**
     * Store a boolean value
     */
    public static function setBoolean(key: String, value: Bool): Void {
        setString(key, value ? "true" : "false");
    }
    
    /**
     * Retrieve a boolean value
     */
    public static function getBoolean(key: String, defaultValue: Bool = false): Bool {
        var value = getString(key);
        if (value == null) return defaultValue;
        
        return value == "true";
    }
    
    /**
     * Store a number value
     */
    public static function setNumber(key: String, value: Float): Void {
        setString(key, Std.string(value));
    }
    
    /**
     * Retrieve a number value
     */
    public static function getNumber(key: String, defaultValue: Float = 0): Float {
        var value = getString(key);
        if (value == null) return defaultValue;
        
        var parsed = Std.parseFloat(value);
        return Math.isNaN(parsed) ? defaultValue : parsed;
    }
    
    /**
     * Store an object as JSON
     */
    public static function setObject(key: String, value: Dynamic): Void {
        try {
            var json = haxe.Json.stringify(value);
            setString(key, json);
        } catch (e: Dynamic) {
            trace('Failed to store object in localStorage: $e');
        }
    }
    
    /**
     * Retrieve an object from JSON
     */
    public static function getObject(key: String, ?defaultValue: Dynamic): Dynamic {
        var value = getString(key);
        if (value == null) return defaultValue;
        
        try {
            return haxe.Json.parse(value);
        } catch (e: Dynamic) {
            trace('Failed to parse object from localStorage: $e');
            return defaultValue;
        }
    }
    
    /**
     * Remove a value from localStorage
     */
    public static function remove(key: String): Void {
        if (!isAvailable()) return;
        
        try {
            storage.removeItem(key);
        } catch (e: Dynamic) {
            trace('Failed to remove item from localStorage: $e');
        }
    }
    
    /**
     * Remove a value from localStorage (alias for remove)
     * This method provides compatibility with common localStorage usage patterns
     */
    public static function removeItem(key: String): Void {
        remove(key);
    }
    
    /**
     * Clear all localStorage data
     */
    public static function clear(): Void {
        if (!isAvailable()) return;
        
        try {
            storage.clear();
        } catch (e: Dynamic) {
            trace('Failed to clear localStorage: $e');
        }
    }
    
    /**
     * Get all keys in localStorage
     */
    public static function getAllKeys(): Array<String> {
        if (!isAvailable()) return [];
        
        var keys = [];
        try {
            for (i in 0...storage.length) {
                var key = storage.key(i);
                if (key != null) keys.push(key);
            }
        } catch (e: Dynamic) {
            trace('Failed to get localStorage keys: $e');
        }
        
        return keys;
    }
    
    /**
     * Get the total size of localStorage in bytes (approximate)
     */
    public static function getUsedSpace(): Int {
        var total = 0;
        for (key in getAllKeys()) {
            var value = getString(key, "");
            total += key.length + value.length;
        }
        return total;
    }
}