package sys.io;

import elixir.types.Term;
import haxe.io.Bytes;
import haxe.io.Eof;

/**
 * sys.io.Process (Elixir target)
 *
 * WHAT
 * - BEAM-backed implementation of Haxe's `sys.io.Process` API for spawning and
 *   communicating with OS processes.
 *
 * WHY
 * - `sys.io.Process` is `extern` in the upstream stdlib and requires a target
 *   implementation. Many Haxe tools and libraries depend on it (e.g. running
 *   compilers, invoking CLIs, reading command output).
 *
 * HOW
 * - Uses Elixir/Erlang ports (`Port.open/2`) with `:binary` + `:exit_status`.
 * - When `args` are provided, runs the executable directly (no shell).
 * - When `args` is `null`, runs via `sh -c` to match the Haxe contract.
 * - `stderr` is redirected into `stdout` (BEAM ports do not provide separate
 *   stderr streams without external drivers); both fields reference `stdout`.
 */
class Process {
    /** Standard output stream (merged stdout+stderr). */
    public var stdout(default, null): haxe.io.Input;

    /** Standard error stream (merged into `stdout` on BEAM). */
    public var stderr(default, null): haxe.io.Input;

    /** Standard input stream. */
    public var stdin(default, null): haxe.io.Output;

    final port: Term;
    var exitCodeCache: Null<Int> = null;
    var isClosed: Bool = false;

    public function new(cmd: String, ?args: Array<String>, ?detached: Bool): Void {
        var useStdio = detached != true;

        if (args == null) {
            port = openShellCommand(cmd, useStdio);
        } else {
            port = openExecutable(cmd, args, useStdio);
        }

        if (useStdio) {
            var mergedOutput = new PortInput(port);
            stdout = mergedOutput;
            stderr = mergedOutput;
            stdin = new PortOutput(port);
        } else {
            var disabledInput = new DisabledInput();
            stdout = disabledInput;
            stderr = disabledInput;
            stdin = new DisabledOutput();
        }
    }

    public function getPid(): Int {
        return untyped __elixir__('
            port = {0}
            case :erlang.port_info(port, :os_pid) do
              {:os_pid, pid} -> pid
              _ -> -1
            end
        ', port);
    }

    public function exitCode(block: Bool = true): Null<Int> {
        if (exitCodeCache != null) return exitCodeCache;

        var maybe: Null<Int> = untyped __elixir__('
            port = {0}
            receive do
              {^port, {:exit_status, status}} -> status
            after 0 ->
              nil
            end
        ', port);

        if (maybe != null) {
            exitCodeCache = maybe;
            return maybe;
        }

        if (!block) return null;

        var status: Int = untyped __elixir__('
            port = {0}
            receive do
              {^port, {:exit_status, status}} -> status
            end
        ', port);

        exitCodeCache = status;
        return status;
    }

    public function close(): Void {
        if (isClosed) return;
        isClosed = true;

        // Best-effort: close the port if still alive.
        untyped __elixir__('
            port = {0}
            if Port.info(port) != nil do
              Port.close(port)
            end
        ', port);
    }

    public function kill(): Void {
        // `Port.close/1` terminates the OS process backing the port.
        close();
    }

    static function openExecutable(cmd: String, args: Array<String>, useStdio: Bool): Term {
        var executable: Null<String> = untyped __elixir__('System.find_executable({0})', cmd);
        if (executable == null) {
            throw "sys.io.Process: executable not found: " + cmd;
        }

        return untyped __elixir__('
            stdio_opt = if {2}, do: :use_stdio, else: :nouse_stdio
            opts = [:binary, :exit_status, stdio_opt, {:args, {1}}]
            opts = if {2}, do: [:stderr_to_stdout | opts], else: opts
            Port.open({:spawn_executable, {0}}, opts)
        ', executable, args, useStdio);
    }

    static function openShellCommand(cmd: String, useStdio: Bool): Term {
        var shell: Null<String> = untyped __elixir__('System.find_executable("sh")');
        if (shell == null) {
            throw "sys.io.Process: shell executable not found (sh)";
        }

        return untyped __elixir__('
            stdio_opt = if {2}, do: :use_stdio, else: :nouse_stdio
            opts = [:binary, :exit_status, stdio_opt, {:args, ["-c", {1}]}]
            opts = if {2}, do: [:stderr_to_stdout | opts], else: opts
            Port.open({:spawn_executable, {0}}, opts)
        ', shell, cmd, useStdio);
    }
}

private class PortInput extends haxe.io.Input {
    final port: Term;
    var buffer: Bytes = null;
    var bufferOffset: Int = 0;
    var ended: Bool = false;

    public function new(port: Term) {
        this.port = port;
    }

    override public function readByte(): Int {
        if (!ensureBuffered()) {
            throw new Eof();
        }

        var value = buffer.get(bufferOffset);
        bufferOffset += 1;
        return value;
    }

    override public function readBytes(buf: Bytes, pos: Int, len: Int): Int {
        if (pos < 0 || len < 0 || pos + len > buf.length) {
            throw haxe.io.Error.OutsideBounds;
        }
        if (len == 0) return 0;

        var totalRead = 0;
        while (totalRead < len) {
            if (!ensureBuffered()) {
                break;
            }

            var available = buffer.length - bufferOffset;
            var remaining = len - totalRead;
            var toCopy = remaining < available ? remaining : available;

            buf.blit(pos + totalRead, buffer, bufferOffset, toCopy);
            bufferOffset += toCopy;
            totalRead += toCopy;
        }

        if (totalRead == 0) {
            throw new Eof();
        }

        return totalRead;
    }

    function ensureBuffered(): Bool {
        if (ended) return false;

        if (buffer != null && bufferOffset < buffer.length) {
            return true;
        }

        buffer = null;
        bufferOffset = 0;

        var data: Term = receiveDataNonBlocking();
        if (data != null) {
            buffer = Bytes.ofData(data);
            return true;
        }

        if (!isPortOpen()) {
            ended = true;
            return false;
        }

        var message: Term = receiveDataOrExitBlocking();
        var tag: Term = untyped __elixir__('elem({0}, 0)', message);

        if (untyped __elixir__('{0} == :data', tag)) {
            var payload: Term = untyped __elixir__('elem({0}, 1)', message);
            buffer = Bytes.ofData(payload);
            return true;
        }

        if (untyped __elixir__('{0} == :exit', tag)) {
            // Preserve the exit status for `Process.exitCode/1`.
            var status: Term = untyped __elixir__('elem({0}, 1)', message);
            untyped __elixir__('send(self(), {{0}, {:exit_status, {1}}})', port, status);
            ended = true;
            return false;
        }

        ended = true;
        return false;
    }

    inline function isPortOpen(): Bool {
        return untyped __elixir__('Port.info({0}) != nil', port);
    }

    function receiveDataNonBlocking(): Term {
        return untyped __elixir__('
            port = {0}
            receive do
              {^port, {:data, data}} -> data
            after 0 ->
              nil
            end
        ', port);
    }

    function receiveDataOrExitBlocking(): Term {
        return untyped __elixir__('
            port = {0}
            receive do
              {^port, {:data, data}} -> {:data, data}
              {^port, {:exit_status, status}} -> {:exit, status}
            end
        ', port);
    }
}

private class PortOutput extends haxe.io.Output {
    final port: Term;

    public function new(port: Term) {
        this.port = port;
    }

    override public function writeByte(c: Int): Void {
        untyped __elixir__('Port.command({0}, <<{1}::8>>)', port, c);
    }

    override public function writeBytes(b: Bytes, pos: Int, len: Int): Int {
        if (pos < 0 || len < 0 || pos + len > b.length) {
            throw haxe.io.Error.OutsideBounds;
        }
        if (len == 0) return 0;

        var slice = b.sub(pos, len).getData();
        untyped __elixir__('Port.command({0}, {1})', port, slice);
        return len;
    }

    override public function close(): Void {
        // Intentionally a no-op: closing stdin independently is not exposed by ports.
    }
}

private class DisabledInput extends haxe.io.Input {
    public function new() {}

    override public function readByte(): Int {
        throw new Eof();
    }

    override public function readBytes(buf: Bytes, pos: Int, len: Int): Int {
        throw new Eof();
    }
}

private class DisabledOutput extends haxe.io.Output {
    public function new() {}

    override public function writeByte(c: Int): Void {
        throw "sys.io.Process: stdin is not available for detached processes";
    }

    override public function writeBytes(b: Bytes, pos: Int, len: Int): Int {
        throw "sys.io.Process: stdin is not available for detached processes";
    }
}
