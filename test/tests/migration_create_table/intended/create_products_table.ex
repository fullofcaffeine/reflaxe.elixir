defmodule CreateProductsTable do
  use Ecto.Migration

  def up do
    create table(:products) do
      # columns will be added by subsequent DSL calls
    end
    add :name, :string
    add :price, :decimal
    if __MODULE__.should_add_inventory() do
      add :inventory_count, :integer
    end
    timestamps()
  end

  def down do
    drop table(:products)
  end

  @doc "Generated from Haxe shouldAddInventory"
  def should_add_inventory() do
    true
  end


end