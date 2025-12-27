defmodule CreateUsers do
  @compile {:nowarn_unused_function, [drop_table: 3]}

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
    _ = add_index(struct, "users", ["name", "active"])
    _ = add_check_constraint(struct, "users", "age_check", "age >= 0 AND age <= 150")
  end
  def down(struct) do
    drop_table(struct, "users")
  end
  defp create_table(struct, name) do
    
  end
  defp add_column(struct, table, name, type, primary_key, default_value) do
    
  end
  defp add_timestamps(struct, table) do
    
  end
  defp drop_table(struct, name) do
    
  end
  defp add_index(struct, table, columns, options) do
    
  end
  defp add_check_constraint(struct, table, name, condition) do
    
  end
  defp drop_table(struct, _name) do
    
  end
end
