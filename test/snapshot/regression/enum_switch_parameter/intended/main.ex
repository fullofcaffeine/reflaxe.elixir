defmodule Main do
  def main() do
    test_result = {:ok, "success"}
    opt = to_option(test_result)
    unwrapped = unwrap_or(test_result, "default")
    _ = Log.trace(opt, %{:file_name => "Main.hx", :line_number => 26, :class_name => "Main", :method_name => "main"})
    _ = Log.trace(unwrapped, %{:file_name => "Main.hx", :line_number => 27, :class_name => "Main", :method_name => "main"})
  end
  def to_option(result) do
    (case result do
      {:ok, value} ->
        some = value
        {:some, value}
      {:error, _value} -> {:none}
    end)
  end
  def unwrap_or(result, default_value) do
    (case result do
      {:ok, value} ->
        default_value = value
        default_value
      {:error, default_value} ->
        default_value = default_value
        default_value
    end)
  end
end
