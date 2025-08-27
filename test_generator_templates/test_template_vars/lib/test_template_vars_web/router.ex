defmodule TestTemplateVarsWeb.Router do
  use TestTemplateVarsWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", TestTemplateVarsWeb do
    pipe_through :api
  end

  # Enable Swoosh mailbox preview in development
  if Application.compile_env(:test_template_vars, :dev_routes) do

    scope "/dev" do
      pipe_through [:fetch_session, :protect_from_forgery]

      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
