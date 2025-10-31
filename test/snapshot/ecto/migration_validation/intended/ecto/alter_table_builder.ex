defmodule AlterTableBuilder do
  def add_column(struct, name, type, options) do
    operations = operations ++ [{:add_column, name, type, options}]
    struct
  end
  def remove_column(struct, name) do
    operations = operations ++ [{:remove_column, name}]
    struct
  end
  def modify_column(struct, name, type, options) do
    operations = operations ++ [{:modify_column, name, type, options}]
    struct
  end
  def rename_column(struct, old_name, new_name) do
    operations = operations ++ [{:rename_column, old_name, new_name}]
    struct
  end
end
