defmodule Main do
  defp assert_that(condition, message) do
    if (not condition) do
      raise Reflaxe.Elixir.HaxeThrow, [value: message]
    end
  end
  def main() do
    _ = bytes_buffer()
    _ = bytes_input_output()
    _ = buffer_input()
    _ = fp_helper()
    _ = io_semantics()
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
  defp io_semantics() do
    all_input = BytesInput.new(Bytes.of_string("hello", nil), nil, nil)
    reflaxe_dispatch_receiver = apply(Map.get(all_input, :__reflaxe_class__) || Map.get(all_input, :__struct__), :read_all, [all_input, 2])
    all = _ = apply(Map.get(reflaxe_dispatch_receiver, :__reflaxe_class__) || Map.get(reflaxe_dispatch_receiver, :__struct__), :to_string, [reflaxe_dispatch_receiver])
    _ = assert_that(all == "hello", "readAll chunked failed")
    line_input = BytesInput.new(Bytes.of_string("a\r\nb\n", nil), nil, nil)
    _ = assert_that(apply(Map.get(line_input, :__reflaxe_class__) || Map.get(line_input, :__struct__), :read_line, [line_input]) == "a", "readLine CRLF failed")
    _ = assert_that(apply(Map.get(line_input, :__reflaxe_class__) || Map.get(line_input, :__struct__), :read_line, [line_input]) == "b", "readLine LF failed")
    try do
      _ = apply(Map.get(line_input, :__reflaxe_class__) || Map.get(line_input, :__struct__), :read_line, [line_input])
      _ = assert_that(false, "readLine should throw Eof on empty input")
    rescue
      haxe_exception ->
        (case {(case haxe_exception do
  %Reflaxe.Elixir.HaxeThrow{value: haxe_unwrapped_value} -> haxe_unwrapped_value
  _ -> haxe_exception
end), haxe_exception} do
          {haxe_catch_value, _} when is_struct(haxe_catch_value, Eof) or is_map(haxe_catch_value) and is_map_key(haxe_catch_value, :__reflaxe_class__) and :erlang.map_get(:__reflaxe_class__, haxe_catch_value) == Eof -> nil
          _ ->
            reraise(haxe_exception, __STACKTRACE__)
        end)
    end
    src = BytesInput.new(Bytes.of_string("xyz", nil), nil, nil)
    sink = BytesOutput.new()
    _ = apply(Map.get(sink, :__reflaxe_class__) || Map.get(sink, :__struct__), :write_input, [sink, src, 2])
    _ = assert_that((fn ->
  reflaxe_dispatch_receiver = apply(Map.get(sink, :__reflaxe_class__) || Map.get(sink, :__struct__), :get_bytes, [sink])
  _ = apply(Map.get(reflaxe_dispatch_receiver, :__reflaxe_class__) || Map.get(reflaxe_dispatch_receiver, :__struct__), :to_string, [reflaxe_dispatch_receiver])
end).() == "xyz", "writeInput failed")
    out = BytesOutput.new()
    _ = Output.set_big_endian(out, false)
    _ = apply(Map.get(out, :__reflaxe_class__) || Map.get(out, :__struct__), :write_double, [out, 3.25])
    bytes = apply(Map.get(out, :__reflaxe_class__) || Map.get(out, :__struct__), :get_bytes, [out])
    _ = assert_that(bytes.length == 8, "writeDouble length should be 8")
    inp = BytesInput.new(bytes, nil, nil)
    _ = Input.set_big_endian(inp, false)
    got = apply(Map.get(inp, :__reflaxe_class__) || Map.get(inp, :__struct__), :read_double, [inp])
    _ = assert_that((fn ->
  v = (got - 3.25)
  if (v < 0) do
    -v
  else
    v
  end
end).() < 1.0e-12, "double roundtrip failed")
  end
end
