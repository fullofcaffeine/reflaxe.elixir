defmodule Main do
  @moduledoc """
  Main module generated from Haxe
  
  
 * Example Haxe class that demonstrates basic Elixir compilation
 
  """

  # Static functions
  @doc "
     * Entry point - this will be compiled to an Elixir module
     "
  @spec main() :: TAbstract(Void,[]).t()
  def main() do
    (
  Log.trace("Hello from Haxe compiled to Elixir!", %{fileName: "src_haxe/Main.hx", lineNumber: 9, className: "Main", methodName: "main"})
  numbers = [1, 2, 3, 4, 5]
  sum = Main.calculate_sum(numbers)
  Log.trace("Sum of " + Std.string(numbers) + " = " + sum, %{fileName: "src_haxe/Main.hx", lineNumber: 15, className: "Main", methodName: "main"})
  message = "Reflaxe.Elixir"
  processed = Main.process_message(message)
  Log.trace("Processed: " + processed, %{fileName: "src_haxe/Main.hx", lineNumber: 20, className: "Main", methodName: "main"})
)
  end

  @doc "
     * Calculate sum of an array
     "
  @spec calculate_sum(TInst(Array,[TAbstract(Int,[])]).t()) :: TAbstract(Int,[]).t()
  def calculate_sum(arg0) do
    (
  total = 0
  (
  _g = 0
  while (_g < numbers.length) do
  (
  num = Enum.at(numbers, _g)
  _g + 1
  total += num
)
end
)
  total
)
  end

  @doc "
     * Process a message string
     "
  @spec process_message(TInst(String,[]).t()) :: TInst(String,[]).t()
  def process_message(arg0) do
    message.to_lower_case() + " is awesome!"
  end

end
