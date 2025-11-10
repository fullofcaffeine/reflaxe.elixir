defmodule Ecto.IdType do
  def auto_increment() do
    {0}
  end
  def uuid() do
    {1}
  end
end
