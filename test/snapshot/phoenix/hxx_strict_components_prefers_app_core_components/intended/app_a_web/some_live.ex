defmodule AppAWeb.SomeLive do
  use Phoenix.Component
  use Phoenix.LiveView, layout: {AppAWeb.Layouts, :app}
  import AppAWeb.CoreComponents, except: [label: 1]
  def render(assigns) do
    ~H"""
<.card title="Hello">Hi</.card>
"""
  end
  def main() do

  end
end
