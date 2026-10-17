defmodule CallStack_Impl_ do
  def call_stack() do
    stack_trace_to_haxe((
    case Process.info(self(), :current_stacktrace) do
      {:current_stacktrace, stacktrace} -> stacktrace
      _ -> []
    end
    ))
  end
  def stack_trace_to_haxe(stack_trace) do

    Enum.map(stack_trace, fn
      {module, function, _arity, location} ->
        file =
          case Keyword.get(location, :file) do
            nil -> "<unknown>"
            chars when is_list(chars) -> List.to_string(chars)
            binary when is_binary(binary) -> binary
            other -> Kernel.to_string(other)
          end

        line = Keyword.get(location, :line, 0) || 0
        {:file_pos, {:method, Kernel.to_string(module), Kernel.to_string(function)}, file, line, nil}

      {module, function, _arity} ->
        {:method, Kernel.to_string(module), Kernel.to_string(function)}

      other ->
        {:module, Kernel.to_string(other)}
    end)

  end
end
