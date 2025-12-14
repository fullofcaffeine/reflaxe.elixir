defmodule Main do
  def main() do
    result = (case MyApp.TestPubSub.subscribe("notifications") do
      {:ok, value} ->
        _fn_ = value
        _end_ = value
        _fn = value
        _end = value
        "Success: #{(fn -> value end).()}"
      {:error, reason} -> "Failed: #{(fn -> reason end).()}"
    end)
    nil
  end
end
