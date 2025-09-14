defmodule Main do
  defp unwrap_or(result, default_value) do
    case (result) do
      {:ok, value} ->
        g = elem(result, 1)
        value = g
        value
      {:error, reason} ->
        _g = elem(result, 1)
        default_value
    end
  end
  defp to_option(result) do
    case (result) do
      {:ok, value} ->
        g = elem(result, 1)
        value = g
        value
      {:error, reason} ->
        _g = elem(result, 1)
        nil
    end
  end
  def main() do
    result = {:ok, 42}
    value = unwrap_or(result, 0)
    Log.trace("Value: " <> Kernel.to_string(value), %{:file_name => "Main.hx", :line_number => 39, :class_name => "Main", :method_name => "main"})
    option = to_option(result)
    Log.trace("Option: " <> Kernel.to_string(option), %{:file_name => "Main.hx", :line_number => 42, :class_name => "Main", :method_name => "main"})
    error_result = {:error, "Something went wrong"}
    fallback = unwrap_or(error_result, -1)
    Log.trace("Fallback: " <> Kernel.to_string(fallback), %{:file_name => "Main.hx", :line_number => 46, :class_name => "Main", :method_name => "main"})
  end
end