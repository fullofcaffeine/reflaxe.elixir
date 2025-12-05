defmodule Migration do
  def create_table(_struct, _name, _options) do
    MyApp.TableBuilder.new(name, options)
  end
  def drop_table(_struct, _name, _options) do
    
  end
  def alter_table(_struct, _name) do
    MyApp.AlterTableBuilder.new(name)
  end
  def create_index(_struct, _table, _columns, _options) do
    
  end
  def drop_index(_struct, _table, _columns) do
    
  end
  def execute(_struct, _sql) do
    
  end
  def create_constraint(_struct, _table, _name, _check) do
    
  end
  def drop_constraint(_struct, _table, _name) do
    
  end
end
