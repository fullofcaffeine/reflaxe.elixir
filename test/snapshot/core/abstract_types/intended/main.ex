defmodule Main do
  def main() do
    user1 = UserId_Impl_._new(100)
    user2 = UserId_Impl_._new(200)
    _combined = UserId_Impl_.add(user1, user2)
    _is_greater = UserId_Impl_.greater(user2, user1)
    price1 = Money_Impl_._new(1050)
    price2 = Money_Impl_._new(750)
    _total = Money_Impl_.add(price1, price2)
    _discount = Money_Impl_.subtract(price1, Money_Impl_._new(150))
    _doubled = Money_Impl_.multiply(price1, 2)
    _is_equal = Money_Impl_.equal(price1, price2)
    user_from_int = 42
    _int_from_user = user_from_int
    nil
  end
end
