package reflaxe.js;

import js.lib.Promise as JSPromise;

/**
 * Static extension methods for js.lib.Promise to provide ergonomic Promise utilities.
 * 
 * Enhances native JavaScript Promises with functional programming patterns
 * and seamless integration with Reflaxe.Elixir's async/await system.
 * 
 * Usage:
 * ```haxe
 * using reflaxe.js.Promise;
 * 
 * var result = await(
 *     loadData()
 *         .map(data -> data.toUpperCase())
 *         .recover(err -> "DEFAULT")
 *         .timeout(5000)
 * );
 * ```
 * 
 * Features:
 * - Functional composition with map, flatMap, filter
 * - Error handling with recover, catchError  
 * - Utility methods like timeout, delay, race
 * - Type-safe chaining that works with await()
 * - Direct compatibility with Phoenix LiveView integration
 */
class Promise {
    
    /**
     * Maps the resolved value of a Promise using a transformation function.
     * 
     * @param promise The source Promise
     * @param transform Function to transform the resolved value
     * @return New Promise with transformed value
     */
    public static function map<T, U>(promise: JSPromise<T>, transform: T -> U): JSPromise<U> {
        return promise.then(function(value: T): U {
            return transform(value);
        });
    }
    
    /**
     * Flat maps a Promise, allowing chaining of Promise-returning functions.
     * 
     * @param promise The source Promise
     * @param transform Function that returns a new Promise
     * @return Flattened Promise result
     */
    public static function flatMap<T, U>(promise: JSPromise<T>, transform: T -> JSPromise<U>): JSPromise<U> {
        return promise.then(transform);
    }
    
    /**
     * Filters a Promise value, rejecting if predicate fails.
     * 
     * @param promise The source Promise
     * @param predicate Function to test the resolved value
     * @param errorMessage Error message if predicate fails
     * @return Promise that resolves only if predicate passes
     */
    public static function filter<T>(promise: JSPromise<T>, predicate: T -> Bool, ?errorMessage: String): JSPromise<T> {
        return promise.then(function(value: T): T {
            if (predicate(value)) {
                return value;
            } else {
                throw new js.lib.Error(errorMessage != null ? errorMessage : "Promise filter failed");
            }
        });
    }
    
    /**
     * Recovers from Promise rejection with a fallback value.
     * 
     * @param promise The source Promise
     * @param recovery Function to provide fallback value
     * @return Promise that never rejects
     */
    public static function recover<T>(promise: JSPromise<T>, recovery: Dynamic -> T): JSPromise<T> {
        return promise.catchError(function(error: Dynamic): T {
            return recovery(error);
        });
    }
    
    /**
     * Transforms Promise rejection to a different error type.
     * 
     * @param promise The source Promise  
     * @param transform Function to transform the error
     * @return Promise with transformed error
     */
    public static function catchError<T>(promise: JSPromise<T>, transform: Dynamic -> T): JSPromise<T> {
        return promise.catchError(function(error: Dynamic): T {
            return transform(error);
        });
    }
    
    /**
     * Adds a timeout to a Promise, rejecting if not resolved in time.
     * 
     * @param promise The source Promise
     * @param timeoutMs Timeout in milliseconds
     * @param errorMessage Custom error message for timeout
     * @return Promise that rejects on timeout
     */
    public static function timeout<T>(promise: JSPromise<T>, timeoutMs: Int, ?errorMessage: String): JSPromise<T> {
        var timeoutPromise = new JSPromise(function(resolve, reject) {
            js.Browser.window.setTimeout(function() {
                reject(new js.lib.Error(errorMessage != null ? errorMessage : 'Promise timeout after ${timeoutMs}ms'));
            }, timeoutMs);
        });
        
        return JSPromise.race([promise, timeoutPromise]);
    }
    
    /**
     * Creates a Promise that resolves after a delay.
     * 
     * @param value Value to resolve with
     * @param delayMs Delay in milliseconds
     * @return Promise that resolves after delay
     */
    public static function delay<T>(value: T, delayMs: Int): JSPromise<T> {
        return new JSPromise(function(resolve, reject) {
            js.Browser.window.setTimeout(function() {
                resolve(value);
            }, delayMs);
        });
    }
    
    /**
     * Creates an immediately resolved Promise.
     * 
     * @param value Value to resolve with
     * @return Resolved Promise
     */
    public static function resolve<T>(value: T): JSPromise<T> {
        return JSPromise.resolve(value);
    }
    
    /**
     * Creates an immediately rejected Promise.
     * 
     * @param error Error to reject with
     * @return Rejected Promise
     */
    public static function reject<T>(error: Dynamic): JSPromise<T> {
        return JSPromise.reject(error);
    }
    
    /**
     * Executes a side effect when Promise resolves, without changing the value.
     * 
     * @param promise The source Promise
     * @param sideEffect Function to execute on success
     * @return Original Promise unchanged
     */
    public static function tap<T>(promise: JSPromise<T>, sideEffect: T -> Void): JSPromise<T> {
        return promise.then(function(value: T): T {
            sideEffect(value);
            return value;
        });
    }
    
    /**
     * Executes a side effect when Promise rejects, without changing the error.
     * 
     * @param promise The source Promise
     * @param sideEffect Function to execute on error
     * @return Original Promise unchanged
     */
    public static function tapError<T>(promise: JSPromise<T>, sideEffect: Dynamic -> Void): JSPromise<T> {
        return promise.catchError(function(error: Dynamic): JSPromise<T> {
            sideEffect(error);
            return JSPromise.reject(error);
        });
    }
    
    /**
     * Converts a callback-based function to Promise.
     * 
     * @param fn Function that takes a callback as last parameter
     * @return Promise-returning function
     */
    public static function fromCallback<T>(fn: (T -> Void) -> Void): JSPromise<T> {
        return new JSPromise(function(resolve, reject) {
            try {
                fn(resolve);
            } catch (error: Dynamic) {
                reject(error);
            }
        });
    }
    
    /**
     * Converts a Node.js-style callback to Promise.
     * 
     * @param fn Function that takes (error, result) callback
     * @return Promise-returning function
     */
    public static function fromNodeCallback<T>(fn: (Dynamic -> T -> Void) -> Void): JSPromise<T> {
        return new JSPromise(function(resolve, reject) {
            fn(function(error: Dynamic, result: T) {
                if (error != null) {
                    reject(error);
                } else {
                    resolve(result);
                }
            });
        });
    }
    
    /**
     * Creates a Promise that resolves when all input Promises resolve.
     * 
     * @param promises Array of Promises to wait for
     * @return Promise of array with all results
     */
    public static function all<T>(promises: Array<JSPromise<T>>): JSPromise<Array<T>> {
        return JSPromise.all(promises);
    }
    
    /**
     * Creates a Promise that resolves when any input Promise resolves.
     * 
     * @param promises Array of Promises to race
     * @return Promise with first resolved result
     */
    public static function race<T>(promises: Array<JSPromise<T>>): JSPromise<T> {
        return JSPromise.race(promises);
    }
    
    /**
     * Creates a Promise that resolves when all Promises settle (resolve or reject).
     * 
     * @param promises Array of Promises to wait for
     * @return Promise of array with all outcomes
     */
    public static function allSettled<T>(promises: Array<JSPromise<T>>): JSPromise<Array<js.lib.Promise.PromiseSettleOutcome<T>>> {
        return JSPromise.allSettled(promises);
    }
}