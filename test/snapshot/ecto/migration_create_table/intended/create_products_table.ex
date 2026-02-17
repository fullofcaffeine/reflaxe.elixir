defmodule CreateProductsTable do
  def up(struct) do
    _ = create_table(struct, "products")
    _ = add_column(struct, "products", "name", "string")
    _ = add_column(struct, "products", "price", "decimal")
    if (should_add_inventory(struct)) do
      add_column(struct, "products", "inventory_count", "integer")
    end
    _ = timestamps(struct)
  end
  def down(struct) do
    drop_table(struct, "products")
  end
  defp should_add_inventory(_struct) do
    true
  end
  defp create_table(_struct, _table_name) do
    
  end
  defp drop_table(_struct, _table_name) do
    
  end
  defp add_column(_struct, _table, _column, _type) do
    
  end
  defp timestamps(_struct) do
    
  end
end
