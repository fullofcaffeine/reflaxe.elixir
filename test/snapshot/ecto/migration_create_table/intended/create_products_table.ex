defmodule CreateProductsTable do
  @compile {:nowarn_unused_function, [create_table: 2, drop_table: 2, add_column: 4, timestamps: 1, should_add_inventory: 1]}

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
  defp create_table(struct, _name) do
    
  end
  defp drop_table(struct, _name) do
    
  end
  defp add_column(struct, _table, _column, _type) do
    
  end
  defp timestamps(struct) do
    
  end
  defp should_add_inventory(struct) do
    true
  end
end
