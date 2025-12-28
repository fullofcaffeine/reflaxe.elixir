defmodule Main do
  def main() do
    _ = test_process_externs()
    _ = test_registry_externs()
    _ = test_agent_externs()
    _ = test_io_externs()
    _ = test_file_externs()
    _ = test_path_externs()
    _ = test_enum_externs()
    _ = test_string_externs()
    _ = test_gen_server_externs()
  end
  defp test_process_externs() do
    pid = Process.self()
    _ = Process.send(pid, "hello")
    _ = Process.exit(pid, "normal")
    new_pid = Process.spawn(fn -> IO.puts("Hello from spawned process") end)
    _ = Process.monitor(new_pid)
    _ = Process.link(new_pid)
    _alive = Process.alive?(pid)
    _info = Process.info(pid)
  end
  defp test_registry_externs() do
    _registry_spec = Registry.start_link(%{:keys => {:unique}, :name => String.to_atom("MyRegistry")})
    _register_result = Registry.register("MyRegistry", "user:123", "user_data")
    _lookup_result = Registry.lookup("MyRegistry", "user:123")
    _count = Registry.count("MyRegistry")
    _keys = Registry.keys("MyRegistry", Process.self())
  end
  defp test_agent_externs() do
    _agent_result = Agent.start_link(fn -> nil end)
    _state = Agent.get(nil, fn count -> count end)
    _ = Agent.update(nil, fn count -> count + 1 end)
    _ = Agent.cast(nil, fn count -> count + 1 end)
    _counter_agent = Agent.start_link(fn -> 10 end)
    agent = nil
    _ = Agent.update(agent, fn count -> count + 5 end)
    agent = nil
    _current_count = _ = Agent.get(agent, fn count -> count end)
  end
  defp test_io_externs() do
    _ = IO.puts("Hello, World!")
    _ = IO.write("Hello ")
    _ = IO.inspect([1, 2, 3])
    _input = IO.gets("Enter something: ")
    _char = IO.read(1)
    _ = IO.puts("Using helper function")
    _ = IO.puts("stderr", "This is an error message")
    label = "label"
    label = if (Kernel.is_nil(label)), do: "", else: label
    if (label != "") do
      IO.puts("#{(fn -> label end).()}: ")
    end
    _ = IO.inspect("Debug value")
    color = IO.io.ansi.red()
    _ = IO.write("#{(fn -> color end).()}Error text#{(fn -> IO.io.ansi.reset() end).()}")
    color = IO.io.ansi.green()
    _ = IO.write("#{(fn -> color end).()}Success text#{(fn -> IO.io.ansi.reset() end).()}")
    color = IO.io.ansi.blue()
    _ = IO.write("#{(fn -> color end).()}Info text#{(fn -> IO.io.ansi.reset() end).()}")
    label = "Array"
    label = if (Kernel.is_nil(label)), do: "", else: label
    result = IO.iodata_to_binary(IO.inspect([1, 2, 3]))
    _formatted = if (label != "") do
      "#{(fn -> label end).()}: #{(fn -> result end).()}"
    else
      result
    end
  end
  defp test_file_externs() do
    _read_result = File.read("test.txt")
    content = File.read!("test.txt")
    _write_result = File.write("output.txt", "Hello, File!")
    _ = File.write!("output2.txt", "Hello again!")
    _stat_result = File.stat("test.txt")
    _exists = File.exists?("test.txt")
    _is_file = File.regular?("test.txt")
    _is_dir = File.dir?("directory")
    _mkdir_result = File.mkdir("new_directory")
    _ls_result = File.ls(".")
    _copy_result = File.copy("source.txt", "dest.txt")
    _rename_result = File.rename("old.txt", "new.txt")
    result = File.read("text_file.txt")
    _text_content = if (result._0 == "ok"), do: result._1, else: nil
    result = File.write("output.txt", "content")
    _write_success = result._0 == "ok"
    result = File.read("multi_line.txt")
    content = if (result._0 == "ok"), do: result._1, else: nil
    _lines = if (not Kernel.is_nil(content)) do
      if ("\n" == "") do
        String.graphemes(content)
      else
        String.split(content, "\n")
      end
    else
      nil
    end
    result = File.mkdir_p("new_dir")
    _dir_created = result._0 == "ok"
  end
  defp test_path_externs() do
    _joined = Path.join(["home", "user", "documents"])
    _joined_two = Path.join((fn -> "/home" end).(), "user")
    _basename = Path.basename("/home/user/file.txt")
    _dirname = Path.dirname("/home/user/file.txt")
    _extension = Path.extname("/home/user/file.txt")
    _rootname = Path.rootname("/home/user/file.txt")
    _is_absolute = Path.absname?("/home/user")
    _path_type = Path.type("/home/user")
    _expanded = Path.expand("~/documents")
    _relative = Path.relative_to_cwd("/home/user/documents")
    _matches = Path.wildcard("*.txt")
    _filename = Path.basename("/home/user/file.txt")
    _filename_no_ext = Path.rootname(Path.basename("/home/user/file.txt"))
    ext = Path.extname("/home/user/file.txt")
    cond_value = String.at(ext, 0) || "" == "."
    _ext = if (String.length(ext) > 0 and cond_value) do
      String.slice(ext, 1..-1//1)
    else
      ext
    end
    _combined = Path.join(["home", "user", "file.txt"])
  end
  defp test_enum_externs() do
    test_array = [1, 2, 3, 4, 5]
    _count = Enum.count(test_array)
    _is_empty = Enum.empty?(test_array)
    _contains = Enum.member?(test_array, 3)
    _first = Enum.at(test_array, 0)
    _found = Enum.find(test_array, fn x -> x > 3 end)
    _doubled = Enum.map(test_array, fn x -> x * 2 end)
    _filtered = Enum.filter(test_array, fn x -> rem(x, 2) == 0 end)
    _reduced = Enum.reduce(test_array, 0, fn acc, x -> acc + x end)
    _sum = Enum.sum(test_array)
    _max = Enum.max(test_array)
    _min = Enum.min(test_array)
    _taken = Enum.take(test_array, 3)
    _dropped = Enum.drop(test_array, 2)
    _reversed = Enum.reverse(test_array)
    _sorted = Enum.sort(test_array)
    _size = Enum.count(test_array)
    _head = Enum.at(test_array, 0)
    _tail = Enum.drop(test_array, 1)
    _collected = Enum.map(test_array, fn x -> inspect(x) end)
  end
  defp test_string_externs() do
    test_string = "  Hello, World!  "
    _length = String.length(test_string)
    _byte_size = String.byte_size(test_string)
    _is_valid = String.valid?(test_string)
    _lower = String.downcase(test_string)
    _upper = String.upcase(test_string)
    _capitalized = String.capitalize(test_string)
    _trimmed = String.trim(test_string)
    _left_trimmed = String.trim_leading(test_string)
    _padded = String.pad_leading("hello", 10)
    _slice = String.slice(test_string, 2, 5)
    _char_at = String.at(test_string, 0)
    _first = String.first(test_string)
    _last = String.last(test_string)
    _contains = String.contains?(test_string, "Hello")
    _starts_with = String.starts_with?(test_string, "  Hello")
    _ends_with = String.ends_with?(test_string, "!  ")
    _replaced = String.replace(test_string, "World", "Elixir")
    _prefix_replaced = String.replace_prefix(test_string, "  ", "")
    _split = String.split("a,b,c")
    _split_on = String.split("a,b,c", ",")
    _split_at = String.split_at(test_string, 5)
    _to_int_result = String.to_integer("123")
    _to_float_result = String.to_float("123.45")
    _is_empty = String.length("") == 0
    string = String.trim("   ")
    _is_blank = String.length(string) == 0
    pad_with = "0"
    pad_with = if (Kernel.is_nil(pad_with)), do: " ", else: pad_with
    _left_padded = if (String.length("test") >= 10) do
      "test"
    else
      String.pad_leading("test", 10, pad_with)
    end
    _repeated = String.duplicate("ha", 3)
  end
  defp test_gen_server_externs() do
    _start_result = GenServer.start_link("MyGenServer", "init_arg")
    server_ref = nil
    _call_result = GenServer.call(server_ref, "get_state")
    _ = GenServer.cast(server_ref, "update_state")
    _ = GenServer.stop(server_ref)
    _pid = GenServer.whereis(server_ref)
    _infinity = :infinity
    _normal = :normal
    _shutdown = :shutdown
  end
end
