defmodule Main do
  def main() do
    name = "World"
    _greeting = "Hello #{name}!"
    first_name = "John"
    last_name = "Doe"
    _full_name = "#{first_name} #{last_name}"
    age = 25
    _message = "Age: #{Reflaxe.Elixir.HaxeFloat.to_string(age)}"
    user = "Alice"
    score = 100
    level = "Advanced"
    _status = "User #{user} has score #{Reflaxe.Elixir.HaxeFloat.to_string(score)} at level #{level}"
    _result = "Result: #{Reflaxe.Elixir.HaxeFloat.to_string(30)}"
    nil
  end
end
