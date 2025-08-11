defmodule Main do
  @moduledoc """
  Main module generated from Haxe
  
  
 * Basic syntax test case
 * Tests fundamental Haxe→Elixir compilation
 
  """

  # Static functions
  @doc "Function greet"
  @spec greet(TInst(String,[]).t()) :: TInst(String,[]).t()
  def greet(arg0) do
    "Hello, " + name + "!"
  end

  @doc "Function main"
  @spec main() :: TAbstract(Void,[]).t()
  def main() do
    (
  instance = # TODO: Implement expression type: TNew
  Log.trace(Main.greet("World"), %{fileName: "Main.hx", lineNumber: 76, className: "Main", methodName: "main"})
  Log.trace(instance.calculate(5, 3), %{fileName: "Main.hx", lineNumber: 77, className: "Main", methodName: "main"})
  Log.trace(instance.check_value(-5), %{fileName: "Main.hx", lineNumber: 78, className: "Main", methodName: "main"})
  Log.trace(instance.sum_range(1, 10), %{fileName: "Main.hx", lineNumber: 79, className: "Main", methodName: "main"})
  Log.trace(instance.factorial(5), %{fileName: "Main.hx", lineNumber: 80, className: "Main", methodName: "main"})
  Log.trace(instance.day_name(3), %{fileName: "Main.hx", lineNumber: 81, className: "Main", methodName: "main"})
)
  end

  # Instance functions
  @doc "Function calculate"
  @spec calculate(TAbstract(Int,[]).t(), TAbstract(Int,[]).t()) :: TAbstract(Int,[]).t()
  def calculate(arg0, arg1) do
    x + y * self().instance_var
  end

  @doc "Function check_value"
  @spec check_value(TAbstract(Int,[]).t()) :: TInst(String,[]).t()
  def check_value(arg0) do
    if (n < 0), do: "negative", else: if (n == 0), do: "zero", else: "positive"
  end

  @doc "Function sum_range"
  @spec sum_range(TAbstract(Int,[]).t(), TAbstract(Int,[]).t()) :: TAbstract(Int,[]).t()
  def sum_range(arg0, arg1) do
    (
  sum = 0
  (
  _g = start
  _g1 = end
  # TODO: Implement expression type: TWhile
)
  sum
)
  end

  @doc "Function factorial"
  @spec factorial(TAbstract(Int,[]).t()) :: TAbstract(Int,[]).t()
  def factorial(arg0) do
    (
  result = 1
  i = n
  # TODO: Implement expression type: TWhile
  result
)
  end

  @doc "Function day_name"
  @spec day_name(TAbstract(Int,[]).t()) :: TInst(String,[]).t()
  def day_name(arg0) do
    (
  temp_result = nil
  # TODO: Implement expression type: TMeta
  temp_result
)
  end

end
