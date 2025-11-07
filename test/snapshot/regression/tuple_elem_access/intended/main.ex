defmodule Main do
  def main() do
    tuple2__1 = "first"
    tuple2__2 = 42
    t__1 = true
    t__2 = 3.14
    t__3 = "third"
    second = tuple2__2
    nested__1__2 = Log.trace("Tuple2: first=#{(fn -> tuple2__1 end).()}, second=#{(fn -> second end).()}", %{:file_name => "Main.hx", :line_number => 10, :class_name => "Main", :method_name => "main"})
    elem1 = t__1
    elem2 = t__2
    nested__1__2 = Log.trace("Tuple3: #{(fn -> inspect(elem1) end).()}, #{(fn -> elem2 end).()}, #{(fn -> t__3 end).()}", %{:file_name => "Main.hx", :line_number => 17, :class_name => "Main", :method_name => "main"})
    nested__1__1 = "nested"
    nested__1__2 = 99
    _ = "outer"
    inner_second = nested__1__2
    nested__1__2 = Log.trace("Nested: inner=(#{(fn -> nested__1__1 end).()}, #{(fn -> inner_second end).()})", %{:file_name => "Main.hx", :line_number => 23, :class_name => "Main", :method_name => "main"})
    result = get_tuple()
    nested__1__2 = Log.trace("Result: #{(fn -> result._1 end).()}, #{(fn -> result._2 end).()}", %{:file_name => "Main.hx", :line_number => 27, :class_name => "Main", :method_name => "main"})
    nested__1__2
  end
  defp get_tuple() do
    {"hello", 123}
  end
end
