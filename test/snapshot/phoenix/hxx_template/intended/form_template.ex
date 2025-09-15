defmodule FormTemplate do
  def render_form(action, method) do
    "<form action='#{action}' method='#{method}'><input type='hidden' name='_csrf_token' value='#{get_csrf_token()}'><div class='form-group'><label for='name'>Name:</label><input type='text' id='name' name='name' required></div><button type='submit'>Submit</button></form>"
  end
  def render_with_helpers(errors) do
    if length(errors) == 0 do
      "<div class='no-errors'></div>"
    else
      error_items = Enum.map(errors, fn error ->
        "<li class='error-item'>#{error}</li>"
      end)
      "<div class='form-errors'><ul class='error-list'>#{Enum.join(error_items, "")}</ul></div>"
    end
  end
  defp get_csrf_token() do
    "csrf_token_placeholder"
  end
end