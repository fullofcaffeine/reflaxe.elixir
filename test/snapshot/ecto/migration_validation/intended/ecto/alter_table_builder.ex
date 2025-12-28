defmodule AlterTableBuilder do
  def new(name) do
    struct = %{:table_name => nil, :operations => nil}
    struct = %{struct | table_name: name}
    struct = %{struct | operations: []}
    struct
  end
  def add_column(struct, name, type, options) do
    %{struct | operations: struct.operations ++ [{:add_column, name, type, (if (not Kernel.is_nil(options)), do: options, else: nil)}]}
  end
  def remove_column(struct, name) do
    struct = %{struct | operations: struct.operations ++ [{:remove_column, name}]}
    struct
  end
  def modify_column(struct, name, type, options) do
    struct = %{struct | operations: struct.operations ++ [{:modify_column, name, type, (if (not Kernel.is_nil(options)), do: options, else: nil)}]}
    struct
  end
  def rename_column(struct, old_name, new_name) do
    struct = %{struct | operations: struct.operations ++ [{:rename_column, old_name, new_name}]}
    struct
  end
end
