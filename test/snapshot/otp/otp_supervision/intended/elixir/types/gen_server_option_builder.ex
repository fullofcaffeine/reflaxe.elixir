defmodule GenServerOptionBuilder do
  def with_name(name, options) do
    options = if (Kernel.is_nil(options)), do: %{}, else: options
    options = Map.put(options, "name", elixir__.("String.to_atom(#{name})"))
    options
  end
  def with_via(module, name, options) do
    options = if (Kernel.is_nil(options)), do: %{}, else: options
    options = Map.put(options, "name", elixir__.("{:via, #{Kernel.to_string(module)}, #{Kernel.to_string(name)}}"))
    options
  end
  def with_global_name(name, options) do
    options = if (Kernel.is_nil(options)), do: %{}, else: options
    options = Map.put(options, "name", elixir__.("{:global, String.to_atom(#{name})}"))
    options
  end
  def with_infinite_timeout(options) do
    options = if (Kernel.is_nil(options)), do: %{}, else: options
    options = Map.put(options, "timeout", :infinity)
    options
  end
  def with_trace(options) do
    options = if (Kernel.is_nil(options)), do: %{}, else: options
    options = if (Kernel.is_nil(options.debug)) do
      Map.put(options, "debug", [])
    else
      options
    end
    options.debug ++ [:trace]
    options
  end
  def with_log(options) do
    options = if (Kernel.is_nil(options)), do: %{}, else: options
    options = if (Kernel.is_nil(options.debug)) do
      Map.put(options, "debug", [])
    else
      options
    end
    options.debug ++ [:log]
    options
  end
  def with_statistics(options) do
    options = if (Kernel.is_nil(options)), do: %{}, else: options
    options = if (Kernel.is_nil(options.debug)) do
      Map.put(options, "debug", [])
    else
      options
    end
    options.debug ++ [:statistics]
    options
  end
end
