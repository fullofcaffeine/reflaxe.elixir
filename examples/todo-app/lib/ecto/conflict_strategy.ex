defmodule ecto.ConflictStrategy do
  def error() do
    {:Error}
  end
  def nothing() do
    {:Nothing}
  end
  def replace_all() do
    {:ReplaceAll}
  end
  def replace(arg0) do
    {:Replace, arg0}
  end
  def update(arg0) do
    {:Update, arg0}
  end
end