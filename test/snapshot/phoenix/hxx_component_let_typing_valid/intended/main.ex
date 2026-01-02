defmodule Main do
  use Phoenix.Component
  def render(assigns) do
    ~H"""
<.card title="Hello" :let={row}><span class={row.user_name}><%= row.user_name %> (<%= row.count %>)</span></.card>
"""
  end
  def main() do
    
  end
end
