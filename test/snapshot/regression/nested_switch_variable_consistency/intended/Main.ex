defmodule Main do
  defp parse_message(msg) do
    case (msg) do
      "alert" ->
        {:some, {:system_alert, "Warning"}}
      "create" ->
        {:some, {:todo_created, %{:id => 1, :title => "Test"}}}
      "delete" ->
        {:some, {:todo_deleted, 1}}
      "update" ->
        {:some, {:todo_updated, %{:id => 1, :title => "Updated"}}}
      _ ->
        {:none}
    end
  end
  def main() do
    msg = "create"
    g = parse_message(msg)
    case (g) do
      {:some, value} ->
        g = g
        parsed_msg = g
        case (parsed_msg) do
          {:todo_created, todo} ->
            g = elem(parsed_msg, 1)
            todo = g
            Log.trace("Todo created: " <> Std.string(todo.title), %{:file_name => "Main.hx", :line_number => 51, :class_name => "Main", :method_name => "main"})
          {:todo_updated, todo} ->
            g = elem(parsed_msg, 1)
            todo = g
            Log.trace("Todo updated: " <> Std.string(todo.title), %{:file_name => "Main.hx", :line_number => 53, :class_name => "Main", :method_name => "main"})
          {:todo_deleted, id} ->
            g = elem(parsed_msg, 1)
            id = g
            Log.trace("Todo deleted: " <> Kernel.to_string(id), %{:file_name => "Main.hx", :line_number => 55, :class_name => "Main", :method_name => "main"})
          {:system_alert, message} ->
            g = elem(parsed_msg, 1)
            message = g
            Log.trace("Alert: " <> message, %{:file_name => "Main.hx", :line_number => 57, :class_name => "Main", :method_name => "main"})
        end
      {:none} ->
        Log.trace("No message parsed", %{:file_name => "Main.hx", :line_number => 60, :class_name => "Main", :method_name => "main"})
    end
  end
end