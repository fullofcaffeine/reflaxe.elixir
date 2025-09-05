defmodule Main do
  def main() do
    tuple2__2 = nil
    tuple2__1 = "first"
    tuple2__2 = 42
    t__3 = nil
    t__2 = nil
    t__1 = true
    t__2 = 3.14
    t__3 = "third"
    first = tuple2__1
    second = tuple2__2
    Log.trace("Tuple2: first=" <> first <> ", second=" <> second, %{:fileName => "Main.hx", :lineNumber => 10, :className => "Main", :methodName => "main"})
    elem1 = t__1
    elem2 = t__2
    elem3 = t__3
    Log.trace("Tuple3: " <> Std.string(elem1) <> ", " <> elem2 <> ", " <> elem3, %{:fileName => "Main.hx", :lineNumber => 17, :className => "Main", :methodName => "main"})
    nested__2 = nil
    nested__1__2 = nil
    nested__1__1 = "nested"
    nested__1__2 = 99
    nested__2 = "outer"
    inner_first = nested__1__1
    inner_second = nested__1__2
    Log.trace("Nested: inner=(" <> inner_first <> ", " <> inner_second <> ")", %{:fileName => "Main.hx", :lineNumber => 23, :className => "Main", :methodName => "main"})
    result = get_tuple()
    Log.trace("Result: " <> elem(result, 0) <> ", " <> elem(result, 1), %{:fileName => "Main.hx", :lineNumber => 27, :className => "Main", :methodName => "main"})
  end
  defp get_tuple() do
    {"hello", 123}
  end
end