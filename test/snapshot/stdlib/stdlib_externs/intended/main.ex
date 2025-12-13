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
    pid = Process.process.self()
    _ = Process.process.send(pid, "hello")
    _ = Process.process.exit(pid, "normal")
    new_pid = Process.process.spawn(fn -> IO.io.puts("Hello from spawned process") end)
    _ = Process.process.monitor(new_pid)
    _ = Process.process.link(new_pid)
    alive = Process.process.alive?(pid)
    info = Process.process.info(pid)
  end
  defp test_registry_externs() do
    registry_spec = Registry.registry.start_link(%{:keys => {:unique}, :name => String.to_atom("MyRegistry")})
    register_result = Registry.registry.register("MyRegistry", "user:123", "user_data")
    lookup_result = Registry.registry.lookup("MyRegistry", "user:123")
    count = Registry.registry.count("MyRegistry")
    keys = Registry.registry.keys("MyRegistry", Process.process.self())
  end
  defp test_agent_externs() do
    agent_result = Agent.agent.start_link(fn ->  end)
    state = Agent.agent.get(nil, fn count -> count end)
    _ = Agent.agent.update(nil, fn count -> count + 1 end)
    _ = Agent.agent.cast(nil, fn count -> count + 1 end)
    counter_agent = Agent.agent.start_link(fn -> 10 end)
    agent = nil
    _ = Agent.agent.update(agent, fn count -> count + 5 end)
    current_count = agent = nil
    _ = Agent.agent.get(agent, fn count -> count end)
  end
  defp test_io_externs() do
    _ = IO.io.puts("Hello, World!")
    _ = IO.io.write("Hello ")
    _ = IO.io.inspect([1, 2, 3])
    input = IO.io.gets("Enter something: ")
    char = IO.io.read(1)
    _ = IO.io.puts("Using helper function")
    _ = IO.io.puts("stderr", "This is an error message")
    label = "label"
    if (Kernel.is_nil(label)) do
      label = ""
    end
    if (label != "") do
      IO.io.puts("#{(fn -> label end).()}: ")
    end
    _ = IO.io.inspect("Debug value")
    color = IO.IO.ANSI.red
    _ = IO.io.write("#{(fn -> color end).()}Error text#{(fn -> IO.IO.ANSI.reset end).()}")
    color = IO.IO.ANSI.green
    _ = IO.io.write("#{(fn -> color end).()}Success text#{(fn -> IO.IO.ANSI.reset end).()}")
    color = IO.IO.ANSI.blue
    _ = IO.io.write("#{(fn -> color end).()}Info text#{(fn -> IO.IO.ANSI.reset end).()}")
    formatted = label = "Array"
    if (Kernel.is_nil(label)) do
      label = ""
    end
    result = IO.io.iodata_to_binary(IO.io.inspect([1, 2, 3]))
    if (label != "") do
      "#{(fn -> label end).()}: #{(fn -> result end).()}"
    else
      result
    end
  end
  defp test_file_externs() do
    read_result = File.file.read("test.txt")
    content = File.file.read!("test.txt")
    write_result = File.file.write("output.txt", "Hello, File!")
    _ = File.file.write!("output2.txt", "Hello again!")
    stat_result = File.file.stat("test.txt")
    exists = File.file.exists?("test.txt")
    is_file = File.file.regular?("test.txt")
    is_dir = File.file.dir?("directory")
    mkdir_result = File.file.mkdir("new_directory")
    ls_result = File.file.ls(".")
    copy_result = File.file.copy("source.txt", "dest.txt")
    rename_result = File.file.rename("old.txt", "new.txt")
    text_content = result = File.file.read("text_file.txt")
    if (result._0 == "ok"), do: result._1, else: nil
    write_success = result = File.file.write("output.txt", "content")
    result._0 == "ok"
    lines = content = result = File.file.read("multi_line.txt")
    if (result._0 == "ok"), do: result._1, else: nil
    if (not Kernel.is_nil(content)) do
      String.split(content, "\n")
    else
      nil
    end
    dir_created = result = File.file.mkdir_p("new_dir")
    result._0 == "ok"
  end
  defp test_path_externs() do
    joined = Path.path.join(["home", "user", "documents"])
    joined_two = Path.path.join("/home", "user")
    basename = Path.path.basename("/home/user/file.txt")
    dirname = Path.path.dirname("/home/user/file.txt")
    extension = Path.path.extname("/home/user/file.txt")
    rootname = Path.path.rootname("/home/user/file.txt")
    is_absolute = Path.path.absname?("/home/user")
    path_type = Path.path.type("/home/user")
    expanded = Path.path.expand("~/documents")
    relative = Path.path.relative_to_cwd("/home/user/documents")
    matches = Path.path.wildcard("*.txt")
    filename = Path.path.basename("/home/user/file.txt")
    filename_no_ext = Path.path.rootname(Path.path.basename("/home/user/file.txt"))
    ext = Path.path.extname("/home/user/file.txt")
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
    combined = Path.path.join(["home", "user", "file.txt"])
  end
  defp test_enum_externs() do
    test_array = [1, 2, 3, 4, 5]
    count = Enum.enum.count(test_array)
    is_empty = Enum.enum.empty?(test_array)
    contains = Enum.enum.member?(test_array, 3)
    first = Enum.enum.at(test_array, 0)
    found = Enum.enum.find(test_array, fn x -> x > 3 end)
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
    collected = Enum.enum.map(test_array, fn x -> inspect(x) end)
  end
  defp test_string_externs() do
    test_string = "  Hello, World!  "
    length = String.string.length(test_string)
    byte_size = String.string.byte_size(test_string)
    is_valid = String.string.valid?(test_string)
    lower = String.string.downcase(test_string)
    upper = String.string.upcase(test_string)
    capitalized = String.string.capitalize(test_string)
    trimmed = String.trim(test_string)
    left_trimmed = String.trim_leading(test_string)
    padded = String.string.pad_leading("hello", 10)
    slice = String.string.slice(test_string, 2, 5)
    char_at = String.string.at(test_string, 0)
    first = String.string.first(test_string)
    last = String.string.last(test_string)
    contains = String.string.contains?(test_string, "Hello")
    starts_with = String.string.starts_with?(test_string, "  Hello")
    ends_with = String.string.ends_with?(test_string, "!  ")
    replaced = String.string.replace(test_string, "World", "Elixir")
    prefix_replaced = String.string.replace_prefix(test_string, "  ", "")
    split = String.split("a,b,c")
    split_on = String.split("a,b,c", ",")
    split_at = String.string.split_at(test_string, 5)
    to_int_result = String.string.to_integer("123")
    to_float_result = String.string.to_float("123.45")
    is_empty = String.string.length("") == 0
    is_blank = string = String.trim("   ")
    String.string.length(string) == 0
    left_padded = pad_with = "0"
    if (Kernel.is_nil(pad_with)) do
      pad_with = " "
    end
    if (String.string.length("test") >= 10) do
      "test"
    else
      String.string.pad_leading("test", 10, pad_with)
    end
    repeated = String.string.duplicate("ha", 3)
  end
  defp test_gen_server_externs() do
    start_result = GenServer.gen_server.start_link("MyGenServer", "init_arg")
    server_ref = nil
    call_result = GenServer.gen_server.call(server_ref, "get_state")
    _ = GenServer.gen_server.cast(server_ref, "update_state")
    _ = GenServer.gen_server.stop(server_ref)
    pid = GenServer.gen_server.whereis(server_ref)
    infinity = :infinity
    normal = :normal
    shutdown = :shutdown
  end
end
