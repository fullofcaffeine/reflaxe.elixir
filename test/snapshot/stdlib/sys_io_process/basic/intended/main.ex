defmodule Main do
  def main() do
    p = Process.new("sh", ["-c", "printf hello"])
    _out = Bytes.to_string(Input.read_all(p.stdout, nil))
    _code = Process.exit_code(p, nil)
    _ = Process.close(p)
    detached = Process.new("sh", ["-c", "exit 3"], true)
    _detached_code = Process.exit_code(detached, nil)
    _ = Process.close(detached)
    nil
  end
end
