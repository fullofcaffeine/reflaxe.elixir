defmodule Main do
  def main() do
    result = {:ok, "success"}
    _message = (case result do
      {:ok, value} -> "Success: #{value}"
      {:error, error} -> "Error: #{error}"
    end)
    nil
  end
end
