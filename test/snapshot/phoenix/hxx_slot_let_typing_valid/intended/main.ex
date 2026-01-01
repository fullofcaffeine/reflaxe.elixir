defmodule Main do
  use Phoenix.Component
  def render(assigns) do
    ~H"""
<.card title="Hello"><:header :let={h} label="Hi"><span class={h.user_name}><%= h.user_name %> (<%= h.count %>)</span></:header></.card>
"""
  end
  def main() do
    
  end
end
