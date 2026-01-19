defmodule Main do
  use Phoenix.Component
  def render(assigns) do
    ~H"""
<div>
            <.form :let={f} for={@formFor} action="/save">
                <div>
                    <input type="text" name="title" value={f[:title].value}/>
                </div>
            </.form>
        </div>
"""
  end
  def main() do
    
  end
end
