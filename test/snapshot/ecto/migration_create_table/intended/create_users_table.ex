defmodule CreateUsersTable do
  @compile {:nowarn_unused_function, [drop_table: 3]}

  def up(struct) do
    _ = create_table(struct, "users")
    _ = add_column(struct, "users", "name", "string")
    _ = add_column(struct, "users", "email", "string")
    _ = add_column(struct, "users", "age", "integer")
    _ = add_index(struct, "users", ["email"])
    _ = timestamps(struct)
  end
  def down(struct) do
    drop_table(struct, "users")
  end
  defp create_table(struct, table_name) do
    
  end
  defp drop_table(struct, table_name) do
    
  end
  defp add_column(struct, table, column, type) do
    
  end
  defp add_index(struct, table, columns) do
    
  end
  defp timestamps(struct) do
    
  end
  defp drop_table(struct, _name) do
    
  end
end
