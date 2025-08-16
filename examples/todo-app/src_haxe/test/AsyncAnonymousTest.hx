package test;

import reflaxe.js.Async;
import js.lib.Promise;
import js.Browser;

/**
 * Test file demonstrating @:async anonymous function support.
 * This shows JavaScript-parity async/await with identical ergonomics.
 */
class AsyncAnonymousTest {
    
    public static function main(): Void {
        // Test 1: Event handler with @:async anonymous function
        Browser.document.addEventListener("DOMContentLoaded", @:async function(event) {
            trace("DOM loaded, starting async operations...");
            
            // Use await inside anonymous function
            var data = await(fetchDataAsync());
            trace("Fetched data: " + data);
            
            // Chain multiple async operations
            var processed = await(processDataAsync(data));
            trace("Processed: " + processed);
        });
        
        // Test 2: Array methods with @:async
        var urls = ["api/1", "api/2", "api/3"];
        
        // Map with async function
        var promises = urls.map(@:async function(url) {
            var response = await(fetchFromUrl(url));
            return response.toUpperCase();
        });
        
        // Test 3: Nested @:async functions
        var complexOperation = @:async function(): Promise<String> {
            trace("Starting complex operation");
            
            // Inner async function
            var innerAsync = @:async function(value: String): Promise<String> {
                var result = await(Async.delay(value, 100));
                return "Inner: " + result;
            };
            
            var result = await(innerAsync("test"));
            return "Outer: " + result;
        };
        
        // Test 4: Async IIFE (Immediately Invoked Function Expression)
        (@:async function() {
            trace("Async IIFE starting");
            var config = await(loadConfig());
            trace("Config loaded: " + config);
        })();
        
        // Test 5: Callback conversion with @:async
        setTimeout(@:async function() {
            trace("Timer fired, doing async work");
            var result = await(doAsyncWork());
            trace("Async work complete: " + result);
        }, 1000);
        
        // Test 6: Promise constructor with @:async executor
        var customPromise = new Promise(@:async function(resolve, reject) {
            try {
                var data = await(riskyOperation());
                resolve(data);
            } catch (e: Dynamic) {
                reject(e);
            }
        });
        
        // Test 7: Object methods with @:async
        var handler = {
            onClick: @:async function(event): Promise<Void> {
                var target = event.target;
                var data = await(fetchDataForElement(target));
                updateUI(data);
            },
            
            onSubmit: @:async function(event): Promise<Bool> {
                event.preventDefault();
                var formData = await(validateForm(event.target));
                var success = await(submitForm(formData));
                return success;
            }
        };
    }
    
    // Helper async functions for testing
    
    static function fetchDataAsync(): Promise<String> {
        return Async.delay("sample data", 100);
    }
    
    static function processDataAsync(data: String): Promise<String> {
        return Async.delay(data.toUpperCase(), 50);
    }
    
    static function fetchFromUrl(url: String): Promise<String> {
        return Async.delay("Response from " + url, 200);
    }
    
    static function loadConfig(): Promise<Dynamic> {
        return Async.resolve({apiUrl: "https://api.example.com", timeout: 5000});
    }
    
    static function doAsyncWork(): Promise<String> {
        return Async.delay("work completed", 300);
    }
    
    static function riskyOperation(): Promise<String> {
        return Math.random() > 0.5 
            ? Async.resolve("success")
            : Async.reject("random failure");
    }
    
    static function fetchDataForElement(element: Dynamic): Promise<Dynamic> {
        return Async.resolve({id: "el-1", value: "clicked"});
    }
    
    static function updateUI(data: Dynamic): Void {
        trace("Updating UI with: " + data);
    }
    
    static function validateForm(form: Dynamic): Promise<Dynamic> {
        return Async.resolve({valid: true, data: {}});
    }
    
    static function submitForm(formData: Dynamic): Promise<Bool> {
        return Async.delay(true, 500);
    }
    
    static function setTimeout(callback: Void -> Void, ms: Int): Void {
        Browser.window.setTimeout(callback, ms);
    }
}