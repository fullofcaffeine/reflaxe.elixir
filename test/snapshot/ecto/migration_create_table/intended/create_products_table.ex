defmodule CreateProductsTable do
  def up(struct) do
    struct.createTable("products")
    struct.addColumn("products", "name", "string")
    struct.addColumn("products", "price", "decimal")
    if (struct.shouldAddInventory()) do
      struct.addColumn("products", "inventory_count", "integer")
    end
    struct.timestamps()
  end
  def down(struct) do
    struct.dropTable("products")
  end
  defp should_add_inventory(_struct) do
    true
  end
  defp create_table(_struct, _table_name) do
    nil
  end
  defp drop_table(_struct, _table_name) do
    nil
  end
  defp add_column(_struct, _table, _column, _type) do
    nil
  end
  defp timestamps(_struct) do
    nil
  end
end