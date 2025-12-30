defmodule UserProfileTemplate do
  def render_profile(user) do
    "<div class='user-profile'><h1>#{user.name}</h1><p>Age: #{Kernel.to_string(user.age)}</p></div>"
  end
  def render_with_condition(user) do
    badge = if (user.is_admin), do: "Admin", else: "User"
    "<div class='user-info'><h2>#{user.name}</h2><span class='badge'>#{badge}</span></div>"
  end
  def render_user_list(users) do
    items = []
    _g = 0
    items = Enum.reduce(users, items, fn user, items_acc -> Enum.concat(items_acc, ["<li><strong>" <> user.name <> "</strong> - " <> user.email <> "</li>"]) end)
    "<ul class='user-list'>#{Enum.join(items, "")}</ul>"
  end
  def render_complex_layout(title, content) do
    "<!DOCTYPE html><html><head><title>#{title}</title></head><body><h1>#{title}</h1><main>#{content}</main></body></html>"
  end
end
