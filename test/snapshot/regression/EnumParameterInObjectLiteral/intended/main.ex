defmodule Main do
  def main() do
    bulk_action = {:some, {:set_priority, "high"}}
    _result = (case parse_action(bulk_action) do
      {:some, _msg} -> nil
      {:none} -> nil
    end)
    simple_action = {:some, {:complete_all}}
    _result_value = parse_action(simple_action)
    nil
  end
  defp parse_action(opt_action) do
    (case opt_action do
      {:some, action} ->
        (case action do
          {:complete_all} -> {:some, {:bulk_update, {:complete_all}}}
          {:delete_completed} -> {:some, {:bulk_update, {:delete_completed}}}
          {:set_priority, priority} -> {:some, {:bulk_update, {:set_priority, priority}}}
        end)
      {:none} -> {:none}
    end)
  end
end
