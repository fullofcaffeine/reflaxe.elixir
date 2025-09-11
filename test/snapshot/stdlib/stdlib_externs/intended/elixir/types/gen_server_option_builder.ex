defmodule GenServerOptionBuilder do
  def with_name(name, options) do
    if (options == nil) do
      options = %{}
    end
    name = __elixir__.call("String.to_atom(" <> name <> ")")
    options
  end
  def with_via(module, name, options) do
    if (options == nil) do
      options = %{}
    end
    name = __elixir__.call("{:via, " <> Std.string(module) <> ", " <> Std.string(name) <> "}")
    options
  end
  def with_global_name(name, options) do
    if (options == nil) do
      options = %{}
    end
    name = __elixir__.call("{:global, String.to_atom(" <> name <> ")}")
    options
  end
  def with_infinite_timeout(options) do
    if (options == nil) do
      options = %{}
    end
    timeout = :infinity
    options
  end
  def with_trace(options) do
    if (options == nil) do
      options = %{}
    end
    if (Map.get(options, :debug) == nil) do
      debug = []
    end
    options.debug ++ [:trace]
    options
  end
  def with_log(options) do
    if (options == nil) do
      options = %{}
    end
    if (Map.get(options, :debug) == nil) do
      debug = []
    end
    options.debug ++ [:log]
    options
  end
  def with_statistics(options) do
    if (options == nil) do
      options = %{}
    end
    if (Map.get(options, :debug) == nil) do
      debug = []
    end
    options.debug ++ [:statistics]
    options
  end
end