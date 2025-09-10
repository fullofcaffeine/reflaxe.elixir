defmodule TableBuilder do
  @table_name nil
  @columns nil
  @indexes nil
  @constraints nil
  @options nil
  def add_column(_struct, _name, _type, _options) do
    %{struct | columns: struct.columns ++ [%{:name => name, :type => type, :options => options}]}
  end
  def add_id(struct, name, type) do
    if (type == {:AutoIncrement}) do
      struct.add_column(name, {:Integer}, %{:primary_key => true, :auto_generate => true})
    else
      struct.add_column(name, {:UUID}, %{:primary_key => true, :auto_generate => true})
    end
  end
  def add_timestamps(struct) do
    struct = struct.add_column("inserted_at", {:DateTime}, %{:nullable => false})
    struct = struct.add_column("updated_at", {:DateTime}, %{:nullable => false})
    struct
  end
  def add_reference(struct, column_name, referenced_table, options) do
    column_options = nil
    if (options != nil) do
      column_options = %{:nullable => false, :on_delete => options.on_delete, :on_update => options.on_update}
    end
    struct = struct.add_column(column_name, {:References, referenced_table}, column_options)
    struct
  end
  def add_foreign_key(struct, column_name, referenced_table, options) do
    struct = struct.add_reference(column_name, referenced_table, options)
  end
  def add_index(_struct, _columns, _options) do
    %{struct | indexes: struct.indexes ++ [%{:columns => columns, :options => options}]}
  end
  def add_unique_constraint(_struct, _columns, _name) do
    %{struct | constraints: struct.constraints ++ [%{:type => {:Unique}, :columns => columns, :name => name, :expression => nil}]}
  end
  def add_check_constraint(_struct, _name, _expression) do
    %{struct | constraints: struct.constraints ++ [%{:type => {:Check}, :name => name, :expression => expression, :columns => nil}]}
  end
end