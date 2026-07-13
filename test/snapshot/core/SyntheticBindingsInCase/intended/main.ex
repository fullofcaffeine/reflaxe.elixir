defmodule Main do
  defp process_result(result) do
    (case result do
      {:ok, value} -> value
      {:error, error} ->
        message = "Error occurred: #{error}"
        IO.puts(message)
        "failed"
    end)
  end
  def main() do
    process_result({:ok, "success"})
    process_result({:error, "something went wrong"})
  end
end
