defmodule Main do
  use Phoenix.Component
  def render(assigns) do
    ~H"""
    <form method="post" phx-update="replace">
        <input type="email" />
        <button type="submit">Save</button>
        <textarea wrap="hard"></textarea>
    </form>
    """
  end
  def main() do

  end
end
