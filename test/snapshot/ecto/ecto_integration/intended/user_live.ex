defmodule UserLive do
  use Phoenix.Component
  use Phoenix.LiveView, layout: {UserLive.Layouts, :app}
  def new() do
    struct = %{:users => nil, :selected_user => nil, :changeset => nil}
    struct = %{struct | changeset: nil}
    struct = %{struct | selected_user: nil}
    struct = %{struct | users: []}
    struct
  end
end
