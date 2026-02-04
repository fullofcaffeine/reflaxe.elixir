defmodule Main do
  def main() do
    _result = process_value({:ok, "success"})
    _ = process_value({:error, "failed"})
    _color = describe_color({:red})
    _ = describe_color({:green})
    _ = describe_color({:blue})
    _nested = handle_nested({:some, {:ok, 42}})
    nil
  end
  defp process_value(value) do
    (case value do
      {:ok, msg} -> "Success: #{msg}"
      {:error, err} -> "Error: #{err}"
    end)
  end
  defp describe_color(color) do
    (case color do
      {:red} -> "The color is red"
      {:green} -> "The color is green"
      {:blue} -> "The color is blue"
    end)
  end
  defp handle_nested(value) do
    (case value do
      {:some, value} ->
        (case value do
          {:ok, value} ->
            n = value
            "Got number: #{Kernel.to_string(n)}"
          {:error, e} -> "Got error: #{e}"
        end)
      {:none} -> "Got nothing"
    end)
  end
end
