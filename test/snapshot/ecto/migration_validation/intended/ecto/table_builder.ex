defmodule TableBuilder do
  def add_column(struct, name, type, options) do
    columns = columns ++ [%{:name => name, :type => type, :options => (if (not Kernel.is_nil(options)), do: options, else: nil)}]
  end
  def add_id(struct, name, type) do
    if (type == {:auto_increment}) do
      add_column(struct, name, {:integer}, %{:primary_key => true, :auto_generate => true})
    else
      add_column(struct, name, {:uuid}, %{:primary_key => true, :auto_generate => true})
    end
  end
  def add_timestamps(struct) do
    _ = add_column(struct, "inserted_at", {:date_time}, %{:nullable => false})
    _ = add_column(struct, "updated_at", {:date_time}, %{:nullable => false})
    struct
  end
  def add_reference(struct, column_name, referenced_table, options) do
    column_options = if (not Kernel.is_nil(options)), do: %{:nullable => false, :on_delete => options.on_delete, :on_update => options.on_update}, else: column_options
    _ = add_column(struct, column_name, {:references, referenced_table}, column_options)
    struct
  end
  def add_foreign_key(struct, column_name, referenced_table, options) do
    add_reference(struct, column_name, referenced_table, options)
  end
  def add_index(struct, columns, options) do
    indexes = indexes ++ [%{:columns => columns, :options => options}]
  end
  def add_unique_constraint(struct, columns, name) do
    constraints = constraints ++ [%{:type => {:unique}, :columns => columns, :name => name, :expression => nil}]
  end
  def add_check_constraint(struct, name, expression) do
    constraints = constraints ++ [%{:type => {:check}, :name => name, :expression => expression, :columns => nil}]
  end
end
