defmodule TodoAppWeb.TodoLive do
  use Phoenix.Component
  use Phoenix.LiveView, layout: {TodoAppWeb.Layouts, :app}
  def build() do
    %MyApp.Todo{}
  end
end
