defmodule CreateUsersTable do
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
  defp create_table(_, _) do
    
  end
  defp drop_table(_, _) do
    
  end
  defp add_column(_, _, _, _) do
    
  end
  defp add_index(_, _, _) do
    
  end
  defp timestamps(_) do
    
  end
end
