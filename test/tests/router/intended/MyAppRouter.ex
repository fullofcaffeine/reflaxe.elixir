defmodule MyAppRouter do
  use Phoenix.Router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", MyAppRouter do
    pipe_through :browser

  end

  scope "/api", MyAppRouter do
    pipe_through :api

    # API routes will be generated here
  end
end


defmodule PageController do
  @moduledoc """
  PageController module generated from Haxe
  """

end


defmodule UserController do
  @moduledoc """
  UserController module generated from Haxe
  """

end


defmodule PostController do
  @moduledoc """
  PostController module generated from Haxe
  """

end


defmodule CommentController do
  @moduledoc """
  CommentController module generated from Haxe
  """

end


defmodule SettingsController do
  @moduledoc """
  SettingsController module generated from Haxe
  """

end


defmodule StatusController do
  @moduledoc """
  StatusController module generated from Haxe
  """

end


defmodule ProductController do
  @moduledoc """
  ProductController module generated from Haxe
  """

end


defmodule OrderController do
  @moduledoc """
  OrderController module generated from Haxe
  """

end


defmodule DashboardLive do
  @moduledoc """
  DashboardLive module generated from Haxe
  """

end


defmodule UserLive do
  @moduledoc """
  UserLive module generated from Haxe
  """

end


defmodule ProfileLive do
  @moduledoc """
  ProfileLive module generated from Haxe
  """

end


defmodule SettingsLive do
  @moduledoc """
  SettingsLive module generated from Haxe
  """

end


defmodule AdminRouter do
  @moduledoc """
  AdminRouter module generated from Haxe
  """

end


defmodule ErrorController do
  @moduledoc """
  ErrorController module generated from Haxe
  """

end


defmodule MyAppWeb do
  @moduledoc """
  MyAppWeb module generated from Haxe
  """

end


@type route :: any()