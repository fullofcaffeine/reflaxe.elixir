defmodule Main do
  defp broadcast(_todo) do

  end
  defp process(res) do
    (case res do
      {:ok, updated_todo} ->
        _ = broadcast(updated_todo)
        "ok"
      {:error, reason} -> reason
    end)
  end
  def main() do
    todo = %{:id => 1, :text => "x"}
    r = {:ok, todo}
    _ = process(r)
  end
end
