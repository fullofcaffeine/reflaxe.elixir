defmodule Main do
  def main() do
    _ = test_basic_operations()
    _ = test_add_char()
    _ = test_add_sub()
    _ = test_complex_building()
  end
  defp test_basic_operations() do
    buf = StringBuf.new()
    _ = StringBuf.add(buf, "Hello")
    _ = StringBuf.add(buf, " ")
    _ = StringBuf.add(buf, "World")
    _result = StringBuf.to_string(buf)
    _ = StringBuf.new()
    _ = StringBuf.add(buf_entry, nil)
    _ = StringBuf.add(buf_entry, " test")
    _ = StringBuf.new()
    _ = StringBuf.add(buf_value, 42)
    _ = StringBuf.add(buf_value, " is the answer")
    nil
  end
  defp test_add_char() do
    buf = StringBuf.new()
    _ = StringBuf.add_char(buf, 72)
    _ = StringBuf.add_char(buf, 105)
    _ = StringBuf.add_char(buf, 33)
    nil
  end
  defp test_add_sub() do
    buf = StringBuf.new()
    source = "Hello World"
    _ = StringBuf.add_sub(buf, source, 0, 5)
    _ = StringBuf.add(buf, "-")
    _ = StringBuf.add_sub(buf, source, 6, nil)
    nil
  end
  defp test_complex_building() do
    buf = StringBuf.new()
    _ = StringBuf.add(buf, "List: [")
    _ = StringBuf.add(buf, 0)
    _ = StringBuf.add(buf, ", ")
    _ = StringBuf.add(buf, 1)
    _ = StringBuf.add(buf, ", ")
    _ = StringBuf.add(buf, 2)
    _ = StringBuf.add(buf, ", ")
    _ = StringBuf.add(buf, 3)
    _ = StringBuf.add(buf, ", ")
    _ = StringBuf.add(buf, 4)
    _ = StringBuf.add(buf, "]")
    nil
  end
end
