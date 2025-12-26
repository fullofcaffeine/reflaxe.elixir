defmodule TableBuilder do
  def add_column(struct, name, type, options) do
    _ = columns ++ [%{:name => name, :type => type, :options => (if (not Kernel.is_nil(options)), do: options, else: nil)}]
    struct
  end
  def add_id(struct, name, type) do
    if (type == {:auto_increment}) do
      struct.addColumn(name, {:integer}, %{:primary_key => true, :auto_generate => true})
    else
      struct.addColumn(name, {:uuid}, %{:primary_key => true, :auto_generate => true})
    end
  end
  def add_timestamps(struct) do
    _ = struct.addColumn("inserted_at", {:date_time}, %{:nullable => false})
    _ = struct.addColumn("updated_at", {:date_time}, %{:nullable => false})
    struct
  end
  def add_reference(struct, column_name, referenced_table, options) do
    column_options = nil
    if (not Kernel.is_nil(options)) do
      column_options = %{:nullable => false, :on_delete => options.on_delete, :on_update => options.on_update}
    end
    _ = struct.addColumn(column_name, {:references, referenced_table}, column_options)
    struct
  end
  def add_foreign_key(struct, column_name, referenced_table, options) do
    struct.addReference(column_name, referenced_table, options)
  end
  def add_index(struct, columns, options) do
    _ = indexes ++ [%{:columns => columns, :options => options}]
    struct
  end
  def add_unique_constraint(struct, columns, name) do
    _ = constraints ++ [%{:type => {:unique}, :columns => columns, :name => name, :expression => nil}]
    struct
  end
  def add_check_constraint(struct, name, expression) do
    _ = constraints ++ [%{:type => {:check}, :name => name, :expression => expression, :columns => nil}]
    struct
  end
end
