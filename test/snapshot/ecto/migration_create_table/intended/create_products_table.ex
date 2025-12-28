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
  defp should_add_inventory(_) do
    true
  end
  defp create_table(_, _) do
    
  end
  defp drop_table(_, _) do
    
  end
  defp add_column(_, _, _, _) do
    
  end
  defp timestamps(_) do
    
  end
end
