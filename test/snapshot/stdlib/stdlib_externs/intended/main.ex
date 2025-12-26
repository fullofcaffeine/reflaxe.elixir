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
    alive = Process.alive?(pid)
    info = Process.info(pid)
  end
  defp test_registry_externs() do
    registry_spec = Registry.start_link(%{:keys => {:unique}, :name => String.to_atom("MyRegistry")})
    register_result = Registry.register("MyRegistry", "user:123", "user_data")
    lookup_result = Registry.lookup("MyRegistry", "user:123")
    count = Registry.count("MyRegistry")
    keys = Registry.keys("MyRegistry", Process.self())
  end
  defp test_agent_externs() do
    agent_result = agent.start_link(fn -> nil end)
    state = agent.get(nil, fn count -> count end)
    _ = agent.update(nil, fn count -> count + 1 end)
    _ = agent.cast(nil, fn count -> count + 1 end)
    counter_agent = agent.start_link(fn -> 10 end)
    agent = nil
    _ = agent.update(agent, fn count -> count + 5 end)
    agent = nil
    current_count = _ = agent.get(agent, fn count -> count end)
  end
  defp test_io_externs() do
    _ = IO.puts("Hello, World!")
    _ = IO.write("Hello ")
    _ = IO.inspect([1, 2, 3])
    input = IO.gets("Enter something: ")
    char = IO.read(1)
    _ = IO.puts("Using helper function")
    _ = IO.puts("stderr", "This is an error message")
    label = "label"
    if (Kernel.is_nil(label)) do
      label = ""
    end
    if (label != "") do
      IO.puts("#{(fn -> label end).()}: ")
    end
    _ = IO.inspect("Debug value")
    color = IO.IO.ANSI.red
    _ = IO.write("#{(fn -> color end).()}Error text#{(fn -> IO.IO.ANSI.reset end).()}")
    color = IO.IO.ANSI.green
    _ = IO.write("#{(fn -> color end).()}Success text#{(fn -> IO.IO.ANSI.reset end).()}")
    color = IO.IO.ANSI.blue
    _ = IO.write("#{(fn -> color end).()}Info text#{(fn -> IO.IO.ANSI.reset end).()}")
    label = "Array"
    if (Kernel.is_nil(label)) do
      label = ""
    end
    result = IO.iodata_to_binary(IO.inspect([1, 2, 3]))
    formatted = if (label != "") do
      "#{(fn -> label end).()}: #{(fn -> result end).()}"
    else
      result
    end
  end
  defp test_file_externs() do
    read_result = File.read("test.txt")
    content = File.read!("test.txt")
    write_result = File.write("output.txt", "Hello, File!")
    _ = File.write!("output2.txt", "Hello again!")
    stat_result = File.stat("test.txt")
    exists = File.exists?("test.txt")
    is_file = File.regular?("test.txt")
    is_dir = File.dir?("directory")
    mkdir_result = File.mkdir("new_directory")
    ls_result = File.ls(".")
    copy_result = File.copy("source.txt", "dest.txt")
    rename_result = File.rename("old.txt", "new.txt")
    result = File.read("text_file.txt")
    text_content = if (result._0 == "ok"), do: result._1, else: nil
    result = File.write("output.txt", "content")
    write_success = result._0 == "ok"
    result = File.read("multi_line.txt")
    content = if (result._0 == "ok"), do: result._1, else: nil
    lines = if (not Kernel.is_nil(content)) do
      String.split(content, "\n")
    else
      nil
    end
    result = File.mkdir_p("new_dir")
    dir_created = result._0 == "ok"
  end
  defp test_path_externs() do
    joined = Path.join((fn -> ["home", "user", "documents"] end).())
    joined_two = Path.join((fn -> "/home" end).(), "user")
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
    ext = Path.extname("/home/user/file.txt")
    ext = if (length(ext) > 0 and String.at(ext, 0) || "" == ".") do
      len = nil
      if (Kernel.is_nil(len)) do
        String.slice(ext, 1..-1)
      else
        String.slice(ext, 1, len)
      end
    else
      ext
    end
    combined = Path.join((fn -> ["home", "user", "file.txt"] end).())
  end
  defp test_enum_externs() do
    test_array = [1, 2, 3, 4, 5]
    count = Enum.count(test_array)
    is_empty = Enum.empty?(test_array)
    contains = Enum.member?(test_array, 3)
    first = Enum.at(test_array, 0)
    found = Enum.find(test_array, fn x -> x > 3 end)
    doubled = Enum.map(test_array, fn x -> x * 2 end)
    filtered = Enum.filter(test_array, fn x -> rem(x, 2) == 0 end)
    _reduced = Enum.reduce(test_array, 0, fn acc, x -> acc + x end)
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
    collected = Enum.map(test_array, fn x -> inspect(x) end)
  end
  defp test_string_externs() do
    test_string = "  Hello, World!  "
    length = string.length(test_string)
    byte_size = string.byte_size(test_string)
    is_valid = string.valid?(test_string)
    lower = string.downcase(test_string)
    upper = string.upcase(test_string)
    capitalized = string.capitalize(test_string)
    trimmed = string.trim(test_string)
    left_trimmed = string.trim_leading(test_string)
    padded = string.pad_leading("hello", 10)
    slice = string.slice(test_string, 2, 5)
    char_at = string.at(test_string, 0)
    first = string.first(test_string)
    last = string.last(test_string)
    contains = string.contains?(test_string, "Hello")
    starts_with = string.starts_with?(test_string, "  Hello")
    ends_with = string.ends_with?(test_string, "!  ")
    replaced = string.replace(test_string, "World", "Elixir")
    prefix_replaced = string.replace_prefix(test_string, "  ", "")
    split = string.split("a,b,c")
    split_on = string.split("a,b,c", ",")
    split_at = string.split_at(test_string, 5)
    to_int_result = string.to_integer("123")
    to_float_result = string.to_float("123.45")
    is_empty = string.length("") == 0
    string = string.trim("   ")
    is_blank = string.length(string) == 0
    pad_with = "0"
    if (Kernel.is_nil(pad_with)) do
      pad_with = " "
    end
    left_padded = if (string.length("test") >= 10) do
      "test"
    else
      string.pad_leading("test", 10, pad_with)
    end
    repeated = string.duplicate("ha", 3)
  end
  defp test_gen_server_externs() do
    start_result = GenServer.start_link("MyGenServer", "init_arg")
    server_ref = nil
    call_result = GenServer.call(server_ref, "get_state")
    _ = GenServer.cast(server_ref, "update_state")
    _ = GenServer.stop(server_ref)
    pid = GenServer.whereis(server_ref)
    infinity = :infinity
    normal = :normal
    shutdown = :shutdown
  end
end
