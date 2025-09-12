defmodule FormTemplate do
  def render_form(action, method) do
    "<form action='" <> action <> "' method='" <> method <> "'>" <> "<input type='hidden' name='_csrf_token' value='" <> (get_csrf_token()) <> "'>" <> "<div class='form-group'>" <> "<label for='name'>Name:</label>" <> "<input type='text' id='name' name='name' required>" <> "</div>" <> "<button type='submit'>Submit</button>" <> "</form>"
  end
  def render_with_helpers(errors) do
    if (length(errors) == 0), do: "<div class='no-errors'></div>"
    error_items = []
    g = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {errors, g, :ok}, fn _, {acc_errors, acc_g, acc_state} ->
  if (acc_g < length(acc_errors)) do
    error = errors[g]
    acc_g = acc_g + 1
    error_items = error_items ++ ["<li class='error-item'>" <> error <> "</li>"]
    {:cont, {acc_errors, acc_g, acc_state}}
  else
    {:halt, {acc_errors, acc_g, acc_state}}
  end
end)
    "<div class='form-errors'><ul class='error-list'>" <> Enum.join(error_items, "") <> "</ul></div>"
  end
  defp get_csrf_token() do
    "csrf_token_placeholder"
  end
end