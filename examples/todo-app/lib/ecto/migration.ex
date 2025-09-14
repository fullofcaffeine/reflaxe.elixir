defmodule Migration do
  def create_table(_struct, name, options) do
    TableBuilder.new(name, options)
  end
  def drop_table(_struct, _name, _options) do
    nil
  end
  def alter_table(_struct, name) do
    AlterTableBuilder.new(name)
  end
  def create_index(_struct, _table, _columns, _options) do
    nil
  end
  def drop_index(_struct, _table, _columns) do
    nil
  end
  def execute(_struct, _sql) do
    nil
  end
  def create_constraint(_struct, _table, _name, _check) do
    nil
  end
  def drop_constraint(_struct, _table, _name) do
    nil
  end
end