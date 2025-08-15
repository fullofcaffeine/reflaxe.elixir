defmodule Main do
  @moduledoc """
  Main module generated from Haxe
  
  
 * Test suite for essential standard library extern definitions
 * Tests that all extern definitions compile correctly and generate proper Elixir code
 
  """

  # Static functions
  @doc "Function main"
  @spec main() :: nil
  def main() do
    Main.testProcessExterns()
    Main.testRegistryExterns()
    Main.testAgentExterns()
    Main.testIOExterns()
    Main.testFileExterns()
    Main.testPathExterns()
    Main.testEnumExterns()
    Main.testStringExterns()
    Main.testGenServerExterns()
  end

  @doc "Function test_process_externs"
  @spec test_process_externs() :: nil
  def test_process_externs() do
    pid = Process.self()
    Process.send(pid, "hello")
    Process.exit(pid, "normal")
    new_pid = Process.spawn(fn  -> IO.puts("Hello from spawned process") end)
    Process.monitor(new_pid)
    Process.link(new_pid)
    Process.alive?(pid)
    Process.info(pid)
  end

  @doc "Function test_registry_externs"
  @spec test_registry_externs() :: nil
  def test_registry_externs() do
    Registry.start_link("unique", "MyRegistry")
    Registry.register("MyRegistry", "user:123", "user_data")
    Registry.lookup("MyRegistry", "user:123")
    Registry.count("MyRegistry")
    Registry.keys("MyRegistry", Process.self())
    _g = Haxe.Ds.StringMap.new()
    _g.set("keys", "unique")
    _g.set("name", "TestRegistry")
    temp_maybe_var = nil
    results = Registry.lookup("MyRegistry", "user:123")
    if (length(results) > 0), do: temp_maybe_var = Enum.at(results, 0)._0, else: temp_maybe_var = nil
  end

  @doc "Function test_agent_externs"
  @spec test_agent_externs() :: nil
  def test_agent_externs() do
    Agent.start_link(fn  -> 0 end)
    Agent.get(nil, fn count -> count end)
    Agent.update(nil, fn count -> count + 1 end)
    Agent.cast(nil, fn count -> count + 1 end)
    Agent.start_link(fn  -> 10 end)
    agent = nil
    Agent.update(agent, fn count -> count + 5 end)
    temp_number = nil
    agent = nil
    temp_number = Agent.get(agent, fn count -> count end)
    temp_number
    Agent.start_link(fn  -> nil end)
    agent = nil
    Agent.update(agent, fn state -> state end)
    temp_var = nil
    agent = nil
    temp_var = Agent.get(agent, fn state -> nil end)
    temp_var
  end

  @doc "Function test_i_o_externs"
  @spec test_i_o_externs() :: nil
  def test_i_o_externs() do
    IO.puts("Hello, World!")
    IO.write("Hello ")
    IO.inspect([1, 2, 3])
    IO.gets("Enter something: ")
    IO.read(1)
    IO.puts("Using helper function")
    IO.puts("stderr", "This is an error message")
    label = "label"
    if (label == nil), do: label = "", else: nil
    if (label != ""), do: IO.puts(label <> ": "), else: nil
    IO.inspect("Debug value")
    color = IO.i_o._a_n_s_i.red
    IO.write(color <> "Error text" <> IO.i_o._a_n_s_i.reset)
    color = IO.i_o._a_n_s_i.green
    IO.write(color <> "Success text" <> IO.i_o._a_n_s_i.reset)
    color = IO.i_o._a_n_s_i.blue
    IO.write(color <> "Info text" <> IO.i_o._a_n_s_i.reset)
    temp_string = nil
    label = "Array"
    if (label == nil), do: label = "", else: nil
    result = IO.iodata_to_binary(IO.inspect([1, 2, 3]))
    if (label != ""), do: temp_string = label <> ": " <> result, else: temp_string = result
  end

  @doc "Function test_file_externs"
  @spec test_file_externs() :: nil
  def test_file_externs() do
    File.read("test.txt")
    File.read!("test.txt")
    File.write("output.txt", "Hello, File!")
    File.write!("output2.txt", "Hello again!")
    File.stat("test.txt")
    File.exists?("test.txt")
    File.regular?("test.txt")
    File.dir?("directory")
    File.mkdir("new_directory")
    File.ls(".")
    File.copy("source.txt", "dest.txt")
    File.rename("old.txt", "new.txt")
    temp_maybe_string = nil
    result = File.read("text_file.txt")
    if (result._0 == "ok"), do: temp_maybe_string = result._1, else: temp_maybe_string = nil
    temp_bool = nil
    result = File.write("output.txt", "content")
    temp_bool = result._0 == "ok"
    temp_bool
    temp_maybe_array = nil
    temp_maybe_string1 = nil
    result = File.read("multi_line.txt")
    if (result._0 == "ok"), do: temp_maybe_string1 = result._1, else: temp_maybe_string1 = nil
    if (temp_maybe_string1 != nil), do: temp_maybe_array = temp_maybe_string1.split("\n"), else: temp_maybe_array = nil
    temp_bool1 = nil
    result = File.mkdir_p("new_dir")
    temp_bool1 = result._0 == "ok"
    temp_bool1
  end

  @doc "Function test_path_externs"
  @spec test_path_externs() :: nil
  def test_path_externs() do
    Path.join(["home", "user", "documents"])
    Path.join("/home", "user")
    Path.basename("/home/user/file.txt")
    Path.dirname("/home/user/file.txt")
    Path.extname("/home/user/file.txt")
    Path.rootname("/home/user/file.txt")
    Path.absname?("/home/user")
    Path.type("/home/user")
    Path.expand("~/documents")
    Path.relative_to_cwd("/home/user/documents")
    Path.wildcard("*.txt")
    Path.basename("/home/user/file.txt")
    Path.rootname(Path.basename("/home/user/file.txt"))
    temp_string = nil
    ext = Path.extname("/home/user/file.txt")
    if (String.length(ext) > 0 && String.at(ext, 0) == "."), do: temp_string = String.slice(ext, 1..-1), else: temp_string = ext
    Path.join(["home", "user", "file.txt"])
  end

  @doc "Function test_enum_externs"
  @spec test_enum_externs() :: nil
  def test_enum_externs() do
    test_array = [1, 2, 3, 4, 5]
    Enum.count(test_array)
    Enum.empty?(test_array)
    Enum.member?(test_array, 3)
    Enum.at(test_array, 0)
    Enum.find(test_array, fn x -> x > 3 end)
    Enum.map(test_array, fn x -> x * 2 end)
    Enum.filter(test_array, fn x -> x rem 2 == 0 end)
    Enum.reduce(test_array, 0, fn acc, x -> acc + x end)
    Enum.sum(test_array)
    Enum.max(test_array)
    Enum.min(test_array)
    Enum.take(test_array, 3)
    Enum.drop(test_array, 2)
    Enum.reverse(test_array)
    Enum.sort(test_array)
    Enum.count(test_array)
    Enum.at(test_array, 0)
    Enum.drop(test_array, 1)
    Enum.map(test_array, fn x -> Std.string(x) end)
  end

  @doc "Function test_string_externs"
  @spec test_string_externs() :: nil
  def test_string_externs() do
    test_string = "  Hello, World!  "
    String.length(test_string)
    String.byte_size(test_string)
    String.valid?(test_string)
    String.downcase(test_string)
    String.upcase(test_string)
    String.capitalize(test_string)
    String.trim(test_string)
    String.trim_leading(test_string)
    String.pad_leading("hello", 10)
    String.slice(test_string, 2, 5)
    String.at(test_string, 0)
    String.first(test_string)
    String.last(test_string)
    String.contains?(test_string, "Hello")
    String.starts_with?(test_string, "  Hello")
    String.ends_with?(test_string, "!  ")
    String.replace(test_string, "World", "Elixir")
    String.replace_prefix(test_string, "  ", "")
    String.split("a,b,c")
    String.split("a,b,c", ",")
    String.split_at(test_string, 5)
    String.to_integer("123")
    String.to_float("123.45")
    String.length("") == 0
    string = String.trim("   ")
    String.length(string) == 0
    temp_bool
    temp_string = nil
    pad_with = "0"
    if (pad_with == nil), do: pad_with = " ", else: nil
    if (String.length("test") >= 10), do: temp_string = "test", else: temp_string = String.pad_leading("test", 10, pad_with)
    String.duplicate("ha", 3)
  end

  @doc "Function test_gen_server_externs"
  @spec test_gen_server_externs() :: nil
  def test_gen_server_externs() do
    GenServer.start_link("MyGenServer", "init_arg")
    GenServer.call(nil, "get_state")
    GenServer.cast(nil, "update_state")
    GenServer.stop(nil)
    :r_e_p_l_y
    "response"
    "new_state"
    :n_o_r_e_p_l_y
    "state"
    :s_t_o_p
    "normal"
    "final_state"
    GenServer.whereis("MyGenServer")
  end

end
