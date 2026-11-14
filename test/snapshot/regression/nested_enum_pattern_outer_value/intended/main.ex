defmodule Main do
  def main() do

  end
  def admit(expected, actual) do
    if (expected == "" or actual == "") do
      {:err, {:malformed, "digest"}}
    else
      if (expected == actual), do: {:ok, 1}, else: {:err, {:stale, expected, actual}}
    end
  end
  def refuses_stale(expected, actual) do
    (case admit(expected, actual) do
      {:err, value} ->
        (case value do
          {:stale, wanted, _} -> wanted == expected
          _ -> false
        end)
      _ -> false
    end)
  end
end
