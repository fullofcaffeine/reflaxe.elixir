defmodule MyApp.Router do
  use Phoenix.Router
  pipeline :api do
    plug(:accepts, ["json"])
  end
end
