defmodule TodoAppWeb.Layouts do
  def root(assigns) do
    RootLayout.render(assigns)
  end
  def app(assigns) do
    AppLayout.render(assigns)
  end
end