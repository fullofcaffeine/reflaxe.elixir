defmodule TestApp.Product do
  use Ecto.Schema
  schema "products" do
    _ = timestamps()
  end
  
  def changeset(product, attrs) do
    product
    |> Ecto.Changeset.cast(attrs, [:title, :description, :price, :stock_count, :category_id])
    |> Ecto.Changeset.validate_required([:title, :price])
  end
end
