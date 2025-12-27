defmodule Main do
  def greet_user(struct, user_name, message) do
    "Hello #{(fn -> user_name end).()}: #{(fn -> message end).()}"
  end
  def process_order(struct, order_id, customer_email, amount) do
    order_id > 0 and String.length(customer_email) > 0 and amount > 0
  end
  def validate_email(struct, email_address) do
    ((case :binary.match(email_address, "@") do
  {pos, _} -> pos
  :nomatch -> -1
end)) > 0
  end
  def calculate_discount(original_price, discount_percent) do
    original_price * ((1 - discount_percent / 100))
  end
end
