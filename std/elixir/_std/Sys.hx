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
	public static inline function println(v:Dynamic):Void {
		untyped __elixir__('IO.puts({0})', v);
	}

	/**
	 * Prints a value to the standard output without a trailing newline.
	 * @param v The value to print
	 */
	public static inline function print(v:Dynamic):Void {
		untyped __elixir__('IO.write({0})', v);
	}

	/** Return a byte input stream for the current process group leader. */
	public static inline function stdin():haxe.io.Input {
		return new reflaxe.elixir.runtime.StandardInput();
	}

	/** Return a byte output stream for standard output. */
	public static inline function stdout():haxe.io.Output {
		return new reflaxe.elixir.runtime.StandardOutput(reflaxe.elixir.runtime.StandardIODevice.StandardIO);
	}

	/** Return a byte output stream for standard error. */
	public static inline function stderr():haxe.io.Output {
		return new reflaxe.elixir.runtime.StandardOutput(reflaxe.elixir.runtime.StandardIODevice.StandardError);
	}

	/**
	 * Reads a single character from standard input.
	 * @param echo Whether to echo the character to stdout
	 * @return The character code
	 */
	public static function getChar(echo:Bool):Int {
		// This target block owns terminal echo control. It disables device echo
		// during the read and writes the character once when echo is requested.
		return untyped __elixir__('
            old_echo = :proplists.get_value(:echo, :io.getopts(:standard_io), :undefined)

            if old_echo != :undefined do
              :io.setopts(:standard_io, [{:echo, false}])
            end

            input =
              try do
                IO.getn("", 1)
              after
                if old_echo != :undefined do
                  :io.setopts(:standard_io, [{:echo, old_echo}])
                end
              end

            case input do
              <<c::utf8>> ->
                if {0}, do: IO.write(input)
                c

              _ ->
                0
            end
        ', echo);
	}

	/**
	 * Returns all environment variables.
	 * @return A map of environment variable names to values
	 */
	public static function environment():Map<String, String> {
		// System.get_env/0 already returns an Elixir map of string keys/values.
		// Expose it directly as a Haxe Map<String, String> for the Elixir target.
		return cast untyped __elixir__('System.get_env()');
	}

	/**
	 * Gets the value of an environment variable.
	 * @param s The name of the environment variable
	 * @return The value of the environment variable, or null if not set
	 */
	public static inline function getEnv(s:String):Null<String> {
		return untyped __elixir__('System.get_env({0})', s);
	}

	/**
	 * Sets the value of an environment variable.
	 * @param s The name of the environment variable
	 * @param v The value to set. If this value is null, the function removes the variable.
	 */
	public static inline function putEnv(s:String, v:Null<String>):Void {
		if (v == null) {
			untyped __elixir__('System.delete_env({0})', s);
		} else {
			untyped __elixir__('System.put_env({0}, {1})', s, v);
		}
	}

	/**
	 * Returns the current working directory.
	 * @return The current working directory path
	 */
	public static inline function getCwd():String {
		return untyped __elixir__('File.cwd!()');
	}

	/**
	 * Changes the current working directory.
	 * @param s The path to change to
	 */
	public static inline function setCwd(s:String):Void {
		untyped __elixir__('File.cd!({0})', s);
	}

	/**
	 * Returns the arguments passed to the program.
	 * @return An array of command-line arguments
	 */
	public static function args():Array<String> {
		return untyped __elixir__('System.argv()');
	}

	/**
	 * Exits the program with the specified exit code.
	 * @param code The exit code (0 for success)
	 */
	public static inline function exit(code:Int):Void {
		untyped __elixir__('System.halt({0})', code);
	}

	/**
	 * Executes a command and forwards its output to the current process.
	 * If args is null, cmd can contain shell syntax.
	 * If args is present, each array item is one direct command argument.
	 * @param cmd The command to execute
	 * @param args Optional arguments for the command
	 * @return The exit code of the command
	 */
	public static function command(cmd:String, ?args:Array<String>):Int {
		if (args == null) {
			return untyped __elixir__('
                {shell, shell_args} =
                  case :os.type() do
                    {:win32, _} -> {"cmd", ["/d", "/s", "/c", {0}]}
                    _ -> {"sh", ["-c", {0}]}
                  end

				case System.cmd(shell, shell_args) do
                    {output, code} ->
                      IO.write(output)
                      code
                end', cmd);
		} else {
			return untyped __elixir__('
				case System.cmd({0}, {1}) do
                    {output, code} ->
                      IO.write(output)
                      code
                end', cmd, args);
		}
	}

	/**
	 * Returns the current system time in seconds since Unix epoch.
	 * @return The current time in seconds
	 */
	public static inline function time():Float {
		return untyped __elixir__('System.system_time(:nanosecond) / 1_000_000_000.0');
	}

	/**
	 * Returns the current CPU time used by the process.
	 * @return The CPU time in seconds
	 */
	public static inline function cpuTime():Float {
		return untyped __elixir__('
            {total, _} = :erlang.statistics(:runtime)
            total / 1000.0
        ');
	}

	/**
	 * Suspends execution for the specified number of seconds.
	 * @param seconds The number of seconds to sleep
	 */
	public static inline function sleep(seconds:Float):Void {
		var milliseconds = Std.int(seconds * 1000);
		untyped __elixir__('Process.sleep({0})', milliseconds);
	}

	/**
	 * Returns the Haxe name for the operating system.
	 * @return One of "BSD", "Linux", "Mac", or "Windows"
	 */
	public static function systemName():String {
		return untyped __elixir__('
            case :os.type() do
                {:unix, :linux} -> "Linux"
                {:unix, :darwin} -> "Mac"
                {:win32, _} -> "Windows"
                {:unix, _} -> "BSD"
                _ -> "BSD"
            end
        ');
	}

	/**
	 * Returns the path to the executable that started the current process.
	 * @return The executable path
	 */
	public static function executablePath():String {
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
	public static function programPath():String {
		// Similar to executablePath for Elixir
		return executablePath();
	}

	/**
	 * Sets the time locale for the current process.
	 * @param loc The locale string (e.g., "en_US", "de_DE")
	 * @return True if the locale was set successfully
	 */
	public static function setTimeLocale(loc:String):Bool {
		// BEAM has no process-wide setlocale operation that changes DateTools.
		// Report the unsupported change instead of recording an unused setting.
		return untyped __elixir__('(is_binary({0}) and false)', loc);
	}
}
