defmodule TestMigration2 do
  def up(struct) do
    reflaxe_dispatch_receiver = apply(Map.get(struct, :__reflaxe_class__) || Map.get(struct, :__struct__), :create_table, [struct, "comments", nil])
    reflaxe_dispatch_receiver = apply(Map.get(reflaxe_dispatch_receiver, :__reflaxe_class__) || Map.get(reflaxe_dispatch_receiver, :__struct__), :add_column, [reflaxe_dispatch_receiver, "id", {:integer}, %{primary_key: true, auto_generate: true}])
    reflaxe_dispatch_receiver = apply(Map.get(reflaxe_dispatch_receiver, :__reflaxe_class__) || Map.get(reflaxe_dispatch_receiver, :__struct__), :add_column, [reflaxe_dispatch_receiver, "content", {:text}, nil])
    reflaxe_dispatch_receiver = apply(Map.get(reflaxe_dispatch_receiver, :__reflaxe_class__) || Map.get(reflaxe_dispatch_receiver, :__struct__), :add_column, [reflaxe_dispatch_receiver, "post_id", {:integer}, nil])
    apply(Map.get(reflaxe_dispatch_receiver, :__reflaxe_class__) || Map.get(reflaxe_dispatch_receiver, :__struct__), :add_index, [reflaxe_dispatch_receiver, ["content"], %{unique: false}])
  end
  def down(struct) do
    apply(Map.get(struct, :__reflaxe_class__) || Map.get(struct, :__struct__), :drop_table, [struct, "comments", nil])
  end
  def create_table(struct, name, options) do
    Migration.create_table(struct, name, options)
  end
  def drop_table(struct, name, options) do
    Migration.drop_table(struct, name, options)
  end
  def alter_table(struct, name) do
    Migration.alter_table(struct, name)
  end
  def create_index(struct, table, columns, options) do
    Migration.create_index(struct, table, columns, options)
  end
  def drop_index(struct, table, columns) do
    Migration.drop_index(struct, table, columns)
  end
  def execute(struct, sql) do
    Migration.execute(struct, sql)
  end
  def create_constraint(struct, table, name, check) do
    Migration.create_constraint(struct, table, name, check)
  end
  def drop_constraint(struct, table, name) do
    Migration.drop_constraint(struct, table, name)
  end
end
