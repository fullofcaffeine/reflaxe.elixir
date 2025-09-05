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
    pid = Process.self()
    Process.send(pid, "hello")
    Process.exit(pid, "normal")
    new_pid = Process.spawn(fn -> IO.puts("Hello from spawned process") end)
    Process.monitor(new_pid)
    Process.link(new_pid)
    alive = Process.alive?(pid)
    info = Process.info(pid)
  end
  defp test_registry_externs() do
    _registry_spec = {:"Registry.start_link", %{:keys => :unique, :name => String.to_atom("MyRegistry")}}
    _register_result = {:"Registry.register", "MyRegistry", "user:123", "user_data"}
    _lookup_result = Registry.lookup("MyRegistry", "user:123")
    _count = Registry.count("MyRegistry")
    _keys = Registry.keys("MyRegistry", Process.self())
  end
  defp test_agent_externs() do
    _agent_result = {:"Agent.start_link", fn -> 0 end}
    state = Agent.get(nil, fn count -> count end)
    Agent.update(nil, fn count -> count + 1 end)
    Agent.cast(nil, fn count -> count + 1 end)
    counter_agent = {:"Agent.start_link", fn -> 10 end}
    agent = nil
    Agent.update(agent, fn count -> count + 5 end)
    agent = nil
    current_count = Agent.get(agent, fn count -> count end)
  end
  defp test_io_externs() do
    IO.puts("Hello, World!")
    IO.write("Hello ")
    IO.inspect([1, 2, 3])
    _input = IO.gets("Enter something: ")
    _char = IO.read(1)
    IO.puts("Using helper function")
    IO.puts("stderr", "This is an error message")
    label = "label"
    if (label == nil) do
      label = ""
    end
    if (label != "") do
      IO.puts(label <> ": ")
    end
    IO.inspect("Debug value")
    color = IO.IO.ANSI.red
    IO.write(color <> "Error text" <> IO.IO.ANSI.reset)
    color = IO.IO.ANSI.green
    IO.write(color <> "Success text" <> IO.IO.ANSI.reset)
    color = IO.IO.ANSI.blue
    IO.write(color <> "Info text" <> IO.IO.ANSI.reset)
    label = "Array"
    label = ""
    result = IO.iodata_to_binary(IO.inspect([1, 2, 3]))
    _formatted = if label == nil, do: label
if label != "", do: label <> ": " <> result, else: result
  end
  defp test_file_externs() do
    _read_result = File.read("test.txt")
    _content = File.read!("test.txt")
    _write_result = File.write("output.txt", "Hello, File!")
    File.write!("output2.txt", "Hello again!")
    _stat_result = File.stat("test.txt")
    _exists = File.exists?("test.txt")
    _is_file = File.regular?("test.txt")
    _is_dir = File.dir?("directory")
    _mkdir_result = File.mkdir("new_directory")
    _ls_result = File.ls(".")
    _copy_result = File.copy("source.txt", "dest.txt")
    _rename_result = File.rename("old.txt", "new.txt")
    result = File.read("text_file.txt")
    _text_content = if result[:_0] == "ok" do
  result[:_1]
else
  nil
end
    result = File.write("output.txt", "content")
    _write_success = result[:_0] == "ok"
    result = File.read("multi_line.txt")
    content = if result[:_0] == "ok" do
  result[:_1]
else
  nil
end
    _lines = content
if content != nil, do: content.split("\n"), else: nil
    result = File.mkdir_p("new_dir")
    _dir_created = result[:_0] == "ok"
  end
  defp test_path_externs() do
    _joined = Path.join(["home", "user", "documents"])
    _joined_two = Path.join("/home", "user")
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
    _ext = if ext.length > 0 && ext.charAt(0) == ".", do: ext.substr(1), else: ext
    _combined = Path.join(["home", "user", "file.txt"])
  end
  defp test_enum_externs() do
    test_array = [1, 2, 3, 4, 5]
    _count = Enum.count(test_array)
    _is_empty = Enum.empty?(test_array)
    _contains = Enum.member?(test_array, 3)
    _first = Enum.at(test_array, 0)
    _found = Enum.find(test_array, fn x -> x > 3 end)
    doubled = Enum.map(test_array, fn x -> x * 2 end)
    filtered = Enum.filter(test_array, fn x -> x rem 2 == 0 end)
    reduced = Enum.reduce(test_array, 0, fn acc, x -> acc + x end)
    sum = Enum.sum(test_array)
    max = Enum.max(test_array)
    min = Enum.min(test_array)
    taken = Enum.take(test_array, 3)
    dropped = Enum.drop(test_array, 2)
    reversed = Enum.reverse(test_array)
    sorted = Enum.sort(test_array)
    size = Enum.count(test_array)
    head = Enum.at(test_array, 0)
    tail = Enum.drop(test_array, 1)
    collected = Enum.map(test_array, fn x -> Std.string(x) end)
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
    pad_with = " "
    _left_padded = if pad_with == nil, do: pad_with
if String.length("test") >= 10 do
  "test"
else
  String.pad_leading("test", 10, pad_with)
end
    _repeated = String.duplicate("ha", 3)
  end
  defp test_gen_server_externs() do
    _start_result = {:"GenServer.start_link", "MyGenServer", "init_arg"}
    server_ref = nil
    _call_result = GenServer.call(server_ref, "get_state")
    GenServer.cast(server_ref, "update_state")
    GenServer.stop(server_ref)
    _pid = GenServer.whereis(server_ref)
    _infinity = :infinity
    _normal = :normal
    _shutdown = :shutdown
  end
end