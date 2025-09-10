defmodule Stream_Impl_ do
  def _new(s) do
    this1 = nil
    this1 = s
    this1
  end
  def to_array(this1) do
    Enum.to_list(this1)
  end
  def map(this1, fn_param) do
    Stream.map(this1, fn_param)
  end
  def filter(this1, fn_param) do
    Stream.filter(this1, fn_param)
  end
  def take(this1, count) do
    Stream.take(this1, count)
  end
end