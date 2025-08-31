defmodule Main do
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
  defp testProcessExterns() do
    pid = Process.self()
    Process.send(pid, "hello")
    Process.exit(pid, "normal")
    new_pid = Process.spawn(fn -> IO.puts("Hello from spawned process") end)
    Process.monitor(new_pid)
    Process.link(new_pid)
    alive = Process.alive?(pid)
    info = Process.info(pid)
  end
  defp testRegistryExterns() do
    registry_spec = Registry.start_link("unique", "MyRegistry")
    register_result = Registry.register("MyRegistry", "user:123", "user_data")
    lookup_result = Registry.lookup("MyRegistry", "user:123")
    count = Registry.count("MyRegistry")
    keys = Registry.keys("MyRegistry", Process.self())
    unique_options = g = %{}
Map.put(g, "keys", "unique")
Map.put(g, "name", "TestRegistry")
g
    found_process = results = Registry.lookup("MyRegistry", "user:123")
if (results.length > 0) do
  results[0][:_0]
else
  nil
end
  end
  defp testAgentExterns() do
    agent_result = Agent.start_link(fn -> 0 end)
    state = Agent.get(nil, fn count -> count end)
    Agent.update(nil, fn count -> count + 1 end)
    Agent.cast(nil, fn count -> count + 1 end)
    counter_agent = Agent.start_link(fn -> 10 end)
    agent = nil
    Agent.update(agent, fn count -> count + 5 end)
    current_count = agent = nil
Agent.get(agent, fn count -> count end)
    map_agent = Agent.start_link(fn -> nil end)
    agent = nil
    Agent.update(agent, fn state -> state end)
    value = agent = nil
Agent.get(agent, fn state -> nil end)
  end
  defp testIOExterns() do
    IO.puts("Hello, World!")
    IO.write("Hello ")
    IO.inspect([1, 2, 3])
    input = IO.gets("Enter something: ")
    char = IO.read(1)
    IO.puts("Using helper function")
    IO.puts("stderr", "This is an error message")
    label = "label"
    if (label == nil) do
      label = ""
    end
    if (label != "") do
      IO.puts(label + ": ")
    end
    IO.inspect("Debug value")
    color = IO.IO.ANSI.red
    IO.write(color + "Error text" + IO.IO.ANSI.reset)
    color = IO.IO.ANSI.green
    IO.write(color + "Success text" + IO.IO.ANSI.reset)
    color = IO.IO.ANSI.blue
    IO.write(color + "Info text" + IO.IO.ANSI.reset)
    formatted = label = "Array"
if (label == nil) do
  label = ""
end
result = IO.iodata_to_binary(IO.inspect([1, 2, 3]))
if (label != ""), do: label + ": " + result, else: result
  end
  defp testFileExterns() do
    read_result = File.read("test.txt")
    content = File.read!("test.txt")
    write_result = File.write("output.txt", "Hello, File!")
    File.write!("output2.txt", "Hello again!")
    stat_result = File.stat("test.txt")
    exists = File.exists?("test.txt")
    is_file = File.regular?("test.txt")
    is_dir = File.dir?("directory")
    mkdir_result = File.mkdir("new_directory")
    ls_result = File.ls(".")
    copy_result = File.copy("source.txt", "dest.txt")
    rename_result = File.rename("old.txt", "new.txt")
    text_content = result = File.read("text_file.txt")
if (result[:_0] == "ok") do
  result[:_1]
else
  nil
end
    write_success = result = File.write("output.txt", "content")
result[:_0] == "ok"
    lines = content = result = File.read("multi_line.txt")
if (result[:_0] == "ok") do
  result[:_1]
else
  nil
end
if (content != nil), do: content.split("\n"), else: nil
    dir_created = result = File.mkdir_p("new_dir")
result[:_0] == "ok"
  end
  defp testPathExterns() do
    joined = Path.join(["home", "user", "documents"])
    joined_two = Path.join("/home", "user")
    basename = Path.basename("/home/user/file.txt")
    dirname = Path.dirname("/home/user/file.txt")
    extension = Path.extname("/home/user/file.txt")
    rootname = Path.rootname("/home/user/file.txt")
    is_absolute = Path.absname?("/home/user")
    path_type = Path.type("/home/user")
    expanded = Path.expand("~/documents")
    relative = Path.relative_to_cwd("/home/user/documents")
    matches = Path.wildcard("*.txt")
    filename = Path.basename("/home/user/file.txt")
    filename_no_ext = Path.rootname(Path.basename("/home/user/file.txt"))
    ext = ext = Path.extname("/home/user/file.txt")
if (ext.length > 0 && ext.charAt(0) == "."), do: ext.substr(1), else: ext
    combined = Path.join(["home", "user", "file.txt"])
  end
  defp testEnumExterns() do
    test_array = [1, 2, 3, 4, 5]
    count = Enum.count(test_array)
    is_empty = Enum.empty?(test_array)
    contains = Enum.member?(test_array, 3)
    first = Enum.at(test_array, 0)
    found = Enum.find(test_array, fn x -> x > 3 end)
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
  defp testStringExterns() do
    test_string = "  Hello, World!  "
    length = String.length(test_string)
    byte_size = String.byte_size(test_string)
    is_valid = String.valid?(test_string)
    lower = String.downcase(test_string)
    upper = String.upcase(test_string)
    capitalized = String.capitalize(test_string)
    trimmed = String.trim(test_string)
    left_trimmed = String.trim_leading(test_string)
    padded = String.pad_leading("hello", 10)
    slice = String.slice(test_string, 2, 5)
    char_at = String.at(test_string, 0)
    first = String.first(test_string)
    last = String.last(test_string)
    contains = String.contains?(test_string, "Hello")
    starts_with = String.starts_with?(test_string, "  Hello")
    ends_with = String.ends_with?(test_string, "!  ")
    replaced = String.replace(test_string, "World", "Elixir")
    prefix_replaced = String.replace_prefix(test_string, "  ", "")
    split = String.split("a,b,c")
    split_on = String.split("a,b,c", ",")
    split_at = String.split_at(test_string, 5)
    to_int_result = String.to_integer("123")
    to_float_result = String.to_float("123.45")
    is_empty = String.length("") == 0
    is_blank = string = String.trim("   ")
String.length(string) == 0
    left_padded = pad_with = "0"
if (pad_with == nil) do
  pad_with = " "
end
if (String.length("test") >= 10) do
  "test"
else
  String.pad_leading("test", 10, pad_with)
end
    repeated = String.duplicate("ha", 3)
  end
  defp testGenServerExterns() do
    start_result = GenServer.start_link("MyGenServer", "init_arg")
    call_result = GenServer.call(nil, "get_state")
    GenServer.cast(nil, "update_state")
    GenServer.stop(nil)
    reply_tuple___2 = nil
    reply_tuple___1 = nil
    reply_tuple___0 = nil
    reply_tuple___0 = :REPLY
    reply_tuple___1 = "response"
    reply_tuple___2 = "new_state"
    noreply_tuple___1 = nil
    noreply_tuple___0 = nil
    noreply_tuple___0 = :NOREPLY
    noreply_tuple___1 = "state"
    stop_tuple___2 = nil
    stop_tuple___1 = nil
    stop_tuple___0 = nil
    stop_tuple___0 = :STOP
    stop_tuple___1 = "normal"
    stop_tuple___2 = "final_state"
    pid = GenServer.whereis("MyGenServer")
  end
end