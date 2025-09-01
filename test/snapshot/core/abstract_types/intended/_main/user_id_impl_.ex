defmodule UserId_Impl_ do
  def _new(id) do
    this_1 = nil
    this_1 = id
    this_1
  end
  def add(a, b) do
    UserId_Impl_._new(UserId_Impl_.to_int(a) + UserId_Impl_.to_int(b))
  end
  def greater(a, b) do
    UserId_Impl_.to_int(a) > UserId_Impl_.to_int(b)
  end
  def to_int(this1) do
    this1
  end
  def to_string(this1) do
    "UserId(" + this1 + ")"
  end
end