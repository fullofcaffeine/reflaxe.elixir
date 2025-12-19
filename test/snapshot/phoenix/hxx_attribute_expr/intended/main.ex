defmodule Main do
  use Phoenix.Component
  def render(assigns) do
    ~H"""
<div>
      <option value="created" selected={@sort_by == "created"}></option>
      <div class={if (@flag), do: "on", else: "off"} id={if (@flag), do: "flag-on", else: "flag-off"}></div>
    </div>
"""
  end
  def main() do
    
  end
end
