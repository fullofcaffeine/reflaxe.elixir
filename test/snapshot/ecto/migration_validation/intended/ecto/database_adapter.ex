defmodule Ecto.DatabaseAdapter do
  def postgres() do
    {0}
  end
  def my_sql() do
    {1}
  end
  def sq_lite3() do
    {2}
  end
  def sql_server() do
    {3}
  end
  def in_memory() do
    {4}
  end
end