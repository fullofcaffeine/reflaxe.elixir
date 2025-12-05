defmodule UserLive do
  use Phoenix.Component
  use Phoenix.LiveView, layout: {UserLive.Layouts, :app}
  require Ecto.Query
end
