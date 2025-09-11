defmodule Main do
  def main() do
    test_process_externs()
    test_registry_externs()
    test_agent_externs()
    test_i_o_externs()
    test_file_externs()
    test_path_externs()
    test_enum_externs()
    test_string_externs()
    test_gen_server_externs()
  end
  defp test_process_externs() do
    pid = Process.process.self()
    Process.process.send(pid, "hello")
    Process.process.exit(pid, "normal")
    new_pid = Process.process.spawn(fn -> IO.i_o.puts("Hello from spawned process") end)
    Process.process.monitor(new_pid)
    Process.process.link(new_pid)
    alive = Process.process.alive?(pid)
    info = Process.process.info(pid)
  end
  defp test_registry_externs() do
    _registry_spec = Registry.registry.start_link(%{:keys => {:unique}, :name => String.to_atom("MyRegistry")})
    _register_result = Registry.registry.register("MyRegistry", "user:123", "user_data")
    _lookup_result = Registry.registry.lookup("MyRegistry", "user:123")
    _count = Registry.registry.count("MyRegistry")
    _keys = Registry.registry.keys("MyRegistry", Process.process.self())
  end
  defp test_agent_externs() do
    _agent_result = Agent.agent.start_link(fn -> 0 end)
    state = Agent.agent.get(nil, fn count -> count end)
    Agent.agent.update(nil, fn count -> count + 1 end)
    Agent.agent.cast(nil, fn count -> count + 1 end)
    counter_agent = Agent.agent.start_link(fn -> 10 end)
    agent = nil
    Agent.agent.update(agent, fn count -> count + 5 end)
    agent = nil
    current_count = Agent.agent.get(agent, fn count -> count end)
  end
  defp test_io_externs() do
    IO.i_o.puts("Hello, World!")
    IO.i_o.write("Hello ")
    IO.i_o.inspect([1, 2, 3])
    _input = IO.i_o.gets("Enter something: ")
    _char = IO.i_o.read(1)
    IO.i_o.puts("Using helper function")
    IO.i_o.puts("stderr", "This is an error message")
    label = "label"
    if (label == nil) do
      label = ""
    end
    if (label != "") do
      IO.i_o.puts(label <> ": ")
    end
    IO.i_o.inspect("Debug value")
    color = IO.i_o._a_n_s_i.red
    IO.i_o.write(color <> "Error text" <> IO.i_o._a_n_s_i.reset)
    color = IO.i_o._a_n_s_i.green
    IO.i_o.write(color <> "Success text" <> IO.i_o._a_n_s_i.reset)
    color = IO.i_o._a_n_s_i.blue
    IO.i_o.write(color <> "Info text" <> IO.i_o._a_n_s_i.reset)
    label = "Array"
    label = ""
    result = IO.i_o.iodata_to_binary(IO.i_o.inspect([1, 2, 3]))
    _formatted = if label == nil, do: label
if label != "", do: label <> ": " <> result, else: result
  end
  defp test_file_externs() do
    _read_result = File.file.read("test.txt")
    _content = File.file.read!("test.txt")
    _write_result = File.file.write("output.txt", "Hello, File!")
    File.file.write!("output2.txt", "Hello again!")
    _stat_result = File.file.stat("test.txt")
    _exists = File.file.exists?("test.txt")
    _is_file = File.file.regular?("test.txt")
    _is_dir = File.file.dir?("directory")
    _mkdir_result = File.file.mkdir("new_directory")
    _ls_result = File.file.ls(".")
    _copy_result = File.file.copy("source.txt", "dest.txt")
    _rename_result = File.file.rename("old.txt", "new.txt")
    _text_content = if (elem(result, -1) == "ok"), do: elem((File.file.read("text_file.txt")), 0), else: nil
    _write_success = elem((File.file.write("output.txt", "content")), -1) == "ok"
    _lines = if (content != nil), do: (if (elem(result, -1) == "ok"), do: elem((File.file.read("multi_line.txt")), 0), else: nil).split("\n"), else: nil
    _dir_created = elem((File.file.mkdir_p("new_dir")), -1) == "ok"
  end
  defp test_path_externs() do
    _joined = Path.path.join(["home", "user", "documents"])
    _joined_two = Path.path.join("/home", "user")
    _basename = Path.path.basename("/home/user/file.txt")
    _dirname = Path.path.dirname("/home/user/file.txt")
    _extension = Path.path.extname("/home/user/file.txt")
    _rootname = Path.path.rootname("/home/user/file.txt")
    _is_absolute = Path.path.absname?("/home/user")
    _path_type = Path.path.type("/home/user")
    _expanded = Path.path.expand("~/documents")
    _relative = Path.path.relative_to_cwd("/home/user/documents")
    _matches = Path.path.wildcard("*.txt")
    _filename = Path.path.basename("/home/user/file.txt")
    _filename_no_ext = Path.path.rootname(Path.path.basename("/home/user/file.txt"))
    ext = Path.path.extname("/home/user/file.txt")
    _ext = if length(ext) > 0 && ext.char_at(0) == ".", do: ext.substr(1), else: ext
    _combined = Path.path.join(["home", "user", "file.txt"])
  end
  defp test_enum_externs() do
    test_array = [1, 2, 3, 4, 5]
    _count = Enum.enum.count(test_array)
    _is_empty = Enum.enum.empty?(test_array)
    _contains = Enum.enum.member?(test_array, 3)
    _first = Enum.enum.at(test_array, 0)
    _found = Enum.enum.find(test_array, fn x -> x > 3 end)
    doubled = Enum.enum.map(test_array, fn x -> x * 2 end)
    filtered = Enum.enum.filter(test_array, fn x -> rem(x, 2) == 0 end)
    reduced = Enum.enum.reduce(test_array, 0, fn acc, x -> acc + x end)
    sum = Enum.enum.sum(test_array)
    max = Enum.enum.max(test_array)
    min = Enum.enum.min(test_array)
    taken = Enum.enum.take(test_array, 3)
    dropped = Enum.enum.drop(test_array, 2)
    reversed = Enum.enum.reverse(test_array)
    sorted = Enum.enum.sort(test_array)
    size = Enum.enum.count(test_array)
    head = Enum.enum.at(test_array, 0)
    tail = Enum.enum.drop(test_array, 1)
    collected = Enum.enum.map(test_array, fn x -> Std.string(x) end)
  end
  defp test_string_externs() do
    test_string = "  Hello, World!  "
    _length = String.string.length(test_string)
    _byte_size = String.string.byte_size(test_string)
    _is_valid = String.string.valid?(test_string)
    _lower = String.string.downcase(test_string)
    _upper = String.string.upcase(test_string)
    _capitalized = String.string.capitalize(test_string)
    _trimmed = String.string.trim(test_string)
    _left_trimmed = String.string.trim_leading(test_string)
    _padded = String.string.pad_leading("hello", 10)
    _slice = String.string.slice(test_string, 2, 5)
    _char_at = String.string.at(test_string, 0)
    _first = String.string.first(test_string)
    _last = String.string.last(test_string)
    _contains = String.string.contains?(test_string, "Hello")
    _starts_with = String.string.starts_with?(test_string, "  Hello")
    _ends_with = String.string.ends_with?(test_string, "!  ")
    _replaced = String.string.replace(test_string, "World", "Elixir")
    _prefix_replaced = String.string.replace_prefix(test_string, "  ", "")
    _split = String.string.split("a,b,c")
    _split_on = String.string.split("a,b,c", ",")
    _split_at = String.string.split_at(test_string, 5)
    _to_int_result = String.string.to_integer("123")
    _to_float_result = String.string.to_float("123.45")
    _is_empty = String.string.length("") == 0
    string = String.string.trim("   ")
    _is_blank = String.string.length(string) == 0
    pad_with = "0"
    pad_with = " "
    _left_padded = if pad_with == nil, do: pad_with
if String.string.length("test") >= 10 do
  "test"
else
  String.string.pad_leading("test", 10, pad_with)
end
    _repeated = String.string.duplicate("ha", 3)
  end
  defp test_gen_server_externs() do
    _start_result = GenServer.gen_server.start_link("MyGenServer", "init_arg")
    server_ref = nil
    _call_result = GenServer.gen_server.call(server_ref, "get_state")
    GenServer.gen_server.cast(server_ref, "update_state")
    GenServer.gen_server.stop(server_ref)
    _pid = GenServer.gen_server.whereis(server_ref)
    _infinity = :infinity
    _normal = :normal
    _shutdown = :shutdown
  end
end