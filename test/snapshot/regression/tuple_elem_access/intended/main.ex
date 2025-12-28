defmodule Main do
  def main() do
    tuple2__1 = "first"
    tuple2__2 = 42
    t__1 = true
    t__2 = 3.14
    t__3 = "third"
    _first = tuple2__1
    _second = tuple2__2
    _ = t__1
    _ = t__2
    _ = t__3
    nested__1__1 = "nested"
    nested__1__2 = 99
    _ = "outer"
    _inner_first = nested__1__1
    _inner_second = nested__1__2
    _result = get_tuple()
    nil
  end
  defp get_tuple() do
    {"hello", 123}
  end
end
