defmodule TableBuilder do
  def new(name, options_param) do
    struct = %{:table_name => nil, :columns => nil, :indexes => nil, :constraints => nil, :options => nil}
    struct = %{struct | table_name: name}
    struct = %{struct | columns: []}
    struct = %{struct | indexes: []}
    struct = %{struct | constraints: []}
    struct = %{struct | options: (if (not Kernel.is_nil(options_param)), do: options_param, else: %{})}
    struct
  end
  def add_column(struct, name, type, options_param) do
    %{struct | columns: struct.columns ++ [%{:name => name, :type => type, :options => (if (not Kernel.is_nil(options_param)), do: options_param, else: nil)}]}
  end
  def add_id(struct, name, type) do
    if (type == {:auto_increment}) do
      add_column(struct, name, {:integer}, %{:primary_key => true, :auto_generate => true})
    else
      add_column(struct, name, {:uuid}, %{:primary_key => true, :auto_generate => true})
    end
  end
  def add_timestamps(struct) do
    struct = add_column(struct, "inserted_at", {:date_time}, %{:nullable => false})
    struct = add_column(struct, "updated_at", {:date_time}, %{:nullable => false})
    struct
  end
  def add_reference(struct, column_name, referenced_table, options_param) do
    column_options = nil
    column_options = if (not Kernel.is_nil(options_param)), do: %{:nullable => false, :on_delete => options_param.on_delete, :on_update => options_param.on_update}, else: column_options
    struct = add_column(struct, column_name, {:references, referenced_table}, column_options)
    struct
  end
  def add_foreign_key(struct, column_name, referenced_table, options_param) do
    add_reference(struct, column_name, referenced_table, options_param)
  end
  def add_index(struct, columns_param, options_param) do
    %{struct | indexes: struct.indexes ++ [%{:columns => columns_param, :options => options_param}]}
  end
  def add_unique_constraint(struct, columns_param, name) do
    %{struct | constraints: struct.constraints ++ [%{:type => {:unique}, :columns => columns_param, :name => name, :expression => nil}]}
  end
  def add_check_constraint(struct, name, expression) do
    %{struct | constraints: struct.constraints ++ [%{:type => {:check}, :name => name, :expression => expression, :columns => nil}]}
  end
end
