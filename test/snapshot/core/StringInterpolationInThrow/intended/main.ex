defmodule Main do
  def main() do
    _ = test_simple_interpolation()
    _ = test_complex_conditional()
    _ = test_nested_function_calls()
    _ = test_multiple_interpolations()
    _ = test_nil_handling()
    _ = test_in_raise()
  end
  defp test_simple_interpolation() do
    try do
      raise Reflaxe.Elixir.HaxeThrow, [value: "Error code: " <> Kernel.to_string(error_code)]
    rescue
      haxe_exception ->
        (case {(case haxe_exception do
  %Reflaxe.Elixir.HaxeThrow{value: haxe_unwrapped_value} -> haxe_unwrapped_value
  _ -> haxe_exception
end), haxe_exception} do
          {e, _} when is_binary(e) -> nil
          _ ->
            reraise(haxe_exception, __STACKTRACE__)
        end)
    end
  end
  defp test_complex_conditional() do
    try do
      errors = get_errors_map(changeset)
      raise Reflaxe.Elixir.HaxeThrow, [value: "Changeset has errors: " <> (if (not Kernel.is_nil(errors)), do: errors.to_string.(), else: "null")]
    rescue
      haxe_exception ->
        (case {(case haxe_exception do
  %Reflaxe.Elixir.HaxeThrow{value: haxe_unwrapped_value} -> haxe_unwrapped_value
  _ -> haxe_exception
end), haxe_exception} do
          {e, _} when is_binary(e) -> nil
          _ ->
            reraise(haxe_exception, __STACKTRACE__)
        end)
    end
  end
  defp test_nested_function_calls() do
    try do
      raise Reflaxe.Elixir.HaxeThrow, [value: "Failed to process: " <> format_data(process_data(data))]
    rescue
      haxe_exception ->
        (case {(case haxe_exception do
  %Reflaxe.Elixir.HaxeThrow{value: haxe_unwrapped_value} -> haxe_unwrapped_value
  _ -> haxe_exception
end), haxe_exception} do
          {e, _} when is_binary(e) -> nil
          _ ->
            reraise(haxe_exception, __STACKTRACE__)
        end)
    end
  end
  defp test_multiple_interpolations() do
    try do
      raise Reflaxe.Elixir.HaxeThrow, [value: "User " <> user <> " cannot " <> action <> " resource " <> resource]
    rescue
      haxe_exception ->
        (case {(case haxe_exception do
  %Reflaxe.Elixir.HaxeThrow{value: haxe_unwrapped_value} -> haxe_unwrapped_value
  _ -> haxe_exception
end), haxe_exception} do
          {e, _} when is_binary(e) -> nil
          _ ->
            reraise(haxe_exception, __STACKTRACE__)
        end)
    end
  end
  defp test_nil_handling() do
    try do
      raise Reflaxe.Elixir.HaxeThrow, [value: "Value is: " <> (if (Kernel.is_nil(maybe_value)), do: "nil", else: maybe_value)]
    rescue
      haxe_exception ->
        (case {(case haxe_exception do
  %Reflaxe.Elixir.HaxeThrow{value: haxe_unwrapped_value} -> haxe_unwrapped_value
  _ -> haxe_exception
end), haxe_exception} do
          {e, _} when is_binary(e) -> nil
          _ ->
            reraise(haxe_exception, __STACKTRACE__)
        end)
    end
  end
  defp test_in_raise() do
    try do
      raise Reflaxe.Elixir.HaxeThrow, [value: CustomError.new("Error in " <> module <> "." <> func)]
    rescue
      haxe_exception ->
        (case {(case haxe_exception do
  %Reflaxe.Elixir.HaxeThrow{value: haxe_unwrapped_value} -> haxe_unwrapped_value
  _ -> haxe_exception
end), haxe_exception} do
          {e, _} when is_struct(e, CustomError) -> nil
          _ ->
            reraise(haxe_exception, __STACKTRACE__)
        end)
    end
  end
  defp get_errors_map(changeset) do
    (case changeset do
      dyn_obj ->
        (case Map.fetch(dyn_obj, "errors") do
          {:ok, dyn_value} -> dyn_value
          _ ->
            Map.get(dyn_obj, :errors)
        end)
    end)
  end
end
