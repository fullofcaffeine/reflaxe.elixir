defmodule Main do
  def new() do
    %{:__reflaxe_class__ => Main}
  end
  def greet_user(_struct, user_name, message) do
    "Hello #{user_name}: #{message}"
  end
  def process_order(_struct, order_id, customer_email, amount) do
    order_id > 0 and String.length(customer_email) > 0 and Reflaxe.Elixir.HaxeFloat.gt(amount, 0)
  end
  def validate_email(_struct, email_address) do
    (case :binary.match(email_address, "@") do
  {pos, _} -> pos
  :nomatch -> -1
end) > 0
  end
  def calculate_discount(original_price, discount_percent) do
    Reflaxe.Elixir.HaxeFloat.mul(original_price, Reflaxe.Elixir.HaxeFloat.sub(1, Reflaxe.Elixir.HaxeFloat.divide(discount_percent, 100)))
  end
end
