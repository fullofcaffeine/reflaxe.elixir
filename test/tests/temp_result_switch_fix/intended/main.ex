defmodule Main do
  @moduledoc "Main module generated from Haxe"

  # Static functions
  @doc """
    This function should generate clean case expression without temp_result wrapper
    or if temp_result is used, the branches should assign to it
  """
  @spec topic_to_string(TestTopic.t()) :: String.t()
  def topic_to_string(topic) do
    case (case topic do :topic_a -> 0; :topic_b -> 1; :topic_c -> 2; _ -> -1 end) do
      0 -> "topic_a"
      1 -> "topic_b"
      2 -> "topic_c"
    end
  end

  @doc """
    Another test - switch in expression context (should be optimized)

  """
  @spec get_value(integer()) :: String.t()
  def get_value(input) do
    case input do
      1 -> "one"
      2 -> "two"
      _ -> "other"
    end
  end

  @doc "Function main"
  @spec main() :: nil
  def main() do
    (
          Log.trace(Main.topic_to_string(:topic_a), %{"fileName" => "Main.hx", "lineNumber" => 42, "className" => "Main", "methodName" => "main"})
          Log.trace(Main.get_value(1), %{"fileName" => "Main.hx", "lineNumber" => 43, "className" => "Main", "methodName" => "main"})
        )
  end

end
