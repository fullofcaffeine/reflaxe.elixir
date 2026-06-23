defmodule Main do
  use Phoenix.Component
  def render(assigns) do
    ~H"""
<.card title="Hello"><:header label="Hello">Hi</:header></.card>
"""
  end
  def main() do

  end
end
