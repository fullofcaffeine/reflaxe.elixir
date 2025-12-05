defmodule Main do
  def main() do
    result = (case MyApp.TestPubSub.subscribe("notifications") do
      {:ok, value} ->
        end_ = value
        fn_ = value
        end_ = value
        fn_ = value
        "Success: #{(fn -> value end).()}"
      {:error, value} ->
        reason = value
        fn_ = value
        reason = value
        "Failed: #{(fn -> reason end).()}"
    end)
    nil
  end
end
