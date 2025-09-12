defmodule UserProfileTemplate do
  def render_profile(user) do
    "<div class='user-profile'><h1>" <> user.name <> "</h1><p>Age: " <> Kernel.to_string(user.age) <> "</p></div>"
  end
  def render_with_condition(user) do
    "<div class='user-info'><h2>" <> user.name <> "</h2><span class='badge'>" <> (if (user.is_admin), do: "Admin", else: "User") <> "</span></div>"
  end
  def render_user_list(users) do
    items = []
    g = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {users, g, :ok}, fn _, {acc_users, acc_g, acc_state} ->
  if (acc_g < length(acc_users)) do
    user = users[g]
    acc_g = acc_g + 1
    items = items ++ ["<li><strong>" <> user.name <> "</strong> - " <> user.email <> "</li>"]
    {:cont, {acc_users, acc_g, acc_state}}
  else
    {:halt, {acc_users, acc_g, acc_state}}
  end
end)
    "<ul class='user-list'>" <> Enum.join(items, "") <> "</ul>"
  end
  def render_complex_layout(title, content) do
    "<!DOCTYPE html><html><head><title>" <> title <> "</title></head><body><h1>" <> title <> "</h1><main>" <> content <> "</main></body></html>"
  end
end