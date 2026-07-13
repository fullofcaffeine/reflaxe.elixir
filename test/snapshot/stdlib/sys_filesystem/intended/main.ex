defmodule Main do
  def main() do
    exists = FileSystem.exists("/tmp")
    if (exists), do: nil
    tmp_path = "/tmp/reflaxe_elixir_stdlib_sys_test.txt"
    Sys.IO.File.save_content(tmp_path, "hello")
    _content = Sys.IO.File.get_content(tmp_path)
    bytes = Bytes.of_string("bin", {:utf8})
    Sys.IO.File.save_bytes(tmp_path, bytes)
    _read_bytes = Sys.IO.File.get_bytes(tmp_path)
    nil
  end
end
