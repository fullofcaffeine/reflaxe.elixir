defmodule CreateUsers do
  def up(struct) do
    _ = create_table(struct, "users")
    _ = add_column(struct, "users", "id", "serial", true, nil)
    _ = add_column(struct, "users", "name", "string", false, nil)
    _ = add_column(struct, "users", "email", "string", false, nil)
    _ = add_column(struct, "users", "age", "integer", nil, 0)
    _ = add_column(struct, "users", "bio", "text", nil, nil)
    _ = add_column(struct, "users", "active", "boolean", nil, true)
    _ = add_timestamps(struct, "users")
    _ = add_index(struct, "users", ["email"], %{:unique => true})
    _ = add_index(struct, "users", ["name", "active"], nil)
    _ = add_check_constraint(struct, "users", "age_check", "age >= 0 AND age <= 150")
  end
  def down(struct) do
    drop_table(struct, "users")
  end
  defp create_table(_, _) do
    
  end
  defp add_column(_, _, _, _, _, _) do
    
  end
  defp add_timestamps(_, _) do
    
  end
  defp drop_table(_, _) do
    
  end
  defp add_index(_, _, _, _) do
    
  end
  defp add_check_constraint(_, _, _, _) do
    
  end
end
