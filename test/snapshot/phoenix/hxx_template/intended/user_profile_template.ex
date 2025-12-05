defmodule UserProfileTemplate do
  def render_profile(user) do
    "<div class='user-profile'><h1>#{(fn -> user.name end).()}</h1><p>Age: #{(fn -> Kernel.to_string(user.age) end).()}</p></div>"
  end
  def render_with_condition(user) do
    badge = if (user.is_admin), do: "Admin", else: "User"
    "<div class='user-info'><h2>#{(fn -> user.name end).()}</h2><span class='badge'>#{(fn -> badge end).()}</span></div>"
  end
  def render_user_list(users) do
    items = []
    Enum.each(users, (fn -> fn item ->
            item = Enum.concat(item, ["<li><strong>" <> item.name <> "</strong> - " <> item.email <> "</li>"])
    end end).())
    "<ul class='user-list'>#{(fn -> Enum.join((fn -> items end).(), "") end).()}</ul>"
  end
  def render_complex_layout(title, content) do
    "<!DOCTYPE html><html><head><title>#{(fn -> title end).()}</title></head><body><h1>#{(fn -> title end).()}</h1><main>#{(fn -> content end).()}</main></body></html>"
  end
end
