defmodule Main do
  @moduledoc "Main module generated from Haxe"

  # Static functions
  @doc "Generated from Haxe main"
  def main() do
    Log.trace("Testing abstract types...", %{"fileName" => "Main.hx", "lineNumber" => 62, "className" => "Main", "methodName" => "main"})

    user1 = UserId_Impl_.new(100)

    user2 = UserId_Impl_.new(200)

    combined = UserId_Impl_.add(user1, user2)

    is_greater = UserId_Impl_.greater(user2, user1)

    Log.trace("User1: " <> UserId_Impl_.to_string(user1), %{"fileName" => "Main.hx", "lineNumber" => 70, "className" => "Main", "methodName" => "main"})

    Log.trace("User2: " <> UserId_Impl_.to_string(user2), %{"fileName" => "Main.hx", "lineNumber" => 71, "className" => "Main", "methodName" => "main"})

    Log.trace("Combined: " <> UserId_Impl_.to_string(combined), %{"fileName" => "Main.hx", "lineNumber" => 72, "className" => "Main", "methodName" => "main"})

    Log.trace("User2 > User1: " <> Std.string(is_greater), %{"fileName" => "Main.hx", "lineNumber" => 73, "className" => "Main", "methodName" => "main"})

    price1 = Money_Impl_.new(1050)

    price2 = Money_Impl_.new(750)

    total = Money_Impl_.add(price1, price2)

    discount = Money_Impl_.subtract(price1, Money_Impl_.new(150))

    doubled = Money_Impl_.multiply(price1, 2)

    is_equal = Money_Impl_.equal(price1, price2)

    Log.trace("Price1: $" <> to_string(Money_Impl_.to_dollars(price1)), %{"fileName" => "Main.hx", "lineNumber" => 83, "className" => "Main", "methodName" => "main"})

    Log.trace("Price2: $" <> to_string(Money_Impl_.to_dollars(price2)), %{"fileName" => "Main.hx", "lineNumber" => 84, "className" => "Main", "methodName" => "main"})

    Log.trace("Total: $" <> to_string(Money_Impl_.to_dollars(total)), %{"fileName" => "Main.hx", "lineNumber" => 85, "className" => "Main", "methodName" => "main"})

    Log.trace("Discounted: $" <> to_string(Money_Impl_.to_dollars(discount)), %{"fileName" => "Main.hx", "lineNumber" => 86, "className" => "Main", "methodName" => "main"})

    Log.trace("Doubled: $" <> to_string(Money_Impl_.to_dollars(doubled)), %{"fileName" => "Main.hx", "lineNumber" => 87, "className" => "Main", "methodName" => "main"})

    Log.trace("Equal: " <> Std.string(is_equal), %{"fileName" => "Main.hx", "lineNumber" => 88, "className" => "Main", "methodName" => "main"})

    user_from_int = 42

    int_from_user = user_from_int

    Log.trace("From int: " <> UserId_Impl_.to_string(user_from_int), %{"fileName" => "Main.hx", "lineNumber" => 93, "className" => "Main", "methodName" => "main"})

    Log.trace("To int: " <> to_string(int_from_user), %{"fileName" => "Main.hx", "lineNumber" => 94, "className" => "Main", "methodName" => "main"})

    money_from_int = 500

    Log.trace("Money from int: $" <> to_string(Money_Impl_.to_dollars(money_from_int)), %{"fileName" => "Main.hx", "lineNumber" => 97, "className" => "Main", "methodName" => "main"})
  end

end
