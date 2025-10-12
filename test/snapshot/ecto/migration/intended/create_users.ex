defmodule CreateUsers do
  @compile {:nowarn_unused_function, [create_table: 2, add_column: 6, add_timestamps: 2, drop_table: 2, add_index: 4, add_check_constraint: 4]}

  def up(struct) do
    struct.createTable("users")
    struct.addColumn("users", "id", "serial", true, nil)
    struct.addColumn("users", "name", "string", false, nil)
    struct.addColumn("users", "email", "string", false, nil)
    struct.addColumn("users", "age", "integer", nil, 0)
    struct.addColumn("users", "bio", "text", nil, nil)
    struct.addColumn("users", "active", "boolean", nil, true)
    struct.addTimestamps("users")
    struct.addIndex("users", ["email"], %{:unique => true})
    struct.addIndex("users", ["name", "active"])
    struct.addCheckConstraint("users", "age_check", "age >= 0 AND age <= 150")
  end
  def down(struct) do
    struct.dropTable("users")
  end
  defp create_table(struct, _name) do
    
  end
  defp add_column(struct, _table, _name, _type, _primary_key, _default_value) do
    
  end
  defp add_timestamps(struct, _table) do
    
  end
  defp drop_table(struct, _name) do
    
  end
  defp add_index(struct, _table, _columns, _options) do
    
  end
  defp add_check_constraint(struct, _table, _name, _condition) do
    
  end
end
