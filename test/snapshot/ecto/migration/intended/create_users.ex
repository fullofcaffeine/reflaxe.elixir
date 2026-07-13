defmodule CreateUsers do
  def up(struct) do
    create_table(struct, "users")
    add_column(struct, "users", "id", "serial", true, nil)
    add_column(struct, "users", "name", "string", false, nil)
    add_column(struct, "users", "email", "string", false, nil)
    add_column(struct, "users", "age", "integer", nil, 0)
    add_column(struct, "users", "bio", "text", nil, nil)
    add_column(struct, "users", "active", "boolean", nil, true)
    add_timestamps(struct, "users")
    add_index(struct, "users", ["email"], %{unique: true})
    add_index(struct, "users", ["name", "active"], nil)
    add_check_constraint(struct, "users", "age_check", "age >= 0 AND age <= 150")
  end
  def down(struct) do
    drop_table(struct, "users")
  end
  defp create_table(_struct, _name) do

  end
  defp add_column(_struct, _table, _name, _type, _primary_key, _default_value) do

  end
  defp add_timestamps(_struct, _table) do

  end
  defp drop_table(_struct, _name) do

  end
  defp add_index(_struct, _table, _columns, _options) do

  end
  defp add_check_constraint(_struct, _table, _name, _condition) do

  end
end
