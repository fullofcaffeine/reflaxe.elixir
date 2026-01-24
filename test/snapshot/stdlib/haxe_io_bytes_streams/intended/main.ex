defmodule Main do
  def main() do
    _ = bytes_buffer()
    _ = bytes_input_output()
    _ = buffer_input()
    _ = fp_helper()
  end
  defp bytes_buffer() do
    buffer = BytesBuffer.new()
    buffer = %{buffer | parts_reversed: [65 | buffer.parts_reversed]}
    buffer = %{buffer | byte_length: buffer.byte_length + 1}
    encoding = nil
    src = Bytes.of_string("BC", encoding)
    buffer = if (src.length == 0) do
      nil
      buffer
    else
      buffer = %{buffer | parts_reversed: [apply(Map.get(src, :__reflaxe_class__) || Map.get(src, :__struct__), :get_data, [src]) | buffer.parts_reversed]}
      %{buffer | byte_length: buffer.byte_length + src.length}
    end
    buffer = %{buffer | parts_reversed: [<<16909060::little-signed-size(32)>> | buffer.parts_reversed]}
    buffer = %{buffer | byte_length: buffer.byte_length + 4}
    buffer = %{buffer | parts_reversed: [<<1.5::float-little-size(32)>> | buffer.parts_reversed]}
    buffer = %{buffer | byte_length: buffer.byte_length + 4}
    buffer = %{buffer | parts_reversed: [<<3.25::float-little-size(64)>> | buffer.parts_reversed]}
    buffer = %{buffer | byte_length: buffer.byte_length + 8}
    _bytes = apply(Map.get(buffer, :__reflaxe_class__) || Map.get(buffer, :__struct__), :get_bytes, [buffer])
    nil
  end
  defp bytes_input_output() do
    out = BytesOutput.new()
    _ = apply(Map.get(out, :__reflaxe_class__) || Map.get(out, :__struct__), :write_byte, [out, 0])
    _ = apply(Map.get(out, :__reflaxe_class__) || Map.get(out, :__struct__), :write_string, [out, "hi", nil])
    bytes = apply(Map.get(out, :__reflaxe_class__) || Map.get(out, :__struct__), :get_bytes, [out])
    input = BytesInput.new(bytes, nil, nil)
    _first = apply(Map.get(input, :__reflaxe_class__) || Map.get(input, :__struct__), :read_byte, [input])
    tmp = Bytes.alloc(2)
    _ = apply(Map.get(input, :__reflaxe_class__) || Map.get(input, :__struct__), :read_bytes, [input, tmp, 0, 2])
    nil
  end
  defp buffer_input() do
    bytes = Bytes.of_string("hello", nil)
    base = BytesInput.new(bytes, nil, nil)
    buf = Bytes.alloc(2)
    _buffered = BufferInput.new(base, buf, nil, nil)
    nil
  end
  defp fp_helper() do
    bits = FPHelper.float_to_i32(1)
    _value = FPHelper.i32_to_float(bits)
    _bits_value = FPHelper.double_to_i64(1)
    nil
  end
end
