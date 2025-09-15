defmodule Main do
  defp unwrap_or(result, default_value) do
    case result do
      {:ok, value} ->
        value
      {:error, _reason} ->
        default_value
    end
  end

  defp to_option(result) do
    case result do
      {:ok, value} ->
        value
      {:error, _reason} ->
        nil
    end
  end

  def main() do
    result = {:ok, 42}
    value = unwrap_or(result, 0)
    Log.trace("Value: #{value}", %{:file_name => "Main.hx", :line_number => 39, :class_name => "Main", :method_name => "main"})

    option = to_option(result)
    Log.trace("Option: #{option}", %{:file_name => "Main.hx", :line_number => 42, :class_name => "Main", :method_name => "main"})

    error_result = {:error, "Something went wrong"}
    fallback = unwrap_or(error_result, -1)
    Log.trace("Fallback: #{fallback}", %{:file_name => "Main.hx", :line_number => 46, :class_name => "Main", :method_name => "main"})
  end
end