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
        message = parsed_msg
        todo = parsed_msg
        (case parsed_msg do
          {:todo_created, todo} ->
            title = todo
            Log.trace("Todo created: #{(fn -> todo.title end).()}", %{:file_name => "Main.hx", :line_number => 51, :class_name => "Main", :method_name => "main"})
          {:todo_updated, todo} ->
            title = todo
            Log.trace("Todo updated: #{(fn -> todo.title end).()}", %{:file_name => "Main.hx", :line_number => 53, :class_name => "Main", :method_name => "main"})
          {:todo_deleted, id} ->
            Log.trace("Todo deleted: #{(fn -> id end).()}", %{:file_name => "Main.hx", :line_number => 55, :class_name => "Main", :method_name => "main"})
          {:system_alert, message} ->
            Log.trace("Alert: #{(fn -> message end).()}", %{:file_name => "Main.hx", :line_number => 57, :class_name => "Main", :method_name => "main"})
        end)
      {:none} ->
        Log.trace("No message parsed", %{:file_name => "Main.hx", :line_number => 60, :class_name => "Main", :method_name => "main"})
    end)
  end
end
