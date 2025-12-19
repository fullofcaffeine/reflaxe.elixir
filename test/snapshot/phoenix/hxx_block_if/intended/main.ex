defmodule Main do
  use Phoenix.Component
  def render(assigns) do
    content = "
      <div>
        <p>Welcome, #{(fn -> assigns.current_user.name end).()}!</p>
        <div class=\"stats\">
          <span>#{(fn -> Kernel.to_string(assigns.total_todos) end).()}</span>
          <span>#{(fn -> Kernel.to_string(assigns.completed_todos) end).()}</span>
          <span>#{(fn -> Kernel.to_string(assigns.pending_todos) end).()}</span>
        </div>
        #{(fn -> if (assigns.show_form), do: "<div id=\"form\">FORM</div>", else: "" end).()}
      </div>
    "
    ~H"""
<%= Phoenix.HTML.raw(content) %>
"""
  end
  def main() do
    
  end
end
