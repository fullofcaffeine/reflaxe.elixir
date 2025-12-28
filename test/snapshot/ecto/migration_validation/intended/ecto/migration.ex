defmodule Migration do
  def create_table(_, name, options) do
    TableBuilder.new(name, options)
  end
  def drop_table(_, _, _) do
    
  end
  def alter_table(_, name) do
    AlterTableBuilder.new(name)
  end
  def create_index(_, _, _, _) do
    
  end
  def drop_index(_, _, _) do
    
  end
  def execute(_, _) do
    
  end
  def create_constraint(_, _, _, _) do
    
  end
  def drop_constraint(_, _, _) do
    
  end
end
