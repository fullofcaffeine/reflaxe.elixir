defmodule CreateUsersTable do
  def up(struct) do
    create_table(struct, "users")
    add_column(struct, "users", "name", "string")
    add_column(struct, "users", "email", "string")
    add_column(struct, "users", "age", "integer")
    add_index(struct, "users", ["email"])
    timestamps(struct)
  end
  def down(struct) do
    drop_table(struct, "users")
  end
  defp create_table(_struct, _table_name) do

  end
  defp drop_table(_struct, _table_name) do

  end
  defp add_column(_struct, _table, _column, _type) do

  end
  defp add_index(_struct, _table, _columns) do

  end
  defp timestamps(_struct) do

  end
end
