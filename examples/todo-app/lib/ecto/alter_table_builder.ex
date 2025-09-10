defmodule AlterTableBuilder do
  @table_name nil
  @operations nil
  def add_column(struct, name, type, options) do
    %{struct | operations: struct.operations ++ [{:AddColumn, name, type, options}]}
  end
  def remove_column(struct, name) do
    struct.operations ++ [{:RemoveColumn, name}]
    struct
  end
  def modify_column(struct, name, type, options) do
    struct.operations ++ [{:ModifyColumn, name, type, options}]
    struct
  end
  def rename_column(struct, old_name, new_name) do
    struct.operations ++ [{:RenameColumn, old_name, new_name}]
    struct
  end
end