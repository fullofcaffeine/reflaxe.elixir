defmodule Main do
  @moduledoc """
    Main struct generated from Haxe

    This module defines a struct with typed fields and constructor functions.
  """

  # Static functions
  @doc "Generated from Haxe calculateDiscount"
  def calculate_discount(original_price, discount_percent) do
    (original_price * ((1.0 - (discount_percent / 100.0))))
  end

  # Instance functions
  @doc "Generated from Haxe greetUser"
  def greet_user(%__MODULE__{} = struct, user_name, message) do
    "Hello " <> user_name <> ": " <> message
  end

  @doc "Generated from Haxe processOrder"
  def process_order(%__MODULE__{} = struct, order_id, customer_email, amount) do
    (((order_id > 0) && (customer_email.length > 0)) && (amount > 0.0))
  end

  @doc "Generated from Haxe validateEmail"
  def validate_email(%__MODULE__{} = struct, email_address) do
    (email_address.index_of("@") > 0)
  end

end
