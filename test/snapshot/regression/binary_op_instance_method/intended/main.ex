defmodule Main do
  def main() do
    calc = Calculator.new(10)
    _ = Calculator.add(calc, 5)
    _ = Calculator.multiply(calc, 3)
    _ = Calculator.concatenate(calc, "test")
    nil
  end
end
