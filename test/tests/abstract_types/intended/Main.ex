defmodule Main do
  use Bitwise
  @moduledoc """
  Main module generated from Haxe
  """

  # Static functions
  @doc "Function main"
  @spec main() :: nil
  def main() do
    Log.trace("Testing abstract types...", %{fileName => "Main.hx", lineNumber => 62, className => "Main", methodName => "main"})
    user1 = UserId_Impl_._new(100)
    user2 = UserId_Impl_._new(200)
    combined = UserId_Impl_.add(user1, user2)
    is_greater = UserId_Impl_.greater(user2, user1)
    Log.trace("User1: " <> UserId_Impl_.toString(user1), %{fileName => "Main.hx", lineNumber => 70, className => "Main", methodName => "main"})
    Log.trace("User2: " <> UserId_Impl_.toString(user2), %{fileName => "Main.hx", lineNumber => 71, className => "Main", methodName => "main"})
    Log.trace("Combined: " <> UserId_Impl_.toString(combined), %{fileName => "Main.hx", lineNumber => 72, className => "Main", methodName => "main"})
    Log.trace("User2 > User1: " <> Std.string(is_greater), %{fileName => "Main.hx", lineNumber => 73, className => "Main", methodName => "main"})
    price1 = Money_Impl_._new(1050)
    price2 = Money_Impl_._new(750)
    total = Money_Impl_.add(price1, price2)
    discount = Money_Impl_.subtract(price1, Money_Impl_._new(150))
    doubled = Money_Impl_.multiply(price1, 2)
    is_equal = Money_Impl_.equal(price1, price2)
    Log.trace("Price1: $" <> Float.to_string(Money_Impl_.toDollars(price1)), %{fileName => "Main.hx", lineNumber => 83, className => "Main", methodName => "main"})
    Log.trace("Price2: $" <> Float.to_string(Money_Impl_.toDollars(price2)), %{fileName => "Main.hx", lineNumber => 84, className => "Main", methodName => "main"})
    Log.trace("Total: $" <> Float.to_string(Money_Impl_.toDollars(total)), %{fileName => "Main.hx", lineNumber => 85, className => "Main", methodName => "main"})
    Log.trace("Discounted: $" <> Float.to_string(Money_Impl_.toDollars(discount)), %{fileName => "Main.hx", lineNumber => 86, className => "Main", methodName => "main"})
    Log.trace("Doubled: $" <> Float.to_string(Money_Impl_.toDollars(doubled)), %{fileName => "Main.hx", lineNumber => 87, className => "Main", methodName => "main"})
    Log.trace("Equal: " <> Std.string(is_equal), %{fileName => "Main.hx", lineNumber => 88, className => "Main", methodName => "main"})
    user_from_int = 42
    int_from_user = user_from_int
    Log.trace("From int: " <> UserId_Impl_.toString(user_from_int), %{fileName => "Main.hx", lineNumber => 93, className => "Main", methodName => "main"})
    Log.trace("To int: " <> Integer.to_string(int_from_user), %{fileName => "Main.hx", lineNumber => 94, className => "Main", methodName => "main"})
    money_from_int = 500
    Log.trace("Money from int: $" <> Float.to_string(Money_Impl_.toDollars(money_from_int)), %{fileName => "Main.hx", lineNumber => 97, className => "Main", methodName => "main"})
  end

end
