defmodule Main do
  def main() do
    _ = bytes_buffer()
    _ = bytes_input_output()
    _ = buffer_input()
    _ = fp_helper()
  end
  defp bytes_buffer() do
    buffer = %BytesBuffer{}
    buffer = %{buffer | parts_reversed: [65 | buffer.parts_reversed]}
    buffer = %{buffer | byte_length: buffer.byte_length + 1}
    encoding = nil
    src = Bytes.of_string("BC", encoding)
    buffer = if (length(src) == 0) do
      nil
      buffer
    else
      buffer = %{buffer | parts_reversed: [Bytes.get_data(src) | buffer.parts_reversed]}
      %{buffer | byte_length: buffer.byte_length + length(src)}
    end
    buffer = %{buffer | parts_reversed: [<<16909060::little-signed-size(32)>> | buffer.parts_reversed]}
    buffer = %{buffer | byte_length: buffer.byte_length + 4}
    buffer = %{buffer | parts_reversed: [<<1.5::float-little-size(32)>> | buffer.parts_reversed]}
    buffer = %{buffer | byte_length: buffer.byte_length + 4}
    buffer = %{buffer | parts_reversed: [<<3.25::float-little-size(64)>> | buffer.parts_reversed]}
    buffer = %{buffer | byte_length: buffer.byte_length + 8}
    _bytes = BytesBuffer.get_bytes(buffer)
    nil
  end
  defp bytes_input_output() do
    out = %BytesOutput{}
    _ = BytesOutput.write_byte(out, 0)
    _ = Output.write_string(out, "hi")
    bytes = BytesOutput.get_bytes(out)
    input = BytesInput.new(bytes)
    _first = BytesInput.read_byte(input)
    tmp = Bytes.alloc(2)
    _ = BytesInput.read_bytes(input, tmp, 0, 2)
    nil
  end
  defp buffer_input() do
    bytes = Bytes.of_string("hello", nil)
    base = BytesInput.new(bytes)
    buf = Bytes.alloc(2)
    _buffered = BufferInput.new(base, buf)
    nil
  end
  defp fp_helper() do
    bits = FPHelper.float_to_i32(1)
    _value = FPHelper.i32_to_float(bits)
    _ = FPHelper.double_to_i64(1)
    nil
  end
end
