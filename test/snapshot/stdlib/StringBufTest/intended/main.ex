defmodule Main do
  def main() do
    _ = test_basic_operations()
    _ = test_add_char()
    _ = test_add_sub()
    _ = test_complex_building()
  end
  defp test_basic_operations() do
    buf = StringBuf.new()
    _ = apply(Map.get(buf, :__reflaxe_class__) || Map.get(buf, :__struct__), :add, [buf, "Hello"])
    _ = apply(Map.get(buf, :__reflaxe_class__) || Map.get(buf, :__struct__), :add, [buf, " "])
    _ = apply(Map.get(buf, :__reflaxe_class__) || Map.get(buf, :__struct__), :add, [buf, "World"])
    _result = apply(Map.get(buf, :__reflaxe_class__) || Map.get(buf, :__struct__), :to_string, [buf])
    buf_entry = StringBuf.new()
    _ = apply(Map.get(buf_entry, :__reflaxe_class__) || Map.get(buf_entry, :__struct__), :add, [buf_entry, nil])
    _ = apply(Map.get(buf_entry, :__reflaxe_class__) || Map.get(buf_entry, :__struct__), :add, [buf_entry, " test"])
    buf_value = StringBuf.new()
    _ = apply(Map.get(buf_value, :__reflaxe_class__) || Map.get(buf_value, :__struct__), :add, [buf_value, 42])
    _ = apply(Map.get(buf_value, :__reflaxe_class__) || Map.get(buf_value, :__struct__), :add, [buf_value, " is the answer"])
    nil
  end
  defp test_add_char() do
    buf = StringBuf.new()
    _ = apply(Map.get(buf, :__reflaxe_class__) || Map.get(buf, :__struct__), :add_char, [buf, 72])
    _ = apply(Map.get(buf, :__reflaxe_class__) || Map.get(buf, :__struct__), :add_char, [buf, 105])
    _ = apply(Map.get(buf, :__reflaxe_class__) || Map.get(buf, :__struct__), :add_char, [buf, 33])
    nil
  end
  defp test_add_sub() do
    buf = StringBuf.new()
    source = "Hello World"
    _ = apply(Map.get(buf, :__reflaxe_class__) || Map.get(buf, :__struct__), :add_sub, [buf, source, 0, 5])
    _ = apply(Map.get(buf, :__reflaxe_class__) || Map.get(buf, :__struct__), :add, [buf, "-"])
    _ = apply(Map.get(buf, :__reflaxe_class__) || Map.get(buf, :__struct__), :add_sub, [buf, source, 6, nil])
    nil
  end
  defp test_complex_building() do
    buf = StringBuf.new()
    _ = apply(Map.get(buf, :__reflaxe_class__) || Map.get(buf, :__struct__), :add, [buf, "List: ["])
    _ = apply(Map.get(buf, :__reflaxe_class__) || Map.get(buf, :__struct__), :add, [buf, 0])
    _ = apply(Map.get(buf, :__reflaxe_class__) || Map.get(buf, :__struct__), :add, [buf, ", "])
    _ = apply(Map.get(buf, :__reflaxe_class__) || Map.get(buf, :__struct__), :add, [buf, 1])
    _ = apply(Map.get(buf, :__reflaxe_class__) || Map.get(buf, :__struct__), :add, [buf, ", "])
    _ = apply(Map.get(buf, :__reflaxe_class__) || Map.get(buf, :__struct__), :add, [buf, 2])
    _ = apply(Map.get(buf, :__reflaxe_class__) || Map.get(buf, :__struct__), :add, [buf, ", "])
    _ = apply(Map.get(buf, :__reflaxe_class__) || Map.get(buf, :__struct__), :add, [buf, 3])
    _ = apply(Map.get(buf, :__reflaxe_class__) || Map.get(buf, :__struct__), :add, [buf, ", "])
    _ = apply(Map.get(buf, :__reflaxe_class__) || Map.get(buf, :__struct__), :add, [buf, 4])
    _ = apply(Map.get(buf, :__reflaxe_class__) || Map.get(buf, :__struct__), :add, [buf, "]"])
    nil
  end
end
