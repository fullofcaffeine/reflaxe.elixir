package elixir;

#if (macro || reflaxe_runtime)

import elixir.types.Term;

/**
 * IO module extern definitions for Elixir standard library
 * Provides type-safe interfaces for input/output operations
 * 
 * Maps to Elixir's IO module functions with proper type signatures
 * Essential for console interaction, file operations, and data formatting
 */
@:native("IO")
extern class IO {
    
    // Output operations
    @:native("IO.puts")
    public static function puts(item: Term): Term; // Returns :ok
    
    @:native("IO.puts")
    public static function putsTo(device: Term, item: Term): Term; // Output to specific device
    
    @:native("IO.write")
    public static function write(item: Term): Term; // Write without newline
    
    @:native("IO.write")
    public static function writeTo(device: Term, item: Term): Term;
    
    @:native("IO.inspect")
    public static function inspect<T>(item: T): T; // Inspect and return the item
    
    @:native("IO.inspect")
    public static function inspectTo<T>(device: Term, item: T): T;
    
    @:native("IO.inspect")
    public static function inspectWithOptions<T>(item: T, options: Map<String, Term>): T;
    
    @:native("IO.inspect")
    public static function inspectToWithOptions<T>(device: Term, item: T, options: Map<String, Term>): T;
    
    // Input operations
    @:native("IO.gets")
    public static function gets(prompt: String): Null<String>; // Read line with prompt
    
    @:native("IO.gets")
    public static function getsFrom(device: Term, prompt: String): Null<String>;
    
    @:native("IO.read")
    public static function read(count: Int): Null<String>; // Read specific number of characters
    
    @:native("IO.read")
    public static function readFrom(device: Term, count: Int): Null<String>;
    
    @:native("IO.read")
    public static function readLine(): Null<String>; // Read single line
    
    @:native("IO.read")
    public static function readLineFrom(device: Term): Null<String>;
    
    // Data formatting
    @:native("IO.iodata_length")
    public static function iodataLength(iodata: Term): Int; // Get iodata byte length
    
    @:native("IO.iodata_to_binary")
    public static function iodataToBinary(iodata: Term): String; // Convert iodata to binary
    
    @:native("IO.chardata_to_string")
    public static function chardataToString(chardata: Term): String; // Convert chardata to string
    
    // Stream operations
    @:native("IO.stream")
    public static function stream(device: Term, lineOrBytes: Term): Term; // Create IO stream
    
    @:native("IO.binstream")
    public static function binstream(device: Term, lineOrBytes: Term): Term; // Create binary IO stream
    
    // ANSI and formatting
    @:native("IO.ANSI.format")
    public static function ansiFormat(ansidata: Array<Term>): String; // Format ANSI codes
    
    @:native("IO.ANSI.format")
    public static function ansiFormatWithOptions(ansidata: Array<Term>, options: Map<String, Term>): String;
    
    // Common ANSI colors and styles
    @:native("IO.ANSI.reset")
    public static var ANSI_RESET: String;
    
    @:native("IO.ANSI.black")
    public static var ANSI_BLACK: String;
    
    @:native("IO.ANSI.red")
    public static var ANSI_RED: String;
    
    @:native("IO.ANSI.green")
    public static var ANSI_GREEN: String;
    
    @:native("IO.ANSI.yellow")
    public static var ANSI_YELLOW: String;
    
    @:native("IO.ANSI.blue")
    public static var ANSI_BLUE: String;
    
    @:native("IO.ANSI.magenta")
    public static var ANSI_MAGENTA: String;
    
    @:native("IO.ANSI.cyan")
    public static var ANSI_CYAN: String;
    
    @:native("IO.ANSI.white")
    public static var ANSI_WHITE: String;
    
    @:native("IO.ANSI.bright")
    public static var ANSI_BRIGHT: String;
    
    @:native("IO.ANSI.faint")
    public static var ANSI_FAINT: String;
    
    @:native("IO.ANSI.italic")
    public static var ANSI_ITALIC: String;
    
    @:native("IO.ANSI.underline")
    public static var ANSI_UNDERLINE: String;
    
    @:native("IO.ANSI.blink_slow")
    public static var ANSI_BLINK_SLOW: String;
    
    @:native("IO.ANSI.blink_rapid")
    public static var ANSI_BLINK_RAPID: String;
    
    @:native("IO.ANSI.reverse")
    public static var ANSI_REVERSE: String;
    
    @:native("IO.ANSI.crossed_out")
    public static var ANSI_CROSSED_OUT: String;
    
    // Warn operations for deprecation and warnings
    @:native("IO.warn")
    public static function warn(message: String): Term; // Print warning
    
    @:native("IO.warn")
    public static function warnWithLocation(message: String, location: Map<String, Term>): Term;
    
    // Device operations
    @:native("IO.getopts")
    public static function getopts(): Map<String, Term>; // Get terminal options
    
    @:native("IO.getopts")
    public static function getoptsFrom(device: Term): Map<String, Term>;
    
    @:native("IO.setopts")
    public static function setopts(options: Map<String, Term>): Term; // Set terminal options
    
    @:native("IO.setopts")
    public static function setoptsTo(device: Term, options: Map<String, Term>): Term;
    
    // Common devices
    public static inline var STDIO: String = "stdio";
    public static inline var STDERR: String = "stderr";
    public static inline var STDIN: String = "stdin";
    
    // Helper functions for common operations
    public static inline function println(item: Term): Term {
        return puts(item);
    }
    
    public static inline function print(item: Term): Term {
        return write(item);
    }
    
    public static inline function debug<T>(item: T, label: String = ""): T {
        if (label != "") {
            puts(label + ": ");
        }
        return inspect(item);
    }
    
    public static inline function error(message: String): Term {
        return putsTo(STDERR, message);
    }
    
    public static inline function coloredPrint(text: String, color: String): Term {
        return write(color + text + ANSI_RESET);
    }
    
    public static inline function redText(text: String): Term {
        return coloredPrint(text, ANSI_RED);
    }
    
    public static inline function greenText(text: String): Term {
        return coloredPrint(text, ANSI_GREEN);
    }
    
    public static inline function blueText(text: String): Term {
        return coloredPrint(text, ANSI_BLUE);
    }
    
    public static inline function yellowText(text: String): Term {
        return coloredPrint(text, ANSI_YELLOW);
    }
    
    // Input helpers
    public static inline function prompt(message: String): Null<String> {
        return gets(message);
    }
    
    public static inline function readChar(): Null<String> {
        return read(1);
    }
    
    public static inline function readAll(): Null<String> {
        return read(-1); // Read all available
    }
    
    // Format helpers
    public static inline function formatInspect<T>(item: T, label: String = ""): String {
        var result = iodataToBinary(inspect(item));
        return label != "" ? label + ": " + result : result;
    }
}

#end
