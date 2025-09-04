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
        :none
    end
  end
  def main() do
    msg = "create"
    g = {:ParseMessage, msg}
    case (g.elem(0)) do
      0 ->
        g = g.elem(1)
        parsed_msg = g
        case (parsed_msg.elem(0)) do
          0 ->
            g = parsed_msg.elem(1)
            todo = g
            Log.trace("Todo created: " <> Std.string(todo.title), %{:fileName => "Main.hx", :lineNumber => 51, :className => "Main", :methodName => "main"})
          1 ->
            g = parsed_msg.elem(1)
            todo = g
            Log.trace("Todo updated: " <> Std.string(todo.title), %{:fileName => "Main.hx", :lineNumber => 53, :className => "Main", :methodName => "main"})
          2 ->
            g = parsed_msg.elem(1)
            id = g
            Log.trace("Todo deleted: " <> id, %{:fileName => "Main.hx", :lineNumber => 55, :className => "Main", :methodName => "main"})
          3 ->
            g = parsed_msg.elem(1)
            message = g
            Log.trace("Alert: " <> message, %{:fileName => "Main.hx", :lineNumber => 57, :className => "Main", :methodName => "main"})
        end
      1 ->
        Log.trace("No message parsed", %{:fileName => "Main.hx", :lineNumber => 60, :className => "Main", :methodName => "main"})
    end
  end
end