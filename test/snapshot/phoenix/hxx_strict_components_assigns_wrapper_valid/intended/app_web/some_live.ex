defmodule AppWeb.SomeLive do
  use Phoenix.Component
  use Phoenix.LiveView, layout: {AppWeb.Layouts, :app}
  import AppWeb.CoreComponents, except: [label: 1]
  def render(assigns) do
    ~H"""
<.card title="Hello">Hi</.card>
"""
  end
  def main() do

  end
end
