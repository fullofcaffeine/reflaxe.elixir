defmodule Main do
  defp main() do
    Log.trace("Testing abstract types...", %{:fileName => "Main.hx", :lineNumber => 62, :className => "Main", :methodName => "main"})
    user_1 = UserId_Impl_._new(100)
    user_2 = UserId_Impl_._new(200)
    combined = UserId_Impl_.add(user, user)
    is_greater = UserId_Impl_.greater(user, user)
    Log.trace("User1: " + UserId_Impl_.to_string(user), %{:fileName => "Main.hx", :lineNumber => 70, :className => "Main", :methodName => "main"})
    Log.trace("User2: " + UserId_Impl_.to_string(user), %{:fileName => "Main.hx", :lineNumber => 71, :className => "Main", :methodName => "main"})
    Log.trace("Combined: " + UserId_Impl_.to_string(combined), %{:fileName => "Main.hx", :lineNumber => 72, :className => "Main", :methodName => "main"})
    Log.trace("User2 > User1: " + Std.string(is_greater), %{:fileName => "Main.hx", :lineNumber => 73, :className => "Main", :methodName => "main"})
    price_1 = Money_Impl_._new(1050)
    price_2 = Money_Impl_._new(750)
    total = Money_Impl_.add(price, price)
    discount = Money_Impl_.subtract(price, Money_Impl_._new(150))
    doubled = Money_Impl_.multiply(price, 2)
    is_equal = Money_Impl_.equal(price, price)
    Log.trace("Price1: $" + Money_Impl_.to_dollars(price), %{:fileName => "Main.hx", :lineNumber => 83, :className => "Main", :methodName => "main"})
    Log.trace("Price2: $" + Money_Impl_.to_dollars(price), %{:fileName => "Main.hx", :lineNumber => 84, :className => "Main", :methodName => "main"})
    Log.trace("Total: $" + Money_Impl_.to_dollars(total), %{:fileName => "Main.hx", :lineNumber => 85, :className => "Main", :methodName => "main"})
    Log.trace("Discounted: $" + Money_Impl_.to_dollars(discount), %{:fileName => "Main.hx", :lineNumber => 86, :className => "Main", :methodName => "main"})
    Log.trace("Doubled: $" + Money_Impl_.to_dollars(doubled), %{:fileName => "Main.hx", :lineNumber => 87, :className => "Main", :methodName => "main"})
    Log.trace("Equal: " + Std.string(is_equal), %{:fileName => "Main.hx", :lineNumber => 88, :className => "Main", :methodName => "main"})
    user_from_int = 42
    int_from_user = user_from_int
    Log.trace("From int: " + UserId_Impl_.to_string(user_from_int), %{:fileName => "Main.hx", :lineNumber => 93, :className => "Main", :methodName => "main"})
    Log.trace("To int: " + int_from_user, %{:fileName => "Main.hx", :lineNumber => 94, :className => "Main", :methodName => "main"})
    money_from_int = 500
    Log.trace("Money from int: $" + Money_Impl_.to_dollars(money_from_int), %{:fileName => "Main.hx", :lineNumber => 97, :className => "Main", :methodName => "main"})
  end
end