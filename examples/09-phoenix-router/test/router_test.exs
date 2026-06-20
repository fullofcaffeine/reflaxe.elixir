defmodule PhoenixRouterExampleTest do
  use ExUnit.Case, async: true

  defp routes do
    PhoenixRouterWeb.Router.__routes__()
  end

  defp assert_route(verb, path, plug, action) do
    assert Enum.any?(routes(), fn route ->
             route.verb == verb and route.path == path and route.plug == plug and
               route.plug_opts == action
           end)
  end

  test "typed router tree expands into Phoenix route metadata" do
    assert length(routes()) == 12

    assert_route(:get, "/users", PhoenixRouterWeb.UserController, :index)
    assert_route(:get, "/users/:id", PhoenixRouterWeb.UserController, :show)
    assert_route(:post, "/users", PhoenixRouterWeb.UserController, :create)
    assert_route(:put, "/users/:id", PhoenixRouterWeb.UserController, :update)
    assert_route(:delete, "/users/:id", PhoenixRouterWeb.UserController, :delete)

    assert_route(:get, "/products", PhoenixRouterWeb.ProductController, :index)
    assert_route(:get, "/products/:id", PhoenixRouterWeb.ProductController, :show)
    assert_route(:post, "/products", PhoenixRouterWeb.ProductController, :create)
    assert_route(:put, "/products/:id", PhoenixRouterWeb.ProductController, :update)
    assert_route(:delete, "/products/:id", PhoenixRouterWeb.ProductController, :delete)

    assert_route(
      :get,
      "/products/:product_id/reviews",
      PhoenixRouterWeb.ProductController,
      :reviews
    )

    assert_route(
      :post,
      "/products/:product_id/reviews",
      PhoenixRouterWeb.ProductController,
      :create_review
    )
  end

  test "generated controller helper methods keep typed path values" do
    assert PhoenixRouterWeb.UserController.index() == "List all users"
    assert PhoenixRouterWeb.UserController.show(42) == "Show user 42"
    assert PhoenixRouterWeb.UserController.update(42, %{}) == "Update user 42"
    assert PhoenixRouterWeb.UserController.delete(42) == "Delete user 42"

    assert PhoenixRouterWeb.ProductController.index() == "List all products"
    assert PhoenixRouterWeb.ProductController.show(7) == "Show product 7"
    assert PhoenixRouterWeb.ProductController.reviews(7) == "Reviews for product 7"

    assert PhoenixRouterWeb.ProductController.create_review(7, %{}) ==
             "Create review for product 7"
  end
end
