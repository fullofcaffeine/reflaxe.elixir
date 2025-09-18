defmodule AlterTableBuilder do
  def add_column(name, type, options) do
    %{struct | operations: struct.operations ++ [{:add_column, name, type, options}]}
  end
  def remove_column(name) do
    struct = %{struct | operations: struct.operations ++ [{:remove_column, name}]}
    struct
  end
  def modify_column(name, type, options) do
    struct = %{struct | operations: struct.operations ++ [{:modify_column, name, type, options}]}
    struct
  end
  def rename_column(old_name, new_name) do
    struct = %{struct | operations: struct.operations ++ [{:rename_column, oldName, newName}]}
    struct
  end
end