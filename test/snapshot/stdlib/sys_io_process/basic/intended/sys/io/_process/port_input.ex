defmodule PortInput do
  def new(port_param) do
    struct = %{:__reflaxe_class__ => PortInput, :port => nil, :buffer => nil, :buffer_offset => nil, :ended => nil, :big_endian => nil}
    struct = %{struct | ended: false}
    struct = %{struct | buffer_offset: 0}
    struct = %{struct | buffer: nil}
    struct = %{struct | port: port_param}
    struct
  end
  def read_byte(struct) do
    if (not ensure_buffered(struct)) do
      raise Reflaxe.Elixir.HaxeThrow, [value: Eof.new()]
    end
    struct = %{struct | buffer_offset: struct.buffer_offset + 1}
    reflaxe_dispatch_receiver = struct.buffer
    _ = apply(Map.get(reflaxe_dispatch_receiver, :__reflaxe_class__) || Map.get(reflaxe_dispatch_receiver, :__struct__), :get, [reflaxe_dispatch_receiver, struct.buffer_offset])
  end
  def read_all(struct, _bufsize) do
    data = (
            port = struct.port
            chunks = Enum.reduce_while(Stream.repeatedly(fn -> :ok end), [], fn _, acc ->
              receive do
                {^port, {:data, chunk}} -> {:cont, [chunk | acc]}
                {^port, {:exit_status, status}} ->
                  send(self(), {port, {:exit_status, status}})
                  {:halt, acc}
              end
            end)
            :erlang.iolist_to_binary(Enum.reverse(chunks))
        )
    _ = Bytes.of_data(data)
  end
  def read_bytes(struct, buf, pos, len) do
    if (pos < 0 or len < 0 or pos + len > buf.length) do
      raise Reflaxe.Elixir.HaxeThrow, [value: {:outside_bounds}]
    end
    if (len == 0) do
      0
    else
      total_read = 0
      {total_read} = Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {total_read}, fn _, {acc_total_read} ->
        try do
          if (acc_total_read < len) do
            if (not ensure_buffered(struct)) do
              throw({:break, {acc_total_read}})
            end
            available = (struct.buffer.length - struct.buffer_offset)
            remaining = (len - acc_total_read)
            to_copy = if (remaining < available), do: remaining, else: available
            _ = apply(Map.get(buf, :__reflaxe_class__) || Map.get(buf, :__struct__), :blit, [buf, pos + acc_total_read, struct.buffer, struct.buffer_offset, to_copy])
            _ = %{struct | buffer_offset: struct.buffer_offset + to_copy}
            acc_total_read = acc_total_read + to_copy
            {:cont, {acc_total_read}}
          else
            {:halt, {acc_total_read}}
          end
        catch
          :throw, {:break, break_state} ->
            {:halt, break_state}
          :throw, {:continue, continue_state} ->
            {:cont, continue_state}
          :throw, :break ->
            {:halt, {acc_total_read}}
          :throw, :continue ->
            {:cont, {acc_total_read}}
        end
      end)
      if (total_read == 0) do
        raise Reflaxe.Elixir.HaxeThrow, [value: Eof.new()]
      end
      total_read
    end
  end
  defp ensure_buffered(struct) do
    if (struct.ended) do
      false
    else
      if (not Kernel.is_nil(struct.buffer) and struct.buffer_offset < struct.buffer.length) do
        true
      else
        struct = %{struct | buffer: nil}
        struct = %{struct | buffer_offset: 0}
        data = receive_data_non_blocking(struct)
        if (not Kernel.is_nil(data)) do
          _ = %{struct | buffer: Bytes.of_data(data)}
          true
        else
          if (not Port.info(struct.port) != nil) do
            _ = %{struct | ended: true}
            false
          else
            message = receive_data_or_exit_blocking(struct)
            tag = elem(message, 0)
            if (tag == :data) do
              payload = elem(message, 1)
              _ = %{struct | buffer: Bytes.of_data(payload)}
              true
            else
              if (tag == :exit) do
                status = elem(message, 1)
                send(self(), {struct.port, {:exit_status, status}})
                _ = %{struct | ended: true}
                false
              else
                _ = %{struct | ended: true}
                false
              end
            end
          end
        end
      end
    end
  end
  defp receive_data_non_blocking(struct) do
    
            port = struct.port
            receive do
              {^port, {:data, data}} -> data
            after 0 ->
              nil
            end
        
  end
  defp receive_data_or_exit_blocking(struct) do
    
            port = struct.port
            receive do
              {^port, {:data, data}} -> {:data, data}
              {^port, {:exit_status, status}} -> {:exit, status}
            end
        
  end
  def set_big_endian(struct, b) do
    Input.set_big_endian(struct, b)
  end
  def close(struct) do
    Input.close(struct)
  end
  def read_full_bytes(struct, s, pos, len) do
    Input.read_full_bytes(struct, s, pos, len)
  end
  def read(struct, nbytes) do
    Input.read(struct, nbytes)
  end
  def read_until(struct, end_param) do
    Input.read_until(struct, end_param)
  end
  def read_line(struct) do
    Input.read_line(struct)
  end
  def read_float(struct) do
    Input.read_float(struct)
  end
  def read_double(struct) do
    Input.read_double(struct)
  end
  def read_int8(struct) do
    Input.read_int8(struct)
  end
  def read_int16(struct) do
    Input.read_int16(struct)
  end
  def read_u_int16(struct) do
    Input.read_u_int16(struct)
  end
  def read_int24(struct) do
    Input.read_int24(struct)
  end
  def read_u_int24(struct) do
    Input.read_u_int24(struct)
  end
  def read_int32(struct) do
    Input.read_int32(struct)
  end
  def read_string(struct, len, encoding) do
    Input.read_string(struct, len, encoding)
  end
end
