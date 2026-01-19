defmodule Main do
  def main() do
    result = {:ok, 42}
    _description = (case result do
      {:ok, value} ->
        n = value
        if (n > 0) do
          "positive"
        else
          n = value
          if (n < 0), do: "negative", else: "zero"
        end
      {:error, msg} -> "error: #{msg}"
    end)
    nil
  end
end
