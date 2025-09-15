defmodule Main do
  def main() do
    Log.trace("Testing abstract types...", %{:file_name => "Main.hx", :line_number => 62, :class_name => "Main", :method_name => "main"})
    user1 = UserId.new(100)
    user2 = UserId.new(200)
    combined = UserId.add(user1, user2)
    is_greater = UserId.greater(user2, user1)
    Log.trace("User1: " <> UserId.to_string(user1), %{:file_name => "Main.hx", :line_number => 70, :class_name => "Main", :method_name => "main"})
    Log.trace("User2: " <> UserId.to_string(user2), %{:file_name => "Main.hx", :line_number => 71, :class_name => "Main", :method_name => "main"})
    Log.trace("Combined: " <> UserId.to_string(combined), %{:file_name => "Main.hx", :line_number => 72, :class_name => "Main", :method_name => "main"})
    Log.trace("User2 > User1: " <> Std.string(is_greater), %{:file_name => "Main.hx", :line_number => 73, :class_name => "Main", :method_name => "main"})
    price1 = Money.new(1050)
    price2 = Money.new(750)
    total = Money.add(price1, price2)
    discount = Money.subtract(price1, Money.new(150))
    doubled = Money.multiply(price1, 2)
    is_equal = Money.equal(price1, price2)
    Log.trace("Price1: $" <> Kernel.to_string(Money.to_dollars(price1)), %{:file_name => "Main.hx", :line_number => 83, :class_name => "Main", :method_name => "main"})
    Log.trace("Price2: $" <> Kernel.to_string(Money.to_dollars(price2)), %{:file_name => "Main.hx", :line_number => 84, :class_name => "Main", :method_name => "main"})
    Log.trace("Total: $" <> Kernel.to_string(Money.to_dollars(total)), %{:file_name => "Main.hx", :line_number => 85, :class_name => "Main", :method_name => "main"})
    Log.trace("Discounted: $" <> Kernel.to_string(Money.to_dollars(discount)), %{:file_name => "Main.hx", :line_number => 86, :class_name => "Main", :method_name => "main"})
    Log.trace("Doubled: $" <> Kernel.to_string(Money.to_dollars(doubled)), %{:file_name => "Main.hx", :line_number => 87, :class_name => "Main", :method_name => "main"})
    Log.trace("Equal: " <> Std.string(is_equal), %{:file_name => "Main.hx", :line_number => 88, :class_name => "Main", :method_name => "main"})
    user_from_int = 42
    int_from_user = user_from_int
    Log.trace("From int: " <> UserId.to_string(user_from_int), %{:file_name => "Main.hx", :line_number => 93, :class_name => "Main", :method_name => "main"})
    Log.trace("To int: " <> Kernel.to_string(int_from_user), %{:file_name => "Main.hx", :line_number => 94, :class_name => "Main", :method_name => "main"})
    money_from_int = 500
    Log.trace("Money from int: $" <> Kernel.to_string(Money.to_dollars(money_from_int)), %{:file_name => "Main.hx", :line_number => 97, :class_name => "Main", :method_name => "main"})
  end
end