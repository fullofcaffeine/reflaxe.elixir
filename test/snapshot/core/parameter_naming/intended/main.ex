defmodule Main do
  def new() do
    %{}
  end
  def greet_user(_, user_name, message) do
    "Hello #{user_name}: #{message}"
  end
  def process_order(_, order_id, customer_email, amount) do
    order_id > 0 and String.length(customer_email) > 0 and amount > 0
  end
  def validate_email(_, email_address) do
    ((case :binary.match(email_address, "@") do
  {pos, _} -> pos
  :nomatch -> -1
end)) > 0
  end
  def calculate_discount(original_price, discount_percent) do
    original_price * ((1 - discount_percent / 100))
  end
end
