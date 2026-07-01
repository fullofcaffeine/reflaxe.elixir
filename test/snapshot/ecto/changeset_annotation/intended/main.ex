defmodule Main do
  def main() do
    attrs = %{title: "Widget", description: "Useful", price: 9.99, stock_count: 5, category_id: 1}
    _changeset = TestApp.Product.changeset(nil, attrs)
    nil
  end
end
