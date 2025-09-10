defmodule Ecto.DatabaseAdapter do
  def postgres() do
    {:Postgres}
  end
  def my_sql() do
    {:MySQL}
  end
  def sq_lite3() do
    {:SQLite3}
  end
  def sql_server() do
    {:SQLServer}
  end
  def in_memory() do
    {:InMemory}
  end
end