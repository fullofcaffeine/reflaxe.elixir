defmodule Main do
  use Bitwise
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
alive = Process.alive?(pid)
info = Process.info(pid)
  end

  @doc "Function test_registry_externs"
  @spec test_registry_externs() :: nil
  def test_registry_externs() do
    registry_spec = Registry.start_link("unique", "MyRegistry")
register_result = Registry.register("MyRegistry", "user:123", "user_data")
lookup_result = Registry.lookup("MyRegistry", "user:123")
count = Registry.count("MyRegistry")
keys = Registry.keys("MyRegistry", Process.self())
temp_map = nil
_g = Haxe.Ds.StringMap.new()
_g.set("keys", "unique")
_g.set("name", "TestRegistry")
temp_map = _g
unique_options = temp_map
temp_maybe_var = nil
results = Registry.lookup("MyRegistry", "user:123")
if (length(results) > 0), do: temp_maybe_var = Enum.at(results, 0)._0, else: temp_maybe_var = nil
found_process = temp_maybe_var
  end

  @doc "Function test_agent_externs"
  @spec test_agent_externs() :: nil
  def test_agent_externs() do
    agent_result = Agent.start_link(fn  -> 0 end)
state = Agent.get(nil, fn count -> count end)
Agent.update(nil, fn count -> count + 1 end)
Agent.cast(nil, fn count -> count + 1 end)
counter_agent = Agent.start_link(fn  -> 10 end)
agent = nil
Agent.update(agent, fn count -> count + 5 end)
temp_number = nil
agent = nil
temp_number = Agent.get(agent, fn count -> count end)
current_count = temp_number
map_agent = Agent.start_link(fn  -> nil end)
agent = nil
Agent.update(agent, fn state -> state end)
temp_var = nil
agent = nil
temp_var = Agent.get(agent, fn state -> nil end)
value = temp_var
  end

  @doc "Function test_i_o_externs"
  @spec test_i_o_externs() :: nil
  def test_i_o_externs() do
    IO.puts("Hello, World!")
IO.write("Hello ")
IO.inspect([1, 2, 3])
input = IO.gets("Enter something: ")
char = IO.read(1)
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
formatted = temp_string
  end

  @doc "Function test_file_externs"
  @spec test_file_externs() :: nil
  def test_file_externs() do
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
temp_maybe_string = nil
result = File.read("text_file.txt")
if (result._0 == "ok"), do: temp_maybe_string = result._1, else: temp_maybe_string = nil
text_content = temp_maybe_string
temp_bool = nil
result = File.write("output.txt", "content")
temp_bool = result._0 == "ok"
write_success = temp_bool
temp_maybe_array = nil
temp_maybe_string1 = nil
result = File.read("multi_line.txt")
if (result._0 == "ok"), do: temp_maybe_string1 = result._1, else: temp_maybe_string1 = nil
content2 = temp_maybe_string1
if (content2 != nil), do: temp_maybe_array = content2.split("\n"), else: temp_maybe_array = nil
lines = temp_maybe_array
temp_bool1 = nil
result = File.mkdir_p("new_dir")
temp_bool1 = result._0 == "ok"
dir_created = temp_bool1
  end

  @doc "Function test_path_externs"
  @spec test_path_externs() :: nil
  def test_path_externs() do
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
temp_string = nil
ext = Path.extname("/home/user/file.txt")
if (String.length(ext) > 0 && String.at(ext, 0) == "."), do: temp_string = String.slice(ext, 1..-1), else: temp_string = ext
ext = temp_string
combined = Path.join(["home", "user", "file.txt"])
  end

  @doc "Function test_enum_externs"
  @spec test_enum_externs() :: nil
  def test_enum_externs() do
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

  @doc "Function test_string_externs"
  @spec test_string_externs() :: nil
  def test_string_externs() do
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
temp_bool = nil
string = String.trim("   ")
temp_bool = String.length(string) == 0
is_blank = temp_bool
temp_string = nil
pad_with = "0"
if (pad_with == nil), do: pad_with = " ", else: nil
if (String.length("test") >= 10), do: temp_string = "test", else: temp_string = String.pad_leading("test", 10, pad_with)
left_padded = temp_string
repeated = String.duplicate("ha", 3)
  end

  @doc "Function test_gen_server_externs"
  @spec test_gen_server_externs() :: nil
  def test_gen_server_externs() do
    start_result = GenServer.start_link("MyGenServer", "init_arg")
call_result = GenServer.call(nil, "get_state")
GenServer.cast(nil, "update_state")
GenServer.stop(nil)
reply_tuple__2 = nil
reply_tuple__1 = nil
reply_tuple__0 = nil
reply_tuple__0 = ElixirAtom.r_e_p_l_y()
reply_tuple__1 = "response"
reply_tuple__2 = "new_state"
noreply_tuple__1 = nil
noreply_tuple__0 = nil
noreply_tuple__0 = ElixirAtom.n_o_r_e_p_l_y()
noreply_tuple__1 = "state"
stop_tuple__2 = nil
stop_tuple__1 = nil
stop_tuple__0 = nil
stop_tuple__0 = ElixirAtom.s_t_o_p()
stop_tuple__1 = "normal"
stop_tuple__2 = "final_state"
pid = GenServer.whereis("MyGenServer")
  end

end
