defmodule Main do
  defp parse_bulk_action(action) do
    (case action do
      "complete_all" -> {:some, {:complete_all}}
      "delete_completed" -> {:some, {:delete_completed}}
      "set_priority" -> {:some, {:set_priority, "high"}}
      _ -> {:none}
    end)
  end
  defp parse_alert_level(level) do
    (case level do
      "critical" -> {:some, level}
      "error" -> {:some, level}
      "info" -> {:some, level}
      "warning" -> {:some, level}
      _ -> {:none}
    end)
  end
  defp parse_message(type, msg) do
    (case type do
      "bulk_update" when Kernel.is_map_key(msg, :action) ->
        bulk_action = parse_bulk_action(Map.get(msg, :action))
        (case bulk_action do
          {:some, action} -> {:some, {:bulk_update, action}}
          {:none} -> {:none}
        end)
      "bulk_update" -> {:none}
      "system_alert" when Kernel.is_map_key(msg, :message) and Kernel.is_map_key(msg, :level) ->
        alert_level = parse_alert_level(Map.get(msg, :level))
        (case alert_level do
          {:some, level} -> {:some, {:system_alert, Map.get(msg, :message), level}}
          {:none} -> {:none}
        end)
      "system_alert" -> {:none}
      _ -> {:none}
    end)
  end
  def main() do
    msg1 = %{:action => "complete_all", :message => nil, :level => nil}
    _ = parse_message("bulk_update", msg1)
    msg2 = %{:action => nil, :message => "System maintenance", :level => "info"}
    _ = parse_message("system_alert", msg2)
    msg3 = %{:action => nil, :message => nil, :level => nil}
    _ = parse_message("unknown", msg3)
    nil
  end
end
