defmodule Main do
  defp topic_to_string(topic) do
    case (topic.elem(0)) do
      0 ->
        "topic_a"
      1 ->
        "topic_b"
      2 ->
        "topic_c"
    end
  end
  defp get_value(input) do
    result = case (input) do
  1 ->
    "one"
  2 ->
    "two"
  _ ->
    "other"
end
    result
  end
  def main() do
    Log.trace(topic_to_string(:topic_a), %{:fileName => "Main.hx", :lineNumber => 42, :className => "Main", :methodName => "main"})
    Log.trace(get_value(1), %{:fileName => "Main.hx", :lineNumber => 43, :className => "Main", :methodName => "main"})
  end
end