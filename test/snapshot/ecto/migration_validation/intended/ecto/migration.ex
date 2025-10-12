defmodule Migration do
  def create_table(struct, name, options) do
    MyApp.TableBuilder.new(name, options)
  end
  def drop_table(struct, _name, _options) do
    
  end
  def alter_table(struct, name) do
    MyApp.AlterTableBuilder.new(name)
  end
  def create_index(struct, _table, _columns, _options) do
    
  end
  def drop_index(struct, _table, _columns) do
    
  end
  def execute(struct, _sql) do
    
  end
  def create_constraint(struct, _table, _name, _check) do
    
  end
  def drop_constraint(struct, _table, _name) do
    
  end
end
