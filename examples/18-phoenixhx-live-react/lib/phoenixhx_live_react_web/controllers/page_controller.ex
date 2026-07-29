defmodule PhoenixhxLiveReactWeb.PageController do
  use PhoenixhxLiveReactWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
