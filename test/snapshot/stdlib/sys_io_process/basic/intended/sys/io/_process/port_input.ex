defmodule PortInput do
  def new(port_param) do
    struct = %{:port => nil, :buffer => nil, :buffer_offset => nil, :ended => nil}
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
    Bytes.get(struct.buffer, struct.buffer_offset)
  end
  def read_bytes(_, buf, pos, len) do
    if (pos < 0 or len < 0 or pos + len > length(buf)) do
      raise Reflaxe.Elixir.HaxeThrow, [value: {:outside_bounds}]
    end
    if (len == 0) do
      0
    else
      total_read = 0
      _ = total_read
    end
  end
  defp ensure_buffered(struct) do
    if (struct.ended) do
      false
    else
      if (not Kernel.is_nil(struct.buffer) and struct.buffer_offset < length(struct.buffer)) do
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
end
