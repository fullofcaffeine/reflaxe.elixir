defmodule AlterTableBuilder do
  @table_name nil
  @operations nil
  def add_column(struct, name, type, options) do
    %{struct | operations: struct.operations ++ [{:add_column, name, type, options}]}
  end
  def remove_column(struct, name) do
    struct.operations ++ [{:remove_column, name}]
    struct
  end
  def modify_column(struct, name, type, options) do
    struct.operations ++ [{:modify_column, name, type, options}]
    struct
  end
  def rename_column(struct, old_name, new_name) do
    struct.operations ++ [{:rename_column, old_name, new_name}]
    struct
  end
end