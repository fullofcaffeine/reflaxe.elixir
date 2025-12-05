defmodule Main do
  defp parse_message(msg) do
    (case msg do
      "alert" -> {:some, {:system_alert, "Warning"}}
      "create" -> {:some, {:todo_created, %{:id => 1, :title => "Test"}}}
      "delete" -> {:some, {:todo_deleted, 1}}
      "update" -> {:some, {:todo_updated, %{:id => 1, :title => "Updated"}}}
      _ -> {:none}
    end)
  end
  def main() do
    msg = "create"
    (case parse_message(msg) do
      {:some, parsed_msg} ->
        (case parsed_msg do
          {:todo_created, __todo} -> nil
          {:todo_updated, __todo} -> nil
          {:todo_deleted, __id} -> nil
          {:system_alert, __message} -> nil
        end)
      {:none} -> nil
    end)
  end
end
