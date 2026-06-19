defmodule Main do
  def main() do
    name = "World"
    age = 25
    _greeting = "Hello #{name}!"
    _info = "Name: #{name}, Age: #{Reflaxe.Elixir.HaxeFloat.to_string(age)}"
    _result = "Result: #{Reflaxe.Elixir.HaxeFloat.to_string(15)} points"
    nil
  end
end
