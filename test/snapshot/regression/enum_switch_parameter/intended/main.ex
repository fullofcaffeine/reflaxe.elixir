defmodule Main do
  def main() do
    test_result = {:Ok, "success"}
    opt = {:ToOption, test_result}
    unwrapped = unwrap_or(test_result, "default")
    Log.trace(opt, %{:fileName => "Main.hx", :lineNumber => 26, :className => "Main", :methodName => "main"})
    Log.trace(unwrapped, %{:fileName => "Main.hx", :lineNumber => 27, :className => "Main", :methodName => "main"})
  end
  def to_option(result) do
    case (result.elem(0)) do
      0 ->
        g = result.elem(1)
        value = g
        {:Some, value}
      1 ->
        g = result.elem(1)
        :none
    end
  end
  def unwrap_or(result, default_value) do
    case (result.elem(0)) do
      0 ->
        g = result.elem(1)
        value = g
        value
      1 ->
        g = result.elem(1)
        default_value
    end
  end
end