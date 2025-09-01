/**
 * Eof: End of File exception for Elixir target
 * 
 * WHY: The standard Haxe Eof uses exception handling patterns that are
 * incompatible with the Elixir target's catch clause typing.
 * 
 * WHAT: A simple exception class that can be caught in Elixir-compatible way.
 * 
 * HOW: Minimal implementation that satisfies the Input class requirements.
 */
package haxe.io;

/**
 * Exception thrown when reading past the end of a file or stream.
 */
class Eof {
    public function new() {}
    
    public function toString(): String {
        return "Eof";
    }
}