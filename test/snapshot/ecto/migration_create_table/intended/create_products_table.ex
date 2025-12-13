defmodule CreateProductsTable do
  @compile {:nowarn_unused_function, [drop_table: 2, add_column: 4, should_add_inventory: 1]}

  def up(struct) do
    _ = struct.createTable("products")
    _ = struct.addColumn("products", "name", "string")
    _ = struct.addColumn("products", "price", "decimal")
    if (struct.shouldAddInventory()) do
      struct.addColumn("products", "inventory_count", "integer")
    end
    _ = struct.timestamps()
  end
  def down(struct) do
    struct.dropTable("products")
  end
  defp drop_table(struct, _name) do
    
  end
  defp add_column(struct, _table, _column, _type) do
    
  end
  defp should_add_inventory(struct) do
    true
  end
end
