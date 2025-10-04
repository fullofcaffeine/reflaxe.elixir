defmodule Main do
  def main() do
    result = case TestPubSub.subscribe("notifications") do
      {:ok, value} ->
        "Success: #{value}"
      {:error, reason} ->
        "Failed: #{reason}"
    end
    Log.trace(result, %{:file_name => "Main.hx", :line_number => 38, :class_name => "Main", :method_name => "main"})
  end
end