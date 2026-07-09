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
      "bulk_update" when Msg.neq(((case msg do
      dyn_obj ->
        (case Map.fetch(dyn_obj, "action") do
          {:ok, dyn_value} -> dyn_value
          _ ->
            Map.get(dyn_obj, :action)
        end)
    end)), nil) ->
        bulk_action = parse_bulk_action(((case msg do
            dyn_obj ->
              (case Map.fetch(dyn_obj, "action") do
                {:ok, dyn_value} -> dyn_value
                _ ->
                  Map.get(dyn_obj, :action)
              end)
          end)))
        (case bulk_action do
          {:some, action} -> {:some, {:bulk_update, action}}
          {:none} -> {:none}
        end)
      "bulk_update" -> {:none}
      "system_alert" when Msg.neq(((case msg do
      dyn_obj ->
        (case Map.fetch(dyn_obj, "message") do
          {:ok, dyn_value} -> dyn_value
          _ ->
            Map.get(dyn_obj, :message)
        end)
    end)), nil) and Msg.neq(((case msg do
      dyn_obj ->
        (case Map.fetch(dyn_obj, "level") do
          {:ok, dyn_value} -> dyn_value
          _ ->
            Map.get(dyn_obj, :level)
        end)
    end)), nil) ->
        alert_level = parse_alert_level(((case msg do
            dyn_obj ->
              (case Map.fetch(dyn_obj, "level") do
                {:ok, dyn_value} -> dyn_value
                _ ->
                  Map.get(dyn_obj, :level)
              end)
          end)))
        (case alert_level do
          {:some, level} ->
            {:some, {:system_alert, (case msg do
              dyn_obj ->
                (case Map.fetch(dyn_obj, "message") do
                  {:ok, dyn_value} -> dyn_value
                  _ ->
                    Map.get(dyn_obj, :message)
                end)
            end), level}}
          {:none} -> {:none}
        end)
      "system_alert" -> {:none}
      _ -> {:none}
    end)
  end
  def main() do
    msg1 = %{action: "complete_all", message: nil, level: nil}
    _ = parse_message("bulk_update", msg1)
    msg2 = %{action: nil, message: "System maintenance", level: "info"}
    _ = parse_message("system_alert", msg2)
    msg3 = %{action: nil, message: nil, level: nil}
    _ = parse_message("unknown", msg3)
    nil
  end
end
