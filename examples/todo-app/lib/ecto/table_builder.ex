defmodule TableBuilder do
  @table_name nil
  @columns nil
  @indexes nil
  @constraints nil
  @options nil
  def add_column(struct, name, type, options) do
    struct.columns ++ [%{:name => name, :type => type, :options => options}]
    struct
  end
  def add_id(struct, name, type) do
    if (type == {:AutoIncrement}) do
      struct.add_column(name, {:Integer}, %{:primary_key => true, :auto_generate => true})
    else
      struct.add_column(name, {:UUID}, %{:primary_key => true, :auto_generate => true})
    end
  end
  def add_timestamps(struct) do
    struct.add_column("inserted_at", {:DateTime}, %{:nullable => false})
    struct.add_column("updated_at", {:DateTime}, %{:nullable => false})
    struct
  end
  def add_reference(struct, column_name, referenced_table, options) do
    struct.add_column(column_name, {:References, referenced_table}, options)
    struct
  end
  def add_foreign_key(struct, column_name, referenced_table, options) do
    struct.add_reference(column_name, referenced_table, options)
  end
  def add_index(struct, columns, options) do
    struct.indexes ++ [%{:columns => columns, :options => options}]
    struct
  end
  def add_unique_constraint(struct, columns, name) do
    struct.constraints ++ [%{:type => {:Unique}, :columns => columns, :name => name, :expression => nil}]
    struct
  end
  def add_check_constraint(struct, name, expression) do
    struct.constraints ++ [%{:type => {:Check}, :name => name, :expression => expression, :columns => nil}]
    struct
  end
end