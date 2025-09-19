defmodule Migration do
  def create_table(name, options) do
    TableBuilder.new(name, options)
  end
  def drop_table(name, options) do
    nil
  end
  def alter_table(name) do
    AlterTableBuilder.new(name)
  end
  def create_index(table, columns, options) do
    nil
  end
  def drop_index(table, columns) do
    nil
  end
  def execute(sql) do
    nil
  end
  def create_constraint(table, name, check) do
    nil
  end
  def drop_constraint(table, name) do
    nil
  end
end