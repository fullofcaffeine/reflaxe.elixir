defmodule UserId_Impl_ do
  def _new(id) do
    this1 = id
    this1
  end
  def add(a, b) do
    _new(to_int(a) + to_int(b))
  end
  def greater(a, b) do
    to_int(a) > to_int(b)
  end
  def to_int(this1) do
    this1
  end
  def to_string(this1) do
    "UserId(" <> this1 <> ")"
  end
end