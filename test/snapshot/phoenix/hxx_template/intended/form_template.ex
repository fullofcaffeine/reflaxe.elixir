defmodule FormTemplate do
  def render_form(action, method) do
    csrf = get_csrf_token()
    "<form action='#{(fn -> action end).()}' method='#{(fn -> method end).()}'><input type='hidden' name='_csrf_token' value='#{(fn -> csrf end).()}'><div class='form-group'><label for='name'>Name:</label><input type='text' id='name' name='name' required></div><button type='submit'>Submit</button></form>"
  end
  def render_with_helpers(errors) do
    if (length(errors) == 0) do
      "<div class='no-errors'></div>"
    else
      error_items = []
      _ = Enum.each(errors, (fn -> fn error ->
    error = Enum.concat(error, ["<li class='error-item'>" <> error <> "</li>"])
end end).())
      "<div class='form-errors'><ul class='error-list'>#{(fn -> Enum.join((fn -> error_items end).(), "") end).()}</ul></div>"
    end
  end
  defp get_csrf_token() do
    "csrf_token_placeholder"
  end
end
