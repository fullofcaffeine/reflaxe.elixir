/*
 * Copyright (C)2005-2025 Haxe Foundation
 *
 * Permission is hereby granted, free of charge, to any person obtaining a
 * copy of this software and associated documentation files (the "Software"),
 * to deal in the Software without restriction, including without limitation
 * the rights to use, copy, modify, merge, publish, distribute, sublicense,
 * and/or sell copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 * DEALINGS IN THE SOFTWARE.
 */

/**
 * System-level operations and information for the Elixir target.
 * 
 * Provides access to system functionality including I/O, environment variables,
 * command execution, and process management on the BEAM.
 * 
 * ## Usage Example (Haxe)
 * ```haxe
 * Sys.println("Hello, World!");
 * var env = Sys.environment();
 * var cwd = Sys.getCwd();
 * ```
 * 
 * ## Generated Idiomatic Elixir
 * ```elixir
 * IO.puts("Hello, World!")
 * env = System.get_env()
 * cwd = File.cwd!()
 * ```
 * 
 * @see https://api.haxe.org/Sys.html
 */
@:coreApi
class Sys {
    /**
     * Prints a line to the standard output, followed by a newline.
     * @param v The value to print
     */
    public static inline function println(v: Dynamic): Void {
        untyped __elixir__('IO.puts({0})', v);
    }
    
    /**
     * Prints a value to the standard output without a trailing newline.
     * @param v The value to print
     */
    public static inline function print(v: Dynamic): Void {
        untyped __elixir__('IO.write({0})', v);
    }
    
    /**
     * Reads a line from the standard input.
     * @return The line read, without the trailing newline
     */
    public static inline function stdin(): haxe.io.Input {
        // Return a standard input object
        return untyped __elixir__('Process.group_leader()');
    }
    
    /**
     * Returns the standard output.
     * @return The standard output stream
     */
    public static inline function stdout(): haxe.io.Output {
        // Return a standard output object
        return untyped __elixir__('Process.group_leader()');
    }
    
    /**
     * Returns the standard error output.
     * @return The standard error stream
     */
    public static inline function stderr(): haxe.io.Output {
        // Return a standard error object
        return untyped __elixir__(':standard_error');
    }
    
    /**
     * Reads a single character from standard input.
     * @param echo Whether to echo the character to stdout
     * @return The character code
     */
    public static function getChar(echo: Bool): Int {
        // Read a single character from stdin.
        //
        // NOTE
        // - Use a raw Elixir block here because terminal echo control is BEAM/IO-specific.
        // - Return the character code as an Int (or 0 on failure).
        return untyped __elixir__('
            {:ok, old_settings} = :io.getopts(:standard_io)

            if not {0} do
                :io.setopts(:standard_io, [{:echo, false}])
            end

            input = IO.getn("", 1)
            :io.setopts(:standard_io, old_settings)

            case input do
                <<c::utf8>> -> c
                _ -> 0
            end
        ', echo);
    }
    
    /**
     * Returns all environment variables.
     * @return A map of environment variable names to values
     */
    public static function environment(): Map<String, String> {
        // System.get_env/0 already returns an Elixir map of string keys/values.
        // Expose it directly as a Haxe Map<String, String> for the Elixir target.
        return cast untyped __elixir__('System.get_env()');
    }
    
    /**
     * Gets the value of an environment variable.
     * @param s The name of the environment variable
     * @return The value of the environment variable, or null if not set
     */
    public static inline function getEnv(s: String): Null<String> {
        return untyped __elixir__('System.get_env({0})', s);
    }
    
    /**
     * Sets the value of an environment variable.
     * @param s The name of the environment variable
     * @param v The value to set
     */
    public static inline function putEnv(s: String, v: String): Void {
        untyped __elixir__('System.put_env({0}, {1})', s, v);
    }
    
    /**
     * Returns the current working directory.
     * @return The current working directory path
     */
    public static inline function getCwd(): String {
        return untyped __elixir__('File.cwd!()');
    }
    
    /**
     * Changes the current working directory.
     * @param s The path to change to
     */
    public static inline function setCwd(s: String): Void {
        untyped __elixir__('File.cd!({0})', s);
    }
    
    /**
     * Returns the arguments passed to the program.
     * @return An array of command-line arguments
     */
    public static function args(): Array<String> {
        return untyped __elixir__('System.argv()');
    }
    
    /**
     * Exits the program with the specified exit code.
     * @param code The exit code (0 for success)
     */
    public static inline function exit(code: Int): Void {
        untyped __elixir__('System.halt({0})', code);
    }
    
    /**
     * Executes a command in the system shell.
     * @param cmd The command to execute
     * @param args Optional arguments for the command
     * @return The exit code of the command
     */
    public static function command(cmd: String, ?args: Array<String>): Int {
        if (args == null || args.length == 0) {
            return untyped __elixir__('
                case System.cmd("sh", ["-c", {0}]) do
                    {_, 0} -> 0
                    {_, code} -> code
                end',
                cmd
            );
        } else {
            return untyped __elixir__('
                case System.cmd({0}, {1}) do
                    {_, 0} -> 0
                    {_, code} -> code
                end',
                cmd, args
            );
        }
    }
    
    /**
     * Returns the current system time in seconds since Unix epoch.
     * @return The current time in seconds
     */
    public static inline function time(): Float {
        return untyped __elixir__('System.system_time(:second)');
    }
    
    /**
     * Returns the current CPU time used by the process.
     * @return The CPU time in seconds
     */
    public static inline function cpuTime(): Float {
        return untyped __elixir__('
            {total, _} = :erlang.statistics(:runtime)
            total / 1000.0
        ');
    }
    
    /**
     * Suspends execution for the specified number of seconds.
     * @param seconds The number of seconds to sleep
     */
    public static inline function sleep(seconds: Float): Void {
        var milliseconds = Std.int(seconds * 1000);
        untyped __elixir__('Process.sleep({0})', milliseconds);
    }
    
    /**
     * Returns the name of the operating system.
     * @return The OS name (e.g., "linux", "darwin", "windows")
     */
    public static function systemName(): String {
        return untyped __elixir__('
            case :os.type() do
                {:unix, :linux} -> "linux"
                {:unix, :darwin} -> "darwin"
                {:win32, _} -> "windows"
                {:unix, name} -> Atom.to_string(name)
                {family, name} -> Atom.to_string(family) <> "_" <> Atom.to_string(name)
            end
        ');
    }
    
    /**
     * Returns the path to the executable that started the current process.
     * @return The executable path
     */
    public static function executablePath(): String {
        // In Elixir/BEAM, this would be the path to the Erlang VM
        // We can get the path to the current executable script or beam file
        return untyped __elixir__('
            case :init.get_argument(:progname) do
                {:ok, [[path | _]]} -> List.to_string(path)
                _ -> System.find_executable("erl") || ""
            end
        ');
    }
    
    /**
     * Returns the path to the current program.
     * @return The program path
     */
    public static function programPath(): String {
        // Similar to executablePath for Elixir
        return executablePath();
    }
    
    /**
     * Sets the time locale for the current process.
     * @param loc The locale string (e.g., "en_US", "de_DE")
     * @return True if the locale was set successfully
     */
    public static function setTimeLocale(loc: String): Bool {
        // Elixir/BEAM doesn't have a direct equivalent to setlocale
        // We can set the application environment for locale
        untyped __elixir__('
            Application.put_env(:elixir, :locale, {0})
        ', loc);
        return true;
    }
}
