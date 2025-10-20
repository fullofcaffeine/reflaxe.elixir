package;

import HXX;

typedef Assigns = {
  sort_by: String,
  count: Int,
  active: Bool,
  user: { name: String }
}

class Main {
  public static function render(assigns: Assigns): String {
    // Valid usages the linter should accept
    return HXX.hxx('<div>\n      <p>User: <%= @user.name %></p>\n      <p class={if @active, do: "on", else: "off"}>Status</p>\n      <p><%= if @sort_by == "created_at" do %>Newest<% else %>Other<% end %></p>\n      <span><%= @count %></span>\n    </div>');
  }

  public static function main() {}
}

