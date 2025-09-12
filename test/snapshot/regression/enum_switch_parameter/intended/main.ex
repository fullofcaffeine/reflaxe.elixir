defmodule Main do
  def main() do
    test_result = {:ok, "success"}
    opt = to_option(test_result)
    unwrapped = unwrap_or(test_result, "default")
    Log.trace(opt, %{:file_name => "Main.hx", :line_number => 26, :class_name => "Main", :method_name => "main"})
    Log.trace(unwrapped, %{:file_name => "Main.hx", :line_number => 27, :class_name => "Main", :method_name => "main"})
  end
  def to_option(_result) do
    case (_result) do
      {:ok, value} ->
        g = elem(_result, 1)
        value = g
        {:some, value}
      {:error, error} ->
        _g = elem(_result, 1)
        {:none}
    end
  end
  def unwrap_or(_result, default_value) do
    case (_result) do
      {:ok, value} ->
        g = elem(_result, 1)
        value = g
        value
      {:error, error} ->
        _g = elem(_result, 1)
        default_value
    end
  end
end