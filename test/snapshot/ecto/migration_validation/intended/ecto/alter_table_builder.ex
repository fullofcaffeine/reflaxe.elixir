defmodule AlterTableBuilder do
  def add_column(struct, name, type, options) do
    _ = operations ++ [{:add_column, name, type, (if (not Kernel.is_nil(options)), do: options, else: nil)}]
    struct
  end
  def remove_column(struct, name) do
    _ = operations ++ [{:remove_column, name}]
    struct
  end
  def modify_column(struct, name, type, options) do
    _ = operations ++ [{:modify_column, name, type, (if (not Kernel.is_nil(options)), do: options, else: nil)}]
    struct
  end
  def rename_column(struct, old_name, new_name) do
    _ = operations ++ [{:rename_column, old_name, new_name}]
    struct
  end
end
