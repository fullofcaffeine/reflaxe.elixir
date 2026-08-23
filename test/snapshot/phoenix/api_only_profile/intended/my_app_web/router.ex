defmodule MyAppWeb.Router do
  use Phoenix.Router
  pipeline :api do
    plug(:accepts, ["json"])
  end
  scope "/api" do
    pipe_through(:api)
    get("/status", MyAppWeb.ApiController, :status)
  end
end
