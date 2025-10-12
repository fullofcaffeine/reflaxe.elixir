defmodule CreateProductsTable do
  @compile {:nowarn_unused_function, [should_add_inventory: 1, create_table: 2, drop_table: 2, add_column: 4, timestamps: 1]}

  def up(struct) do
    struct.createTable("products")
    struct.addColumn("products", "name", "string")
    struct.addColumn("products", "price", "decimal")
    if struct.shouldAddInventory() do
      struct.addColumn("products", "inventory_count", "integer")
    end
    struct.timestamps()
  end
  def down(struct) do
    struct.dropTable("products")
  end
  defp should_add_inventory(struct) do
    true
  end
  defp create_table(struct, _table_name) do
    
  end
  defp drop_table(struct, _table_name) do
    
  end
  defp add_column(struct, _table, _column, _type) do
    
  end
  defp timestamps(struct) do
    
  end
end
