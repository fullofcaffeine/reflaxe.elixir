defmodule Process do
  def new(cmd, args, detached) do
    struct = %{:stdout => nil, :stderr => nil, :stdin => nil, :port => nil, :exit_code_cache => nil, :is_closed => nil}
    struct = %{struct | is_closed: false}
    struct = %{struct | exit_code_cache: nil}
    use_stdio = detached != true
    if (Kernel.is_nil(args)) do
      struct = %{struct | port: open_shell_command(cmd, use_stdio)}
    else
      struct = %{struct | port: open_executable(cmd, args, use_stdio)}
    end
    if (use_stdio) do
      merged_output = PortInput.new(struct.port)
      struct = %{struct | stdout: merged_output}
      struct = %{struct | stderr: merged_output}
      _ = %{struct | stdin: PortOutput.new(struct.port)}
    else
      disabled_input = disabled_input.new()
      struct = %{struct | stdout: disabled_input}
      struct = %{struct | stderr: disabled_input}
      _ = %{struct | stdin: DisabledOutput.new()}
    end
    struct
  end
  def get_pid(struct) do
    
            port = struct.port
            case :erlang.port_info(port, :os_pid) do
              {:os_pid, pid} -> pid
              _ -> -1
            end
        
  end
  def exit_code(struct, block) do
    if (not Kernel.is_nil(struct.exit_code_cache)) do
      struct.exit_code_cache
    else
      maybe = 
            port = struct.port
            receive do
              {^port, {:exit_status, status}} -> status
            after 0 ->
              nil
            end
        
      if (not Kernel.is_nil(maybe)) do
        _ = %{struct | exit_code_cache: maybe}
        maybe
      else
        if (not block) do
          nil
        else
          status = 
            port = struct.port
            receive do
              {^port, {:exit_status, status}} -> status
            end
        
          _ = %{struct | exit_code_cache: status}
          status
        end
      end
    end
  end
  def close(struct) do
    if (struct.is_closed) do
      nil
    else
      struct = %{struct | is_closed: true}
      
            port = struct.port
            if Port.info(port) != nil do
              Port.close(port)
            end
        
    end
  end
  def kill(struct) do
    close(struct)
  end
  defp open_executable(cmd, args, use_stdio) do
    executable = System.find_executable(cmd)
    if (Kernel.is_nil(executable)) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "sys.io.Process: executable not found: " <> cmd]
    end
    
            stdio_opt = if use_stdio, do: :use_stdio, else: :nouse_stdio
            opts = [:binary, :exit_status, stdio_opt, {:args, args}]
            opts = if use_stdio, do: [:stderr_to_stdout | opts], else: opts
            Port.open({:spawn_executable, executable}, opts)
        
  end
  defp open_shell_command(cmd, use_stdio) do
    shell = System.find_executable("sh")
    if (Kernel.is_nil(shell)) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "sys.io.Process: shell executable not found (sh)"]
    end
    
            stdio_opt = if use_stdio, do: :use_stdio, else: :nouse_stdio
            opts = [:binary, :exit_status, stdio_opt, {:args, ["-c", cmd]}]
            opts = if use_stdio, do: [:stderr_to_stdout | opts], else: opts
            Port.open({:spawn_executable, shell}, opts)
        
  end
end
