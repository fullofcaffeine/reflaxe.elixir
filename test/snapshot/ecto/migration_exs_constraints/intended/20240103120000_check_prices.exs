defmodule TestApp.Repo.Migrations.CheckPrices do
  use Ecto.Migration
  def up() do
    drop(constraint(:products, :legacy_price))
    create(constraint(:products, :positive_price, [check: "price > 0"]))
    create(constraint(:products, :bounded_price, [check: "price < 1000"]))
  end
  def down() do
    drop(constraint(:products, :bounded_price))
    drop(constraint(:products, :positive_price))
    create(constraint(:products, :legacy_price, [check: "price >= 0"]))
  end
end
