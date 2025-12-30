defmodule FormTemplate do
  def render_form(action, method) do
    csrf = get_csrf_token()
    "<form action='#{action}' method='#{method}'><input type='hidden' name='_csrf_token' value='#{csrf}'><div class='form-group'><label for='name'>Name:</label><input type='text' id='name' name='name' required></div><button type='submit'>Submit</button></form>"
  end
  def render_with_helpers(errors) do
    if (length(errors) == 0) do
      "<div class='no-errors'></div>"
    else
      error_items = []
      _g = 0
      error_items = Enum.reduce(errors, error_items, fn error, error_items_acc -> Enum.concat(error_items_acc, ["<li class='error-item'>" <> error <> "</li>"]) end)
      "<div class='form-errors'><ul class='error-list'>#{Enum.join(error_items, "")}</ul></div>"
    end
  end
  defp get_csrf_token() do
    "csrf_token_placeholder"
  end
end
