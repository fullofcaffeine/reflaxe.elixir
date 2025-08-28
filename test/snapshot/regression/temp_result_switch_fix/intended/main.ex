defmodule Main do
  @moduledoc "Main module generated from Haxe"

  # Static functions
  @doc "Generated from Haxe topicToString"
  def topic_to_string(topic) do
    temp_result = nil

    temp_result = nil

    case (case topic do :topic_a -> 0; :topic_b -> 1; :topic_c -> 2; _ -> -1 end) do
      0 -> "topic_a"
      1 -> "topic_b"
      2 -> "topic_c"
    end

    temp_result
  end

  @doc "Generated from Haxe getValue"
  def get_value(input) do
    temp_string = nil

    temp_string = nil

    case (input) do
      _ ->
        "one"
      _ ->
        "two"
      _ -> "other"
    end

    temp_string
  end

  @doc "Generated from Haxe main"
  def main() do
    Log.trace(Main.topic_to_string(:topic_a), %{"fileName" => "Main.hx", "lineNumber" => 42, "className" => "Main", "methodName" => "main"})

    Log.trace(Main.get_value(1), %{"fileName" => "Main.hx", "lineNumber" => 43, "className" => "Main", "methodName" => "main"})
  end

end
