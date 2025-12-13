defmodule GenServerOptionBuilder do
  def with_name(name, options) do
    if (Kernel.is_nil(options)) do
      options = %{}
    end
    options = Map.put(options, "name", _elixir__.("String.to_atom(#{(fn -> name end).()})"))
    options
  end
  def with_via(module, name, options) do
    if (Kernel.is_nil(options)) do
      options = %{}
    end
    options = Map.put(options, "name", _elixir__.("{:via, #{(fn -> inspect(module) end).()}, #{(fn -> inspect(name) end).()}}"))
    options
  end
  def with_global_name(name, options) do
    if (Kernel.is_nil(options)) do
      options = %{}
    end
    options = Map.put(options, "name", _elixir__.("{:global, String.to_atom(#{(fn -> name end).()})}"))
    options
  end
  def with_infinite_timeout(options) do
    if (Kernel.is_nil(options)) do
      options = %{}
    end
    options = Map.put(options, "timeout", :infinity)
    options
  end
  def with_trace(options) do
    if (Kernel.is_nil(options)) do
      options = %{}
    end
    options = if (Kernel.is_nil(options.debug)) do
      Map.put(options, "debug", [])
    else
      options
    end
    _ = options.debug.push(:trace)
    options
  end
  def with_log(options) do
    if (Kernel.is_nil(options)) do
      options = %{}
    end
    options = if (Kernel.is_nil(options.debug)) do
      Map.put(options, "debug", [])
    else
      options
    end
    _ = options.debug.push(:log)
    options
  end
  def with_statistics(options) do
    if (Kernel.is_nil(options)) do
      options = %{}
    end
    options = if (Kernel.is_nil(options.debug)) do
      Map.put(options, "debug", [])
    else
      options
    end
    _ = options.debug.push(:statistics)
    options
  end
end
