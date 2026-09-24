defmodule Main do
  def main() do
    _description = (case {:ok, 42} do
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
