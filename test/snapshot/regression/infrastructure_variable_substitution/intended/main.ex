defmodule Main do
  def main() do
    _result = (case TestPubSub.subscribe("notifications") do
      {:ok, value} -> "Success: #{value}"
      {:error, reason} -> "Failed: #{reason}"
    end)
    nil
  end
end
