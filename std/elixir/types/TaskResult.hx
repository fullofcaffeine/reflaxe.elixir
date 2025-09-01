package elixir.types;

/**
 * Type-safe result types for Task operations
 * 
 * These enums provide compile-time safety for Task.yield and Task.shutdown results,
 * ensuring proper handling of async operation outcomes.
 */

/**
 * Result from Task.yield operations
 * 
 * @param T The type of the successful task result
 */
enum TaskYieldResult<T> {
    /**
     * Task completed successfully with a value
     * Compiles to: {:ok, value}
     */
    Ok(value: T);
    
    /**
     * Task exited with a reason
     * Compiles to: {:exit, reason}
     */
    Exit(reason: Dynamic);
}

/**
 * Optional wrapper for yield results (can be null if timeout)
 * 
 * @param T The type of the successful task result
 */
typedef TaskYieldOption<T> = Null<TaskYieldResult<T>>;

/**
 * Result from Task.async_stream operations
 * 
 * @param T The type of the successful stream element
 */
enum TaskStreamResult<T> {
    /**
     * Stream element processed successfully
     * Compiles to: {:ok, value}
     */
    Ok(value: T);
    
    /**
     * Stream element failed with exit
     * Compiles to: {:exit, reason}
     */
    Exit(reason: Dynamic);
}

/**
 * Helper class for working with task results
 */
class TaskResultHelper {
    /**
     * Check if a yield result is successful
     */
    public static inline function isOk<T>(result: TaskYieldOption<T>): Bool {
        return switch(result) {
            case null: false;
            case Ok(_): true;
            case Exit(_): false;
        };
    }
    
    /**
     * Extract value from successful yield result
     */
    public static inline function getValue<T>(result: TaskYieldOption<T>): Null<T> {
        return switch(result) {
            case null: null;
            case Ok(value): value;
            case Exit(_): null;
        };
    }
    
    /**
     * Extract exit reason from failed yield result
     */
    public static inline function getExitReason<T>(result: TaskYieldOption<T>): Null<Dynamic> {
        return switch(result) {
            case null: null;
            case Ok(_): null;
            case Exit(reason): reason;
        };
    }
}