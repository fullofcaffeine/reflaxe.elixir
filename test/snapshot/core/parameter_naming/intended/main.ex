defmodule Main do
  def greet_user(_struct, user_name, message) do
    "Hello #{user_name}: #{message}"
  end
  def process_order(_struct, order_id, customer_email, amount) do
    order_id > 0 and length(customer_email) > 0 and amount > 0
  end
  def validate_email(_struct, email_address) do
    (case :binary.match(email_address, "@") do
                {pos, _} -> pos
                nil -> -1
            end) > 0
  end
  def calculate_discount(original_price, discount_percent) do
    original_price * (1 - discount_percent / 100)
  end
end