defmodule Migration do
  def create_table(struct, name, options) do
    TableBuilder.new(name, options)
  end
  def drop_table(struct, _name, _options) do
    nil
  end
  def alter_table(struct, name) do
    AlterTableBuilder.new(name)
  end
  def create_index(struct, _table, _columns, _options) do
    nil
  end
  def drop_index(struct, _table, _columns) do
    nil
  end
  def execute(struct, _sql) do
    nil
  end
  def create_constraint(struct, _table, _name, _check) do
    nil
  end
  def drop_constraint(struct, _table, _name) do
    nil
  end
end