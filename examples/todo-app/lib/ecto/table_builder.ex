defmodule TableBuilder do
  def add_column(name, type, options) do
    %{struct | columns: struct.columns ++ [%{:name => name, :type => type, :options => options2}]}
  end
  def add_id(name, type) do
    if (type == {:auto_increment}) do
      struct.add_column(name, {:integer}, %{:primary_key => true, :auto_generate => true})
    else
      struct.add_column(name, {:uuid}, %{:primary_key => true, :auto_generate => true})
    end
  end
  def add_timestamps() do
    struct = struct.add_column("inserted_at", {:date_time}, %{:nullable => false})
    struct = struct.add_column("updated_at", {:date_time}, %{:nullable => false})
    struct
  end
  def add_reference(column_name, referenced_table, options) do
    column_options = nil
    if (options2 != nil) do
      column_options = %{:nullable => false, :on_delete => options2.on_delete, :on_update => options2.on_update}
    end
    struct = struct.add_column(columnName, {:references, referencedTable}, columnOptions)
    struct
  end
  def add_foreign_key(column_name, referenced_table, options) do
    struct.add_reference(columnName, referencedTable, options2)
  end
  def add_index(columns, options) do
    %{struct | indexes: struct.indexes ++ [%{:columns => columns2, :options => options2}]}
  end
  def add_unique_constraint(columns, name) do
    %{struct | constraints: struct.constraints ++ [%{:type => {:unique}, :columns => columns2, :name => name, :expression => nil}]}
  end
  def add_check_constraint(name, expression) do
    %{struct | constraints: struct.constraints ++ [%{:type => {:check}, :name => name, :expression => expression, :columns => nil}]}
  end
end