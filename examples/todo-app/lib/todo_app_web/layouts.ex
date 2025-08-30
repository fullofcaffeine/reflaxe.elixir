defmodule TodoAppWeb.Layouts do
  def root(assigns) do
    fn assigns -> RootLayout.render(assigns) end
  end
  def app(assigns) do
    fn assigns -> AppLayout.render(assigns) end
  end
end