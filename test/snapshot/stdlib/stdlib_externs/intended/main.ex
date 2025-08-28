defmodule Main do
  @moduledoc """
    Main module generated from Haxe

     * Test suite for essential standard library extern definitions
     * Tests that all extern definitions compile correctly and generate proper Elixir code
  """

  # Static functions
  @doc "Generated from Haxe main"
  def main() do
    Main.test_process_externs()

    Main.test_registry_externs()

    Main.test_agent_externs()

    Main.test_i_o_externs()

    Main.test_file_externs()

    Main.test_path_externs()

    Main.test_enum_externs()

    Main.test_string_externs()

    Main.test_gen_server_externs()
  end

  @doc "Generated from Haxe testProcessExterns"
  def test_process_externs() do
    pid = Process.self(Process)

    Process.send(Process, pid, "hello")

    Process.exit(Process, pid, "normal")

    new_pid = Process.spawn(Process, fn  -> IO.puts(IO, "Hello from spawned process") end)

    Process.monitor(Process, new_pid)

    Process.link(Process, new_pid)

    _alive = Process.alive?(Process, pid)

    _info = Process.info(Process, pid)
  end

  @doc "Generated from Haxe testRegistryExterns"
  def test_registry_externs() do
    temp_maybe_var = nil

    _registry_spec = Registry.start_link(Registry, "unique", "MyRegistry")

    _register_result = Registry.register(Registry, "MyRegistry", "user:123", "user_data")

    _lookup_result = Registry.lookup(Registry, "MyRegistry", "user:123")

    _count = Registry.count(Registry, "MyRegistry")

    _keys = Registry.keys(Registry, "MyRegistry", Process.self(Process))

    g_array = StringMap.new()

    g_array = Map.put(g_array, "keys", "unique")

    g_array = Map.put(g_array, "name", "TestRegistry")

    temp_maybe_var = nil

    results = Registry.lookup(Registry, "MyRegistry", "user:123")

    if ((results.length > 0)), do: temp_maybe_var = Enum.at(results, 0).0, else: temp_maybe_var = nil
  end

  @doc "Generated from Haxe testAgentExterns"
  def test_agent_externs() do
    temp_number = nil
    temp_var = nil

    _agent_result = Agent.start_link(Agent, fn  -> 0 end)

    _state = Agent.get(Agent, nil, fn count -> count end)

    Agent.update(Agent, nil, fn count -> (count + 1) end)

    Agent.cast(Agent, nil, fn count -> (count + 1) end)

    _counter_agent = Agent.start_link(Agent, fn  -> 10 end)

    agent = nil
    Agent.update(Agent, agent, fn count -> (count + 5) end)

    temp_number = nil

    agent = nil
    temp_number = Agent.get(Agent, agent, fn count -> count end)

    _current_count = temp_number

    _map_agent = Agent.start_link(Agent, fn  -> nil end)

    agent = nil
    Agent.update(Agent, agent, fn state -> state end)

    temp_var = nil

    agent = nil
    temp_var = Agent.get(Agent, agent, fn state -> nil end)

    _value = temp_var
  end

  @doc "Generated from Haxe testIOExterns"
  def test_i_o_externs() do
    temp_string = nil

    IO.puts(IO, "Hello, World!")

    IO.write(IO, "Hello ")

    IO.inspect(IO, [1, 2, 3])

    _input = IO.gets(IO, "Enter something: ")

    _char = IO.read(IO, 1)

    IO.puts(IO, "Using helper function")

    IO.puts(IO, "stderr", "This is an error message")

    label = "label"
    if ((label == nil)), do: label = "", else: nil
    if ((label != "")), do: IO.puts(IO, label <> ": "), else: nil
    IO.inspect(IO, "Debug value")

    color = IO.i_o._a_n_s_i.red
    IO.write(IO, color <> "Error text" <> IO.i_o._a_n_s_i.reset)

    color = IO.i_o._a_n_s_i.green
    IO.write(IO, color <> "Success text" <> IO.i_o._a_n_s_i.reset)

    color = IO.i_o._a_n_s_i.blue
    IO.write(IO, color <> "Info text" <> IO.i_o._a_n_s_i.reset)

    temp_string = nil

    label = "Array"
    if ((label == nil)), do: label = "", else: nil
    result = IO.iodata_to_binary(IO, IO.inspect(IO, [1, 2, 3]))
    if ((label != "")), do: temp_string = label <> ": " <> result, else: temp_string = result
  end

  @doc "Generated from Haxe testFileExterns"
  def test_file_externs() do
    temp_maybe_string = nil
    temp_bool = nil
    temp_maybe_string1 = nil
    temp_maybe_array = nil
    temp_bool1 = nil

    _read_result = File.read(File, "test.txt")

    _content = File.read!(File, "test.txt")

    _write_result = File.write(File, "output.txt", "Hello, File!")

    File.write!(File, "output2.txt", "Hello again!")

    _stat_result = File.stat(File, "test.txt")

    _exists = File.exists?(File, "test.txt")

    _is_file = File.regular?(File, "test.txt")

    _is_dir = File.dir?(File, "directory")

    _mkdir_result = File.mkdir(File, "new_directory")

    _ls_result = File.ls(File, ".")

    _copy_result = File.copy(File, "source.txt", "dest.txt")

    _rename_result = File.rename(File, "old.txt", "new.txt")

    temp_maybe_string = nil

    result = File.read(File, "text_file.txt")
    if ((result.0 == "ok")), do: temp_maybe_string = result.1, else: temp_maybe_string = nil

    temp_bool = nil

    result = File.write(File, "output.txt", "content")
    temp_bool = (result.0 == "ok")

    _write_success = temp_bool

    temp_maybe_string1 = nil

    result = File.read(File, "multi_line.txt")
    if ((result.0 == "ok")), do: temp_maybe_string1 = result.1, else: temp_maybe_string1 = nil

    if ((temp_maybe_string1 != nil)), do: temp_maybe_array = temp_maybe_string1.split("\n"), else: temp_maybe_array = nil

    temp_bool1 = nil

    result = File.mkdir_p(File, "new_dir")
    temp_bool1 = (result.0 == "ok")

    _dir_created = temp_bool1
  end

  @doc "Generated from Haxe testPathExterns"
  def test_path_externs() do
    temp_string = nil

    _joined = Path.join(Path, ["home", "user", "documents"])

    _joined_two = Path.join(Path, "/home", "user")

    _basename = Path.basename(Path, "/home/user/file.txt")

    _dirname = Path.dirname(Path, "/home/user/file.txt")

    _extension = Path.extname(Path, "/home/user/file.txt")

    _rootname = Path.rootname(Path, "/home/user/file.txt")

    _is_absolute = Path.absname?(Path, "/home/user")

    _path_type = Path.type(Path, "/home/user")

    _expanded = Path.expand(Path, "~/documents")

    _relative = Path.relative_to_cwd(Path, "/home/user/documents")

    _matches = Path.wildcard(Path, "*.txt")

    _filename = Path.basename(Path, "/home/user/file.txt")

    _filename_no_ext = Path.rootname(Path, Path.basename(Path, "/home/user/file.txt"))

    ext = Path.extname(Path, "/home/user/file.txt")
    if (((ext.length > 0) && (ext.char_at(0) == "."))), do: temp_string = ext.substr(1), else: temp_string = ext

    _combined = Path.join(Path, ["home", "user", "file.txt"])
  end

  @doc "Generated from Haxe testEnumExterns"
  def test_enum_externs() do
    test_array = [1, 2, 3, 4, 5]

    _count = Enum.count(Enum, test_array)

    _is_empty = Enum.empty?(Enum, test_array)

    _contains = Enum.member?(Enum, test_array, 3)

    _first = Enum.at(Enum, test_array, 0)

    _found = Enum.find(Enum, test_array, fn x -> (x > 3) end)

    _doubled = Enum.map(Enum, test_array, fn x -> (x * 2) end)

    _filtered = Enum.filter(Enum, test_array, fn x -> (rem(x, 2) == 0) end)

    _reduced = Enum.reduce(Enum, test_array, 0, fn acc, x -> (acc + x) end)

    _sum = Enum.sum(Enum, test_array)

    _max = Enum.max(Enum, test_array)

    _min = Enum.min(Enum, test_array)

    _taken = Enum.take(Enum, test_array, 3)

    _dropped = Enum.drop(Enum, test_array, 2)

    _reversed = Enum.reverse(Enum, test_array)

    _sorted = Enum.sort(Enum, test_array)

    _size = Enum.count(Enum, test_array)

    _head = Enum.at(Enum, test_array, 0)

    _tail = Enum.drop(Enum, test_array, 1)

    _collected = Enum.map(Enum, test_array, fn x -> Std.string(x) end)
  end

  @doc "Generated from Haxe testStringExterns"
  def test_string_externs() do
    temp_bool = nil
    temp_string = nil

    test_string = "  Hello, World!  "

    _length = String.length(String, test_string)

    _byte_size = String.byte_size(String, test_string)

    _is_valid = String.valid?(String, test_string)

    _lower = String.downcase(String, test_string)

    _upper = String.upcase(String, test_string)

    _capitalized = String.capitalize(String, test_string)

    _trimmed = String.trim(String, test_string)

    _left_trimmed = String.trim_leading(String, test_string)

    _padded = String.pad_leading(String, "hello", 10)

    _slice = String.slice(String, test_string, 2, 5)

    _char_at = String.at(String, test_string, 0)

    _first = String.first(String, test_string)

    _last = String.last(String, test_string)

    _contains = String.contains?(String, test_string, "Hello")

    _starts_with = String.starts_with?(String, test_string, "  Hello")

    _ends_with = String.ends_with?(String, test_string, "!  ")

    _replaced = String.replace(String, test_string, "World", "Elixir")

    _prefix_replaced = String.replace_prefix(String, test_string, "  ", "")

    _split = String.split(String, "a,b,c")

    _split_on = String.split(String, "a,b,c", ",")

    _split_at = String.split_at(String, test_string, 5)

    _to_int_result = String.to_integer(String, "123")

    _to_float_result = String.to_float(String, "123.45")

    _is_empty = (String.length(String, "") == 0)

    string = String.trim(String, "   ")

    _temp_bool = (String.length(String, string) == 0)

    _is_blank = _temp_bool

    pad_with = "0"

    if ((pad_with == nil)), do: pad_with = " ", else: nil

    if ((String.length(String, "test") >= 10)), do: temp_string = "test", else: temp_string = String.pad_leading(String, "test", 10, pad_with)

    _repeated = String.duplicate(String, "ha", 3)
  end

  @doc "Generated from Haxe testGenServerExterns"
  def test_gen_server_externs() do
    _start_result = GenServer.start_link(GenServer, "MyGenServer", "init_arg")

    _call_result = GenServer.call(GenServer, nil, "get_state")

    GenServer.cast(GenServer, nil, "update_state")

    GenServer.stop(GenServer, nil)

    _reply_tuple__0 = :r_e_p_l_y

    _reply_tuple__1 = "response"

    _reply_tuple__2 = "new_state"

    _noreply_tuple__0 = :n_o_r_e_p_l_y

    _noreply_tuple__1 = "state"

    _stop_tuple__0 = :s_t_o_p

    _stop_tuple__1 = "normal"

    _stop_tuple__2 = "final_state"

    _pid = GenServer.whereis(GenServer, "MyGenServer")
  end

end
