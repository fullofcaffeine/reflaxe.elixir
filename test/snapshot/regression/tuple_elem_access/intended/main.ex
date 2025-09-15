defmodule Main do
  def main() do
    tuple2__1 = "first"
    tuple2__2 = 42
    t__1 = true
    t__2 = 3.14
    t__3 = "third"
    first = tuple2__1
    second = tuple2__2
    Log.trace("Tuple2: first=#{first}, second=#{second}", %{:file_name => "Main.hx", :line_number => 10, :class_name => "Main", :method_name => "main"})
    elem1 = t__1
    elem2 = t__2
    elem3 = t__3
    Log.trace("Tuple3: #{elem1}, #{elem2}, #{elem3}", %{:file_name => "Main.hx", :line_number => 17, :class_name => "Main", :method_name => "main"})
    nested__1__1 = "nested"
    nested__1__2 = 99
    nested__2 = "outer"
    inner_first = nested__1__1
    inner_second = nested__1__2
    Log.trace("Nested: inner=(#{inner_first}, #{inner_second})", %{:file_name => "Main.hx", :line_number => 23, :class_name => "Main", :method_name => "main"})
    result = get_tuple()
    {res1, res2} = result
    Log.trace("Result: #{res1}, #{res2}", %{:file_name => "Main.hx", :line_number => 27, :class_name => "Main", :method_name => "main"})
  end
  defp get_tuple() do
    {"hello", 123}
  end
end