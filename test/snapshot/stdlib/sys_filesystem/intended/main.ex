defmodule Main do
  def main() do
    exists = FileSystem.exists("/tmp")
    if (exists), do: nil
    tmp_path = "/tmp/reflaxe_elixir_stdlib_sys_test.txt"
    _ = File.save_content(tmp_path, "hello")
    _content = File.get_content(tmp_path)
    bytes = Bytes.of_string("bin", nil)
    _ = File.save_bytes(tmp_path, bytes)
    _read_bytes = File.get_bytes(tmp_path)
    nil
  end
end
