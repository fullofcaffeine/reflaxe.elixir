defmodule TodoAppWeb.Layouts do
  use Phoenix.Component

  @moduledoc """
    TodoAppWeb.Layouts module generated from Haxe

     * Main layouts module for Phoenix application
     * Provides the layout functions that Phoenix expects
  """

  # Static functions
  @doc "Generated from Haxe root"
  def root(assigns) do
    RootLayout.render(_assigns)
  end

  @doc "Generated from Haxe app"
  def app(assigns) do
    AppLayout.render(_assigns)
  end

end
