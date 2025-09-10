defmodule Ecto.JsonLibrary do
  def jason() do
    {:Jason}
  end
  def poison() do
    {:Poison}
  end
  def none() do
    {:None}
  end
end