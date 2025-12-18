package elixir.types;

import elixir.types.Term;

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
    Exit(reason: Term);
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
    Exit(reason: Term);
}

@:nativeGen extern class TaskResultHelper {
    public static function isOk<T>(result: TaskYieldOption<T>): Bool;
    public static function getValue<T>(result: TaskYieldOption<T>): Null<T>;
    public static function getExitReason<T>(result: TaskYieldOption<T>): Null<Term>;
}
