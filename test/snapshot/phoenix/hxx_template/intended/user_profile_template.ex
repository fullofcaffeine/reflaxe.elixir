defmodule UserProfileTemplate do
  def render_profile(user) do
    "<div class='user-profile'><h1>#{user.name}</h1><p>Age: #{user.age}</p></div>"
  end
  def render_with_condition(user) do
    badge = if user.isAdmin, do: "Admin", else: "User"
    "<div class='user-info'><h2>#{user.name}</h2><span class='badge'>#{badge}</span></div>"
  end
  def render_user_list(users) do
    items = []
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {users}, fn _, {users} ->
  if 0 < length(users) do
    user = users[0]
    0 + 1
    items.push("<li><strong>" <> user.name <> "</strong> - " <> user.email <> "</li>")
    {:cont, {users}}
  else
    {:halt, {users}}
  end
end)
    "<ul class='user-list'>#{Enum.join(items, "")}</ul>"
  end
  def render_complex_layout(title, content) do
    "<!DOCTYPE html><html><head><title>#{title}</title></head><body><h1>#{title}</h1><main>#{content}</main></body></html>"
  end
end