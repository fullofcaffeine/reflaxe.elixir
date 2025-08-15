defmodule Main do
  use Bitwise
  @moduledoc """
  Main module generated from Haxe
  """

  # Static functions
  @doc "Function calculate_discount"
  @spec calculate_discount(float(), float()) :: float()
  def calculate_discount(original_price, discount_percent) do
    original_price * (1.0 - discount_percent / 100.0)
  end

  # Instance functions
  @doc "Function greet_user"
  @spec greet_user(String.t(), String.t()) :: String.t()
  def greet_user(user_name, message) do
    "Hello " <> user_name <> ": " <> message
  end

  @doc "Function process_order"
  @spec process_order(integer(), String.t(), float()) :: boolean()
  def process_order(order_id, customer_email, amount) do
    order_id > 0 && String.length(customer_email) > 0 && amount > 0.0
  end

  @doc "Function validate_email"
  @spec validate_email(String.t()) :: boolean()
  def validate_email(email_address) do
    case :binary.match(email_address, "@") do {pos, _} -> pos; :nomatch -> -1 end > 0
  end

end
