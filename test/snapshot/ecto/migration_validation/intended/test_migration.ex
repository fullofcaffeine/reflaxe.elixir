defmodule TestMigration do
  def up(struct) do
    reflaxe_dispatch_receiver_node_0 = apply(Map.get(struct, :__reflaxe_class__) || Map.get(struct, :__struct__), :create_table, [struct, "users", nil])
    reflaxe_dispatch_receiver_node_1 = apply(Map.get(reflaxe_dispatch_receiver_node_0, :__reflaxe_class__) || Map.get(reflaxe_dispatch_receiver_node_0, :__struct__), :add_column, [reflaxe_dispatch_receiver_node_0, "id", {:integer}, %{primary_key: true, auto_generate: true}])
    reflaxe_dispatch_receiver_node_2 = apply(Map.get(reflaxe_dispatch_receiver_node_1, :__reflaxe_class__) || Map.get(reflaxe_dispatch_receiver_node_1, :__struct__), :add_column, [reflaxe_dispatch_receiver_node_1, "name", {:string}, %{nullable: false}])
    reflaxe_dispatch_receiver_node_3 = apply(Map.get(reflaxe_dispatch_receiver_node_2, :__reflaxe_class__) || Map.get(reflaxe_dispatch_receiver_node_2, :__struct__), :add_column, [reflaxe_dispatch_receiver_node_2, "email", {:string}, %{nullable: false}])
    reflaxe_dispatch_receiver_node_4 = apply(Map.get(reflaxe_dispatch_receiver_node_3, :__reflaxe_class__) || Map.get(reflaxe_dispatch_receiver_node_3, :__struct__), :add_timestamps, [reflaxe_dispatch_receiver_node_3])
    apply(Map.get(reflaxe_dispatch_receiver_node_4, :__reflaxe_class__) || Map.get(reflaxe_dispatch_receiver_node_4, :__struct__), :add_index, [reflaxe_dispatch_receiver_node_4, ["email"], %{unique: true}])
    reflaxe_dispatch_receiver_node_5 = apply(Map.get(struct, :__reflaxe_class__) || Map.get(struct, :__struct__), :create_table, [struct, "posts", nil])
    reflaxe_dispatch_receiver_node_6 = apply(Map.get(reflaxe_dispatch_receiver_node_5, :__reflaxe_class__) || Map.get(reflaxe_dispatch_receiver_node_5, :__struct__), :add_column, [reflaxe_dispatch_receiver_node_5, "id", {:integer}, %{primary_key: true, auto_generate: true}])
    reflaxe_dispatch_receiver_node_7 = apply(Map.get(reflaxe_dispatch_receiver_node_6, :__reflaxe_class__) || Map.get(reflaxe_dispatch_receiver_node_6, :__struct__), :add_column, [reflaxe_dispatch_receiver_node_6, "title", {:string}, %{nullable: false}])
    reflaxe_dispatch_receiver_node_8 = apply(Map.get(reflaxe_dispatch_receiver_node_7, :__reflaxe_class__) || Map.get(reflaxe_dispatch_receiver_node_7, :__struct__), :add_column, [reflaxe_dispatch_receiver_node_7, "content", {:text}, nil])
    reflaxe_dispatch_receiver_node_9 = apply(Map.get(reflaxe_dispatch_receiver_node_8, :__reflaxe_class__) || Map.get(reflaxe_dispatch_receiver_node_8, :__struct__), :add_column, [reflaxe_dispatch_receiver_node_8, "author_id", {:integer}, nil])
    reflaxe_dispatch_receiver_node_10 = apply(Map.get(reflaxe_dispatch_receiver_node_9, :__reflaxe_class__) || Map.get(reflaxe_dispatch_receiver_node_9, :__struct__), :add_timestamps, [reflaxe_dispatch_receiver_node_9])
    apply(Map.get(reflaxe_dispatch_receiver_node_10, :__reflaxe_class__) || Map.get(reflaxe_dispatch_receiver_node_10, :__struct__), :add_foreign_key, [reflaxe_dispatch_receiver_node_10, "author_id", "users", nil])
  end
  def down(struct) do
    apply(Map.get(struct, :__reflaxe_class__) || Map.get(struct, :__struct__), :drop_table, [struct, "posts", nil])
    apply(Map.get(struct, :__reflaxe_class__) || Map.get(struct, :__struct__), :drop_table, [struct, "users", nil])
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
