defmodule FormTemplate do
  def render_form(action, method) do
    csrf = get_csrf_token()
    "<form action='#{(fn -> action end).()}' method='#{(fn -> method end).()}'><input type='hidden' name='_csrf_token' value='#{(fn -> csrf end).()}'><div class='form-group'><label for='name'>Name:</label><input type='text' id='name' name='name' required></div><button type='submit'>Submit</button></form>"
  end
  def render_with_helpers(errors) do
    if (length(errors) == 0), do: "<div class='no-errors'></div>"
    error_items = []
    Enum.each(errors, (fn -> fn item ->
            item = Enum.concat(item, ["<li class='error-item'>" <> item <> "</li>"])
    end end).())
    "<div class='form-errors'><ul class='error-list'>#{(fn -> Enum.join((fn -> error_items end).(), "") end).()}</ul></div>"
  end
  defp get_csrf_token() do
    "csrf_token_placeholder"
  end
end
