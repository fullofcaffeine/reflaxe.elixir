defmodule Main do
  def main() do
    result = to_int({:custom, 418})
    Log.trace(result, %{:file_name => "Main.hx", :line_number => 12, :class_name => "Main", :method_name => "main"})
  end
  def to_int(status) do
    __elixir_switch_result_1 = case (status) do
      :ok ->
        200
      {:error, _msg} ->
        500
      {:custom, code} ->
        code
    end
    __elixir_switch_result_1
  end
end