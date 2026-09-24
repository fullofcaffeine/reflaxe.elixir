defmodule Main do
  def main() do
    _message = (case {:ok, "success"} do
      {:ok, value} -> "Success: #{value}"
      {:error, error} -> "Error: #{error}"
    end)
    nil
  end
end
