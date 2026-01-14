defmodule Main do
  use Phoenix.Component
  def render(assigns) do
    ~H"""
<.form :let={_f} for={@changeset}><span>OK</span></.form>
"""
  end
  def main() do
    
  end
end
