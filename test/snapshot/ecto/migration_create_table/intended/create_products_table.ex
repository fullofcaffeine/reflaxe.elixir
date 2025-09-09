defmodule CreateProductsTable do
  def up(struct) do
    struct.create_table("products")
    struct.add_column("products", "name", "string")
    struct.add_column("products", "price", "decimal")
    if (struct.should_add_inventory()) do
      struct.add_column("products", "inventory_count", "integer")
    end
    struct.timestamps()
  end
  def down(struct) do
    struct.drop_table("products")
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