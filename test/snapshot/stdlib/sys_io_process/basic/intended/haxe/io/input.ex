defmodule Input do
  def read_byte(_) do
    raise Reflaxe.Elixir.HaxeThrow, [value: NotImplementedException.new(nil, nil, %{:file_name => "../../../../../std/haxe/io/Input.hx", :line_number => 38, :class_name => "haxe.io.Input", :method_name => "readByte"})]
  end
  def read_bytes(struct, s, pos, len) do
    if (pos < 0 or len < 0 or pos + len > length(s)) do
      raise Reflaxe.Elixir.HaxeThrow, [value: {:outside_bounds}]
    end
    k = len
    try do
      {s, pos, k} = Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {s, pos, k}, fn _, {acc_s, acc_pos, acc_k} ->
        try do
          if (acc_k > 0) do
            acc_s = Bytes.set(acc_s, acc_pos, read_byte(struct))
            acc_pos = acc_pos + 1
            acc_k = (acc_k - 1)
            {:cont, {acc_s, acc_pos, acc_k}}
          else
            {:halt, {acc_s, acc_pos, acc_k}}
          end
        catch
          :throw, {:break, break_state} ->
            {:halt, break_state}
          :throw, {:continue, continue_state} ->
            {:cont, continue_state}
          :throw, :break ->
            {:halt, {acc_s, acc_pos, acc_k}}
          :throw, :continue ->
            {:cont, {acc_s, acc_pos, acc_k}}
        end
      end)
    rescue
      haxe_exception ->
        (case {(case haxe_exception do
  %Reflaxe.Elixir.HaxeThrow{value: haxe_unwrapped_value} -> haxe_unwrapped_value
  _ -> haxe_exception
end), haxe_exception} do
          {haxe_catch_value, _} when is_struct(haxe_catch_value, Eof) -> nil
          _ ->
            reraise(haxe_exception, __STACKTRACE__)
        end)
    end
    (len - k)
  end
  def close(_) do
    
  end
  def read_all(struct, bufsize) do
    bufsize = if (Kernel.is_nil(bufsize)), do: 16384, else: bufsize
    buf = Bytes.alloc(bufsize)
    total = BytesBuffer.new()
    try do
      Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), :ok, fn _, acc ->
        try do
          len = read_bytes(struct, buf, 0, bufsize)
          if (len == 0) do
            raise Reflaxe.Elixir.HaxeThrow, [value: {:blocked}]
          end
          if (len < 0 or len > length(buf)) do
            raise Reflaxe.Elixir.HaxeThrow, [value: {:outside_bounds}]
          end
          if (len == 0) do
            nil
          else
            slice = :binary.part(Bytes.get_data(buf), 0, len)
            total = %{total | parts_reversed: [slice | total.parts_reversed]}
            total = %{total | byte_length: total.byte_length + len}
          end
          {:cont, acc}
        catch
          :throw, {:break, break_state} ->
            {:halt, break_state}
          :throw, {:continue, continue_state} ->
            {:cont, continue_state}
          :throw, :break ->
            {:halt, acc}
          :throw, :continue ->
            {:cont, acc}
        end
      end)
    rescue
      haxe_exception ->
        (case {(case haxe_exception do
  %Reflaxe.Elixir.HaxeThrow{value: haxe_unwrapped_value} -> haxe_unwrapped_value
  _ -> haxe_exception
end), haxe_exception} do
          {haxe_catch_value, _} when is_struct(haxe_catch_value, Eof) -> nil
          _ ->
            reraise(haxe_exception, __STACKTRACE__)
        end)
    end
    _ = BytesBuffer.get_bytes(total)
  end
  def read_full_bytes(struct, s, pos, len) do
    {pos, len} = Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {pos, len}, fn _, {acc_pos, acc_len} ->
      try do
        if (acc_len > 0) do
          k = read_bytes(struct, s, acc_pos, acc_len)
          if (k == 0) do
            raise Reflaxe.Elixir.HaxeThrow, [value: {:blocked}]
          end
          acc_pos = acc_pos + k
          acc_len = (acc_len - k)
          {:cont, {acc_pos, acc_len}}
        else
          {:halt, {acc_pos, acc_len}}
        end
      catch
        :throw, {:break, break_state} ->
          {:halt, break_state}
        :throw, {:continue, continue_state} ->
          {:cont, continue_state}
        :throw, :break ->
          {:halt, {acc_pos, acc_len}}
        :throw, :continue ->
          {:cont, {acc_pos, acc_len}}
      end
    end)
  end
  def read(struct, nbytes) do
    s = Bytes.alloc(nbytes)
    p = 0
    {_nbytes, _p} = Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {nbytes, p}, fn _, {acc_nbytes, acc_p} ->
      try do
        if (acc_nbytes > 0) do
          k = read_bytes(struct, s, acc_p, acc_nbytes)
          if (k == 0) do
            raise Reflaxe.Elixir.HaxeThrow, [value: {:blocked}]
          end
          acc_p = acc_p + k
          acc_nbytes = (acc_nbytes - k)
          {:cont, {acc_nbytes, acc_p}}
        else
          {:halt, {acc_nbytes, acc_p}}
        end
      catch
        :throw, {:break, break_state} ->
          {:halt, break_state}
        :throw, {:continue, continue_state} ->
          {:cont, continue_state}
        :throw, :break ->
          {:halt, {acc_nbytes, acc_p}}
        :throw, :continue ->
          {:cont, {acc_nbytes, acc_p}}
      end
    end)
    s
  end
  def read_until(struct, end_param) do
    buf = BytesBuffer.new()
    _ = Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), :ok, fn _, acc ->
  try do
    if ((last = read_byte(struct)) != end_param) do
      buf = %{buf | parts_reversed: [last | buf.parts_reversed]}
      buf = %{buf | byte_length: buf.byte_length + 1}
      {:cont, acc}
    else
      {:halt, acc}
    end
  catch
    :throw, {:break, break_state} ->
      {:halt, break_state}
    :throw, {:continue, continue_state} ->
      {:cont, continue_state}
    :throw, :break ->
      {:halt, acc}
    :throw, :continue ->
      {:cont, acc}
  end
end)
    _ = Bytes.to_string(BytesBuffer.get_bytes(buf))
  end
  def read_line(struct) do
    buf = BytesBuffer.new()
    s = nil
    try do
      _ = Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), :ok, fn _, acc ->
  try do
    if ((last = read_byte(struct)) != 10) do
      buf = %{buf | parts_reversed: [last | buf.parts_reversed]}
      buf = %{buf | byte_length: buf.byte_length + 1}
      {:cont, acc}
    else
      {:halt, acc}
    end
  catch
    :throw, {:break, break_state} ->
      {:halt, break_state}
    :throw, {:continue, continue_state} ->
      {:cont, continue_state}
    :throw, :break ->
      {:halt, acc}
    :throw, :continue ->
      {:cont, acc}
  end
end)
      s = Bytes.to_string(BytesBuffer.get_bytes(buf))
      cond_value = (if ((String.length(s) - 1) < 0) do
        nil
      else
        Enum.at(String.to_charlist(s), (String.length(s) - 1))
      end)
      s = if (cond_value == 13) do
        String.slice(s, 0, -1)
      else
        s
      end
    rescue
      haxe_exception ->
        (case {(case haxe_exception do
  %Reflaxe.Elixir.HaxeThrow{value: haxe_unwrapped_value} -> haxe_unwrapped_value
  _ -> haxe_exception
end), haxe_exception} do
          {e, _} when is_struct(e, Eof) ->
            s = Bytes.to_string(BytesBuffer.get_bytes(buf))
            if (String.length(s) == 0) do
              raise Reflaxe.Elixir.HaxeThrow, [value: e]
            end
          _ ->
            reraise(haxe_exception, __STACKTRACE__)
        end)
    end
    s
  end
  def read_float(struct) do
    FPHelper.i32_to_float(read_int32(struct))
  end
  def read_double(struct) do
    i1 = read_int32(struct)
    i2 = read_int32(struct)
    if (struct.big_endian) do
      FPHelper.i64_to_double(i2, i1)
    else
      FPHelper.i64_to_double(i1, i2)
    end
  end
  def read_int8(struct) do
    n = read_byte(struct)
    if (n >= 128), do: (n - 256), else: n
  end
  def read_int16(struct) do
    ch1 = read_byte(struct)
    ch2 = read_byte(struct)
    n = if (struct.big_endian), do: Bitwise.bor(ch2, Bitwise.bsl(ch1, 8)), else: Bitwise.bor(ch1, Bitwise.bsl(ch2, 8))
    if (Bitwise.band(n, 32768) != 0), do: (n - 65536), else: n
  end
  def read_u_int16(struct) do
    ch1 = read_byte(struct)
    ch2 = read_byte(struct)
    if (struct.big_endian), do: Bitwise.bor(ch2, Bitwise.bsl(ch1, 8)), else: Bitwise.bor(ch1, Bitwise.bsl(ch2, 8))
  end
  def read_int24(struct) do
    ch1 = read_byte(struct)
    ch2 = read_byte(struct)
    ch3 = read_byte(struct)
    n = if (struct.big_endian), do: Bitwise.bor(Bitwise.bor(ch3, Bitwise.bsl(ch2, 8)), Bitwise.bsl(ch1, 16)), else: Bitwise.bor(Bitwise.bor(ch1, Bitwise.bsl(ch2, 8)), Bitwise.bsl(ch3, 16))
    if (Bitwise.band(n, 8388608) != 0), do: (n - 16777216), else: n
  end
  def read_u_int24(struct) do
    ch1 = read_byte(struct)
    ch2 = read_byte(struct)
    ch3 = read_byte(struct)
    if (struct.big_endian), do: Bitwise.bor(Bitwise.bor(ch3, Bitwise.bsl(ch2, 8)), Bitwise.bsl(ch1, 16)), else: Bitwise.bor(Bitwise.bor(ch1, Bitwise.bsl(ch2, 8)), Bitwise.bsl(ch3, 16))
  end
  def read_int32(struct) do
    ch1 = read_byte(struct)
    ch2 = read_byte(struct)
    ch3 = read_byte(struct)
    ch4 = read_byte(struct)
    if (struct.big_endian), do: Bitwise.bor(Bitwise.bor(Bitwise.bor(ch4, Bitwise.bsl(ch3, 8)), Bitwise.bsl(ch2, 16)), Bitwise.bsl(ch1, 24)), else: Bitwise.bor(Bitwise.bor(Bitwise.bor(ch1, Bitwise.bsl(ch2, 8)), Bitwise.bsl(ch3, 16)), Bitwise.bsl(ch4, 24))
  end
  def read_string(struct, len, encoding) do
    b = Bytes.alloc(len)
    _ = read_full_bytes(struct, b, 0, len)
    _ = Bytes.get_string(b, 0, len, encoding)
  end
end
