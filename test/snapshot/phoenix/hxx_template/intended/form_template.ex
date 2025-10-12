defmodule FormTemplate do
  @compile {:nowarn_unused_function, [get_csrf_token: 0]}

  def render_form(action, method) do
    csrf = get_csrf_token()
    "<form action='#{action}' method='#{method}'><input type='hidden' name='_csrf_token' value='#{csrf}'><div class='form-group'><label for='name'>Name:</label><input type='text' id='name' name='name' required></div><button type='submit'>Submit</button></form>"
  end
  def render_with_helpers(errors) do
    if length(errors) == 0, do: "<div class='no-errors'></div>"
    error_items = []
    {errors} = Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {errors}, fn _, {errors} ->
  if 0 < length(errors) do
    error = errors[0]
    0 + 1
    error_items = Enum.concat(error_items, ["<li class='error-item'>" <> error <> "</li>"])
    {:cont, {errors}}
  else
    {:halt, {errors}}
  end
end)
    "<div class='form-errors'><ul class='error-list'>#{Enum.join(error_items, "")}</ul></div>"
  end
  defp get_csrf_token() do
    "csrf_token_placeholder"
  end
end
