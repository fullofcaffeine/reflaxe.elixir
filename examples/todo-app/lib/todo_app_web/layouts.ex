defmodule TodoAppWeb.Layouts do
  def root(_assigns) do
    RootLayout.render(assigns)
  end
  def app(_assigns) do
    AppLayout.render(assigns)
  end
end