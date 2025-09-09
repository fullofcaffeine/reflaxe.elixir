defmodule Main do
  defp parse_message(msg) do
    case (msg) do
      "alert" ->
        {:Some, {:SystemAlert, "Warning"}}
      "create" ->
        {:Some, {:TodoCreated, %{:id => 1, :title => "Test"}}}
      "delete" ->
        {:Some, {:TodoDeleted, 1}}
      "update" ->
        {:Some, {:TodoUpdated, %{:id => 1, :title => "Updated"}}}
      _ ->
        {1}
    end
  end
  def main() do
    msg = "create"
    g = parse_message(msg)
    case (elem(g, 0)) do
      0 ->
        g = elem(g, 1)
        parsed_msg = g
        case (elem(parsed_msg, 0)) do
          0 ->
            g = elem(parsed_msg, 1)
            todo = g
            Log.trace("Todo created: " <> Std.string(todo.title), %{:file_name => "Main.hx", :line_number => 51, :class_name => "Main", :method_name => "main"})
          1 ->
            g = elem(parsed_msg, 1)
            todo = g
            Log.trace("Todo updated: " <> Std.string(todo.title), %{:file_name => "Main.hx", :line_number => 53, :class_name => "Main", :method_name => "main"})
          2 ->
            g = elem(parsed_msg, 1)
            id = g
            Log.trace("Todo deleted: " <> Kernel.to_string(id), %{:file_name => "Main.hx", :line_number => 55, :class_name => "Main", :method_name => "main"})
          3 ->
            g = elem(parsed_msg, 1)
            message = g
            Log.trace("Alert: " <> message, %{:file_name => "Main.hx", :line_number => 57, :class_name => "Main", :method_name => "main"})
        end
      1 ->
        Log.trace("No message parsed", %{:file_name => "Main.hx", :line_number => 60, :class_name => "Main", :method_name => "main"})
    end
  end
end