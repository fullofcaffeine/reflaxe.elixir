defmodule Main do
  @moduledoc "Main module generated from Haxe"

  # Static functions
  @doc "Generated from Haxe parseMessage"
  def parse_message(msg) do
    temp_result = nil

    temp_result = nil

    case (msg) do
      _ -> :none
    end

    temp_result
  end

  @doc "Generated from Haxe main"
  def main() do
    msg = "create"

    g_array = Main.parse_message(msg)
    case (case g_array do :some -> 0; :none -> 1; _ -> -1 end) do
      {0, parsed_msg} -> g_array = elem(g_array, 1)
    case (case parsed_msg do :todo_created -> 0; :todo_updated -> 1; :todo_deleted -> 2; :system_alert -> 3; _ -> -1 end) do
      {0, todo} -> g_array = elem(parsed_msg, 1)
    Log.trace("Todo created: " <> Std.string(todo.title), %{"fileName" => "Main.hx", "lineNumber" => 51, "className" => "Main", "methodName" => "main"})
      {1, todo} -> g_array = elem(parsed_msg, 1)
    Log.trace("Todo updated: " <> Std.string(todo.title), %{"fileName" => "Main.hx", "lineNumber" => 53, "className" => "Main", "methodName" => "main"})
      {2, id} -> g_array = elem(parsed_msg, 1)
    Log.trace("Todo deleted: " <> to_string(id), %{"fileName" => "Main.hx", "lineNumber" => 55, "className" => "Main", "methodName" => "main"})
      {3, message} -> g_array = elem(parsed_msg, 1)
    Log.trace("Alert: " <> message, %{"fileName" => "Main.hx", "lineNumber" => 57, "className" => "Main", "methodName" => "main"})
    end
      1 -> Log.trace("No message parsed", %{"fileName" => "Main.hx", "lineNumber" => 60, "className" => "Main", "methodName" => "main"})
    end
  end

end