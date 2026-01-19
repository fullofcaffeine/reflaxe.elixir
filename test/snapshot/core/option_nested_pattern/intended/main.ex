defmodule Main do
  def eval(opt) do
    (case opt do
      {:some, v} ->
        (case v do
          {:a, n} -> n + 1
          {:b} -> 0
        end)
      {:none} -> -1
    end)
  end
  def main() do
    
  end
end
