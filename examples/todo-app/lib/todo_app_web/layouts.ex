defmodule TodoAppWeb.Layouts do
  def root() do
    fn assigns -> RootLayout.render(assigns) end
  end
  def app() do
    fn assigns -> AppLayout.render(assigns) end
  end
end