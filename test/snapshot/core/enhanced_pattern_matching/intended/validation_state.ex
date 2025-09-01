defmodule ValidationState do
  def valid() do
    {:Valid}
  end
  def invalid(arg0) do
    {:Invalid, arg0}
  end
  def pending(arg0) do
    {:Pending, arg0}
  end
end