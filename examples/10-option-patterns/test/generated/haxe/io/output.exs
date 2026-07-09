defmodule Output do
  def set_big_endian(struct, b) do
    _ = %{struct | big_endian: b}
    b
  end
  def write_byte(_struct, _c) do
    raise Reflaxe.Elixir.HaxeThrow, [value: NotImplementedException.new(nil, nil, %{file_name: "elixir/_std/haxe/io/Output.hx", line_number: 38, class_name: "haxe.io.Output", method_name: "writeByte"})]
  end
  def write_bytes(struct, s, pos, len) do
    if (pos < 0 or len < 0 or pos + len > s.length) do
      raise Reflaxe.Elixir.HaxeThrow, [value: {:outside_bounds}]
    end
    k = len
    {_pos, _k} = Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {pos, k}, fn _, {acc_pos, acc_k} ->
      try do
        if (acc_k > 0) do
          _ = apply(Map.get(struct, :__reflaxe_class__) || Map.get(struct, :__struct__), :write_byte, [struct, apply(Map.get(s, :__reflaxe_class__) || Map.get(s, :__struct__), :get, [s, acc_pos])])
          acc_pos = acc_pos + 1
          acc_k = (acc_k - 1)
          {:cont, {acc_pos, acc_k}}
        else
          {:halt, {acc_pos, acc_k}}
        end
      catch
        :throw, {:break, break_state} ->
          {:halt, break_state}
        :throw, {:continue, continue_state} ->
          {:cont, continue_state}
        :throw, :break ->
          {:halt, {acc_pos, acc_k}}
        :throw, :continue ->
          {:cont, {acc_pos, acc_k}}
      end
    end)
    len
  end
  def flush(_struct) do

  end
  def close(_struct) do

  end
  def write(struct, s) do
    l = s.length
    p = 0
    {_l, _p} = Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {l, p}, fn _, {acc_l, acc_p} ->
      try do
        if (acc_l > 0) do
          k = apply(Map.get(struct, :__reflaxe_class__) || Map.get(struct, :__struct__), :write_bytes, [struct, s, acc_p, acc_l])
          if (k == 0) do
            raise Reflaxe.Elixir.HaxeThrow, [value: {:blocked}]
          end
          acc_p = acc_p + k
          acc_l = (acc_l - k)
          {:cont, {acc_l, acc_p}}
        else
          {:halt, {acc_l, acc_p}}
        end
      catch
        :throw, {:break, break_state} ->
          {:halt, break_state}
        :throw, {:continue, continue_state} ->
          {:cont, continue_state}
        :throw, :break ->
          {:halt, {acc_l, acc_p}}
        :throw, :continue ->
          {:cont, {acc_l, acc_p}}
      end
    end)
  end
  def write_full_bytes(struct, s, pos, len) do
    {_pos, _len} = Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {pos, len}, fn _, {acc_pos, acc_len} ->
      try do
        if (acc_len > 0) do
          k = apply(Map.get(struct, :__reflaxe_class__) || Map.get(struct, :__struct__), :write_bytes, [struct, s, acc_pos, acc_len])
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
  def write_float(struct, x) do
    apply(Map.get(struct, :__reflaxe_class__) || Map.get(struct, :__struct__), :write_int32, [struct, FPHelper.float_to_i32(x)])
  end
  def write_double(struct, x) do
    i64 = FPHelper.double_to_i64(x)
    if (struct.big_endian) do
      _ =
        apply(Map.get(struct, :__reflaxe_class__) || Map.get(struct, :__struct__), :write_int32, (fn -> [struct, (fn ->
          x = :erlang.bsr(i64, 32)
          reflaxe_i32_clamp = :erlang.band(x, 4294967295)
          if reflaxe_i32_clamp >= 2147483648, do: reflaxe_i32_clamp - 4294967296, else: reflaxe_i32_clamp
        end).()] end).())
      _ =
        apply(Map.get(struct, :__reflaxe_class__) || Map.get(struct, :__struct__), :write_int32, (fn -> [struct, (fn ->
          low_unsigned = :erlang.band(i64, 4294967295)
          signed = if low_unsigned >= 2147483648, do: low_unsigned - 4294967296, else: low_unsigned
          reflaxe_i32_clamp = :erlang.band(signed, 4294967295)
          if reflaxe_i32_clamp >= 2147483648, do: reflaxe_i32_clamp - 4294967296, else: reflaxe_i32_clamp
        end).()] end).())
    else
      _ =
        apply(Map.get(struct, :__reflaxe_class__) || Map.get(struct, :__struct__), :write_int32, (fn -> [struct, (fn ->
          low_unsigned = :erlang.band(i64, 4294967295)
          signed = if low_unsigned >= 2147483648, do: low_unsigned - 4294967296, else: low_unsigned
          reflaxe_i32_clamp = :erlang.band(signed, 4294967295)
          if reflaxe_i32_clamp >= 2147483648, do: reflaxe_i32_clamp - 4294967296, else: reflaxe_i32_clamp
        end).()] end).())
      _ =
        apply(Map.get(struct, :__reflaxe_class__) || Map.get(struct, :__struct__), :write_int32, (fn -> [struct, (fn ->
          x = :erlang.bsr(i64, 32)
          reflaxe_i32_clamp = :erlang.band(x, 4294967295)
          if reflaxe_i32_clamp >= 2147483648, do: reflaxe_i32_clamp - 4294967296, else: reflaxe_i32_clamp
        end).()] end).())
    end
  end
  def write_int8(struct, x) do
    if (x < -128 or x >= 128) do
      raise Reflaxe.Elixir.HaxeThrow, [value: {:overflow}]
    end
    _ = apply(Map.get(struct, :__reflaxe_class__) || Map.get(struct, :__struct__), :write_byte, [struct, Bitwise.band(x, 255)])
  end
  def write_int16(struct, x) do
    if (x < -32768 or x >= 32768) do
      raise Reflaxe.Elixir.HaxeThrow, [value: {:overflow}]
    end
    _ = apply(Map.get(struct, :__reflaxe_class__) || Map.get(struct, :__struct__), :write_u_int16, [struct, Bitwise.band(x, 65535)])
  end
  def write_u_int16(struct, x) do
    if (x < 0 or x >= 65536) do
      raise Reflaxe.Elixir.HaxeThrow, [value: {:overflow}]
    end
    if (struct.big_endian) do
      _ = apply(Map.get(struct, :__reflaxe_class__) || Map.get(struct, :__struct__), :write_byte, [struct, Bitwise.bsr(x, 8)])
      _ = apply(Map.get(struct, :__reflaxe_class__) || Map.get(struct, :__struct__), :write_byte, [struct, Bitwise.band(x, 255)])
    else
      _ = apply(Map.get(struct, :__reflaxe_class__) || Map.get(struct, :__struct__), :write_byte, [struct, Bitwise.band(x, 255)])
      _ = apply(Map.get(struct, :__reflaxe_class__) || Map.get(struct, :__struct__), :write_byte, [struct, Bitwise.bsr(x, 8)])
    end
  end
  def write_int24(struct, x) do
    if (x < -8388608 or x >= 8388608) do
      raise Reflaxe.Elixir.HaxeThrow, [value: {:overflow}]
    end
    _ = apply(Map.get(struct, :__reflaxe_class__) || Map.get(struct, :__struct__), :write_u_int24, [struct, Bitwise.band(x, 16777215)])
  end
  def write_u_int24(struct, x) do
    if (x < 0 or x >= 16777216) do
      raise Reflaxe.Elixir.HaxeThrow, [value: {:overflow}]
    end
    if (struct.big_endian) do
      _ = apply(Map.get(struct, :__reflaxe_class__) || Map.get(struct, :__struct__), :write_byte, [struct, Bitwise.bsr(x, 16)])
      _ = apply(Map.get(struct, :__reflaxe_class__) || Map.get(struct, :__struct__), :write_byte, [struct, Bitwise.band(Bitwise.bsr(x, 8), 255)])
      _ = apply(Map.get(struct, :__reflaxe_class__) || Map.get(struct, :__struct__), :write_byte, [struct, Bitwise.band(x, 255)])
    else
      _ = apply(Map.get(struct, :__reflaxe_class__) || Map.get(struct, :__struct__), :write_byte, [struct, Bitwise.band(x, 255)])
      _ = apply(Map.get(struct, :__reflaxe_class__) || Map.get(struct, :__struct__), :write_byte, [struct, Bitwise.band(Bitwise.bsr(x, 8), 255)])
      _ = apply(Map.get(struct, :__reflaxe_class__) || Map.get(struct, :__struct__), :write_byte, [struct, Bitwise.bsr(x, 16)])
    end
  end
  def write_int32(struct, x) do
    if (struct.big_endian) do
      _ = apply(Map.get(struct, :__reflaxe_class__) || Map.get(struct, :__struct__), :write_byte, [struct, Bitwise.bsr(x, 24)])
      _ = apply(Map.get(struct, :__reflaxe_class__) || Map.get(struct, :__struct__), :write_byte, [struct, Bitwise.band(Bitwise.bsr(x, 16), 255)])
      _ = apply(Map.get(struct, :__reflaxe_class__) || Map.get(struct, :__struct__), :write_byte, [struct, Bitwise.band(Bitwise.bsr(x, 8), 255)])
      _ = apply(Map.get(struct, :__reflaxe_class__) || Map.get(struct, :__struct__), :write_byte, [struct, Bitwise.band(x, 255)])
    else
      _ = apply(Map.get(struct, :__reflaxe_class__) || Map.get(struct, :__struct__), :write_byte, [struct, Bitwise.band(x, 255)])
      _ = apply(Map.get(struct, :__reflaxe_class__) || Map.get(struct, :__struct__), :write_byte, [struct, Bitwise.band(Bitwise.bsr(x, 8), 255)])
      _ = apply(Map.get(struct, :__reflaxe_class__) || Map.get(struct, :__struct__), :write_byte, [struct, Bitwise.band(Bitwise.bsr(x, 16), 255)])
      _ = apply(Map.get(struct, :__reflaxe_class__) || Map.get(struct, :__struct__), :write_byte, [struct, Bitwise.bsr(x, 24)])
    end
  end
  def prepare(_struct, _nbytes) do

  end
  def write_input(struct, i, bufsize) do
    bufsize = if (Kernel.is_nil(bufsize)), do: 4096, else: bufsize
    buf = Bytes.alloc(bufsize)
    _ =
      Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), :ok, fn _, acc ->
        try do
          try do
            len = apply(Map.get(i, :__reflaxe_class__) || Map.get(i, :__struct__), :read_bytes, [i, buf, 0, bufsize])
            if (len == 0) do
              raise Reflaxe.Elixir.HaxeThrow, [value: {:blocked}]
            end
            p = 0
            {_len, _p} = Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {len, p}, fn _, {acc_len, acc_p} ->
              try do
                if (acc_len > 0) do
                  k = apply(Map.get(struct, :__reflaxe_class__) || Map.get(struct, :__struct__), :write_bytes, [struct, buf, acc_p, acc_len])
                  if (k == 0) do
                    raise Reflaxe.Elixir.HaxeThrow, [value: {:blocked}]
                  end
                  acc_p = acc_p + k
                  acc_len = (acc_len - k)
                  {:cont, {acc_len, acc_p}}
                else
                  {:halt, {acc_len, acc_p}}
                end
              catch
                :throw, {:break, break_state} ->
                  {:halt, break_state}
                :throw, {:continue, continue_state} ->
                  {:cont, continue_state}
                :throw, :break ->
                  {:halt, {acc_len, acc_p}}
                :throw, :continue ->
                  {:cont, {acc_len, acc_p}}
              end
            end)
          rescue
            haxe_exception ->
              Process.put(:__reflaxe_last_stacktrace__, __STACKTRACE__)
              (case {(case haxe_exception do
                %Reflaxe.Elixir.HaxeThrow{value: haxe_unwrapped_value} -> haxe_unwrapped_value
                _ -> haxe_exception
              end), haxe_exception} do
                {haxe_catch_value, _} when is_struct(haxe_catch_value, Eof) or is_map(haxe_catch_value) and is_map_key(haxe_catch_value, :__reflaxe_class__) and :erlang.map_get(:__reflaxe_class__, haxe_catch_value) == Eof -> throw({:break, acc})
                _ ->
                  reraise(haxe_exception, __STACKTRACE__)
              end)
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
  end
  def write_string(struct, s, encoding) do
    b = Bytes.of_string(s, encoding)
    _ = apply(Map.get(struct, :__reflaxe_class__) || Map.get(struct, :__struct__), :write_full_bytes, [struct, b, 0, b.length])
  end
end
