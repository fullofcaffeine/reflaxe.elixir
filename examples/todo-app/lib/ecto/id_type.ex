defmodule Ecto.IdType do
  def auto_increment() do
    {:AutoIncrement}
  end
  def uuid() do
    {:UUID}
  end
end