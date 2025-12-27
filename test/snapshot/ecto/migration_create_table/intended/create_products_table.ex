defmodule CreateProductsTable do
  @compile {:nowarn_unused_function, [drop_table: 3, add_column: 5, should_add_inventory: 2]}

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
  defp should_add_inventory(struct) do
    true
  end
  defp create_table(struct, table_name) do
    
  end
  defp drop_table(struct, table_name) do
    
  end
  defp add_column(struct, table, column, type) do
    
  end
  defp timestamps(struct) do
    
  end
  defp drop_table(struct, _name) do
    
  end
  defp add_column(struct, _arg, _arg, _arg, _arg) do
    
  end
  defp should_add_inventory(struct, _arg) do
    true
  end
end
