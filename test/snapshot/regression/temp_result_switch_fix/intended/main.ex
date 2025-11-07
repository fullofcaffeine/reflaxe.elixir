defmodule Main do
  defp topic_to_string(topic) do
    (case topic do
      {:topic_a} -> "topic_a"
      {:topic_b} -> "topic_b"
      {:topic_c} -> "topic_c"
    end)
  end
  defp get_value(input) do
    (case input do
      1 -> "one"
      2 -> "two"
      _ -> "other"
    end)
  end
  def main() do
    _ = Log.trace(topic_to_string({:topic_a}), %{:file_name => "Main.hx", :line_number => 42, :class_name => "Main", :method_name => "main"})
    _ = Log.trace(get_value(1), %{:file_name => "Main.hx", :line_number => 43, :class_name => "Main", :method_name => "main"})
  end
end
