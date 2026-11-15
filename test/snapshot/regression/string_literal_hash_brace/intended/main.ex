defmodule Main do
  defp __haxe_static_get__(key, init) do
    static_key = {:__haxe_static__, Main, key}
    (case Process.get(static_key) do
      {:set, value} -> value
      nil ->
        value = init
        Process.put(static_key, {:set, value})
        value
    end)
  end
  defp __haxe_static_put__(key, value) do
    static_key = {:__haxe_static__, Main, key}
    Process.put(static_key, {:set, value})
    value
  end
  def static_text() do
    __haxe_static_get__(:static_text, "static \#{f} text")
  end
  def static_text(value) do
    __haxe_static_put__(:static_text, value)
  end
  def main() do
    x = 5
    name = "n"
    v = show("\#{x}")
    IO.puts(v)
    IO.puts("lit \#{1 + 1} end")
    IO.puts("\#{x}")
    IO.puts("\#{name} and \#{unknown} twice")
    IO.puts("\#{")
    IO.puts("\#{}")
    IO.puts("#\#{x}")
    IO.puts("nested \#{ %{a: 1} } braces")
    IO.puts("quote \" then \#{x}")
    IO.puts("call \#{raise \"boom\"}")
    IO.puts("a # b { c } # {#}")
    IO.puts("\\\#{x}")
    IO.puts("\\\\\#{x}")
    IO.puts("#\\{x}")
    IO.puts("tab\t\#{x}\tnl\\n")
    IO.puts("line1\n\#{x}\nline3")
    v = merged(name, x)
    IO.puts(v)
    v = open_brace(name)
    IO.puts(v)
    v = close_brace(name)
    IO.puts(v)
    v = interpolated(name, x)
    IO.puts(v)
    v = multi_line(name)
    IO.puts(v)
    IO.puts("lit \#{1 + 1} " <> name <> " end")
    IO.puts("\\\#{x} " <> name)
    v = split_marker()
    IO.puts(v)
    v = split_marker_around_value(name)
    IO.puts(v)
    IO.puts("#" <> "{x}")
    s = "\#{x}"
    IO.puts(s)
    v = StringTools.haxe_length(s)
    IO.puts(v)
    IO.puts(s == "\#{x}")
    IO.puts(s == "5")
    parts = ["\#{x}", "b\#{name}"]
    v = Enum.join(parts, "|")
    IO.puts(v)
    by_key = %{"\#{k}" => "\#{v}"}
    v = Map.get(by_key, "\#{k}")
    IO.puts(v)
    record_label = "\#{o}"
    v = record_label
    IO.puts(v)
    IO.puts("inline \#{c} text")
    v = Main.static_text()
    IO.puts(v)
    v = with_default("\#{d}")
    IO.puts(v)
    v = choose(true)
    IO.puts(v)
    v = choose(false)
    IO.puts(v)
    v = classify("\#{x}")
    IO.puts(v)
    v = classify("5")
    IO.puts(v)
    v = classify("other")
    IO.puts(v)
    g = {:named, "\#{e}"}
    g = elem(g, 1)
    label = g
    IO.puts(label)
    v = Enum.join(StringTools.haxe_split("a\#{x}b", "\#{x}"), "-")
    IO.puts(v)
    v = StringTools.replace("p \#{q} r", "\#{q}", "Q")
    IO.puts(v)
    v = StringTools.haxe_index_of("x\#{y}", "\#{", 0)
    IO.puts(v)
    v = String.upcase("\#{x}")
    IO.puts(v)
    heading = EReg.new("^\#{1,3} ", "")
    v = apply(Map.get(heading, :__reflaxe_class__) || Map.get(heading, :__struct__), :match, [heading, "## title"])
    IO.puts(v)
    v = apply(Map.get(heading, :__reflaxe_class__) || Map.get(heading, :__struct__), :match, [heading, "title"])
    IO.puts(v)
    buffer = StringBuf.new()
    buffer = apply(Map.get(buffer, :__reflaxe_class__) || Map.get(buffer, :__struct__), :add, [buffer, "\#{b}"])
    buffer = apply(Map.get(buffer, :__reflaxe_class__) || Map.get(buffer, :__struct__), :add, [buffer, x])
    v = apply(Map.get(buffer, :__reflaxe_class__) || Map.get(buffer, :__struct__), :to_string, [buffer])
    IO.puts(v)
    total = ""
    total = "#{total}\#{i}#{Reflaxe.Elixir.HaxeFloat.to_string(0)}"
    total = "#{total}\#{i}#{Reflaxe.Elixir.HaxeFloat.to_string(1)}"
    IO.puts(total)
    try do
      raise Reflaxe.Elixir.HaxeThrow, [value: "\#{thrown}"]
    rescue
      haxe_exception ->
        Process.put(:__reflaxe_last_stacktrace__, __STACKTRACE__)
        (case {(case haxe_exception do
          %Reflaxe.Elixir.HaxeThrow{value: haxe_unwrapped_value} -> haxe_unwrapped_value
          _ -> haxe_exception
        end), haxe_exception} do
          {e, _} when is_binary(e) -> IO.puts(e)
          _ ->
            reraise(haxe_exception, __STACKTRACE__)
        end)
    end
    v = Mix.Tasks.Markers.Count.run(["a", "b"])
    IO.puts(v)
    IO.puts("injected #{1 + 1}")
    IO.puts("argument \#{1 + 1}")
    IO.puts("in string: #{"\#{x}"} #{name}")
    v = atom_text(:"c\#{d}")
    IO.puts(v)
  end
  defp atom_text(a) do
    inspect(a)
  end
  def show(s) do
    "[#{s}]"
  end
  defp merged(name, x) do
    "lit \#{1 + 1} #{name} \#{x} and \#{name} v=#{Reflaxe.Elixir.HaxeFloat.to_string(x)}"
  end
  defp open_brace(name) do
    "\#{#{name}}"
  end
  defp close_brace(name) do
    "#{name} } \#{"
  end
  defp interpolated(name, x) do
    "single #{name} \#{name} #{Reflaxe.Elixir.HaxeFloat.to_string(x)} \#{#{Reflaxe.Elixir.HaxeFloat.to_string(x + 1)}}"
  end
  defp multi_line(name) do
    "ml #{name}\n\#{x}"
  end
  defp split_marker() do
    hash = "#"
    "#{hash}{x}"
  end
  defp split_marker_around_value(name) do
    "a\#{#{name}}\#{b}"
  end
  defp with_default(s) do
    s
  end
  defp choose(b) do
    if (b), do: "\#{t}", else: "f\#{f}"
  end
  defp classify(s) do
    (case s do
      "\#{x}" -> "marker"
      "5" -> "five"
      _ -> "other \#{s}"
    end)
  end
end
