defmodule Main do
  def main() do
    _result = (case TestPubSub.subscribe("notifications") do
      {:ok, value} -> "Success: #{(fn -> value end).()}"
      {:error, reason} -> "Failed: #{(fn -> reason end).()}"
    end)
    nil
  end
end
