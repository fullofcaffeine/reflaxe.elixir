defmodule Migration do
  def create_table(struct, name, options) do
    TableBuilder.new(name, options)
  end
  def drop_table(struct, name, options) do
    
  end
  def alter_table(struct, name) do
    AlterTableBuilder.new(name)
  end
  def create_index(struct, table, columns, options) do
    
  end
  def drop_index(struct, table, columns) do
    
  end
  def execute(struct, sql) do
    
  end
  def create_constraint(struct, table, name, check) do
    
  end
  def drop_constraint(struct, table, name) do
    
  end
end
