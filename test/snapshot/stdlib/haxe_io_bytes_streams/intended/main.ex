defmodule Main do
  defp assert_that(condition, message) do
    if (not condition) do
      raise Reflaxe.Elixir.HaxeThrow, [value: message]
    end
  end
  def main() do
    bytes_buffer()
    bytes_input_output()
    buffer_input()
    string_input()
    fp_helper()
    io_semantics()
  end
  defp bytes_buffer() do
    buffer = BytesBuffer.new()
    buffer = apply(Map.get(buffer, :__reflaxe_class__) || Map.get(buffer, :__struct__), :add_byte, [buffer, 65])
    buffer = apply(Map.get(buffer, :__reflaxe_class__) || Map.get(buffer, :__struct__), :add_string, [buffer, "BC", nil])
    buffer = apply(Map.get(buffer, :__reflaxe_class__) || Map.get(buffer, :__struct__), :add_int32, [buffer, 16909060])
    buffer = apply(Map.get(buffer, :__reflaxe_class__) || Map.get(buffer, :__struct__), :add_float, [buffer, 1.5])
    buffer = apply(Map.get(buffer, :__reflaxe_class__) || Map.get(buffer, :__struct__), :add_double, [buffer, 3.25])
    _bytes = apply(Map.get(buffer, :__reflaxe_class__) || Map.get(buffer, :__struct__), :get_bytes, [buffer])
    nil
  end
  defp bytes_input_output() do
    out = BytesOutput.new()
    apply(Map.get(out, :__reflaxe_class__) || Map.get(out, :__struct__), :write_byte, [out, 0])
    apply(Map.get(out, :__reflaxe_class__) || Map.get(out, :__struct__), :write_string, [out, "hi", nil])
    bytes = apply(Map.get(out, :__reflaxe_class__) || Map.get(out, :__struct__), :get_bytes, [out])
    input = BytesInput.new(bytes, nil, nil)
    _first = apply(Map.get(input, :__reflaxe_class__) || Map.get(input, :__struct__), :read_byte, [input])
    tmp = Bytes.alloc(2)
    apply(Map.get(input, :__reflaxe_class__) || Map.get(input, :__struct__), :read_bytes, [input, tmp, 0, 2])
    nil
  end
  defp buffer_input() do
    bytes = Bytes.of_string("hello", {:utf8})
    base = BytesInput.new(bytes, nil, nil)
    buf = Bytes.alloc(2)
    _buffered = BufferInput.new(base, buf, nil, nil)
    nil
  end
  defp string_input() do
    _input = StringInput.new("alpha\nbeta")
    nil
  end
  defp fp_helper() do
    bits = FPHelper.float_to_i32(1)
    _value = FPHelper.i32_to_float(bits)
    _bits_value = FPHelper.double_to_i64(1)
    nil
  end
  defp io_semantics() do
    all_input = BytesInput.new(Bytes.of_string("hello", {:utf8}), nil, nil)
    reflaxe_dispatch_receiver = apply(Map.get(all_input, :__reflaxe_class__) || Map.get(all_input, :__struct__), :read_all, [all_input, 2])
    all = apply(Map.get(reflaxe_dispatch_receiver, :__reflaxe_class__) || Map.get(reflaxe_dispatch_receiver, :__struct__), :to_string, [reflaxe_dispatch_receiver])
    assert_that(all == "hello", "readAll chunked failed")
    line_input = BytesInput.new(Bytes.of_string("a\r\nb\n", {:utf8}), nil, nil)
    assert_that(apply(Map.get(line_input, :__reflaxe_class__) || Map.get(line_input, :__struct__), :read_line, [line_input]) == "a", "readLine CRLF failed")
    assert_that(apply(Map.get(line_input, :__reflaxe_class__) || Map.get(line_input, :__struct__), :read_line, [line_input]) == "b", "readLine LF failed")
    try do
      apply(Map.get(line_input, :__reflaxe_class__) || Map.get(line_input, :__struct__), :read_line, [line_input])
      assert_that(false, "readLine should throw Eof on empty input")
    rescue
      haxe_exception ->
        Process.put(:__reflaxe_last_stacktrace__, __STACKTRACE__)
        (case {(case haxe_exception do
          %Reflaxe.Elixir.HaxeThrow{value: haxe_unwrapped_value} -> haxe_unwrapped_value
          _ -> haxe_exception
        end), haxe_exception} do
          {haxe_catch_value, _} when is_struct(haxe_catch_value, Eof) or is_map(haxe_catch_value) and is_map_key(haxe_catch_value, :__reflaxe_class__) and :erlang.map_get(:__reflaxe_class__, haxe_catch_value) == Eof -> nil
          _ ->
            reraise(haxe_exception, __STACKTRACE__)
        end)
    end
    src = BytesInput.new(Bytes.of_string("xyz", {:utf8}), nil, nil)
    sink = BytesOutput.new()
    apply(Map.get(sink, :__reflaxe_class__) || Map.get(sink, :__struct__), :write_input, [sink, src, 2])
    assert_that((fn ->
      reflaxe_dispatch_receiver = apply(Map.get(sink, :__reflaxe_class__) || Map.get(sink, :__struct__), :get_bytes, [sink])
      apply(Map.get(reflaxe_dispatch_receiver, :__reflaxe_class__) || Map.get(reflaxe_dispatch_receiver, :__struct__), :to_string, [reflaxe_dispatch_receiver])
    end).() == "xyz", "writeInput failed")
    out = BytesOutput.new()
    Output.set_big_endian(out, false)
    apply(Map.get(out, :__reflaxe_class__) || Map.get(out, :__struct__), :write_double, [out, 3.25])
    bytes = apply(Map.get(out, :__reflaxe_class__) || Map.get(out, :__struct__), :get_bytes, [out])
    assert_that(bytes.length == 8, "writeDouble length should be 8")
    inp = BytesInput.new(bytes, nil, nil)
    Input.set_big_endian(inp, false)
    got = apply(Map.get(inp, :__reflaxe_class__) || Map.get(inp, :__struct__), :read_double, [inp])
    assert_that(Reflaxe.Elixir.HaxeFloat.lt(Reflaxe.Elixir.HaxeFloat.abs(Reflaxe.Elixir.HaxeFloat.sub(got, 3.25)), 1.0e-12), "double roundtrip failed")
    string_input = StringInput.new("red\r\nblue\n")
    assert_that(apply(Map.get(string_input, :__reflaxe_class__) || Map.get(string_input, :__struct__), :read_line, [string_input]) == "red", "StringInput readLine CRLF failed")
    assert_that(apply(Map.get(string_input, :__reflaxe_class__) || Map.get(string_input, :__struct__), :read_line, [string_input]) == "blue", "StringInput readLine LF failed")
    try do
      apply(Map.get(string_input, :__reflaxe_class__) || Map.get(string_input, :__struct__), :read_byte, [string_input])
      assert_that(false, "StringInput should throw Eof after readLine consumes content")
    rescue
      haxe_exception ->
        Process.put(:__reflaxe_last_stacktrace__, __STACKTRACE__)
        (case {(case haxe_exception do
          %Reflaxe.Elixir.HaxeThrow{value: haxe_unwrapped_value} -> haxe_unwrapped_value
          _ -> haxe_exception
        end), haxe_exception} do
          {haxe_catch_value, _} when is_struct(haxe_catch_value, Eof) or is_map(haxe_catch_value) and is_map_key(haxe_catch_value, :__reflaxe_class__) and :erlang.map_get(:__reflaxe_class__, haxe_catch_value) == Eof -> nil
          _ ->
            reraise(haxe_exception, __STACKTRACE__)
        end)
    end
  end
end
