package;

import HXX;

typedef Assigns = {
  sort_by: String,
  count: Int,
  active: Bool
}

class Main {
  public static function render(assigns: Assigns): String {
    // Intentionally invalid usages to trigger HeexAssignsTypeLinter errors:
    // 1) Unknown assigns field: @srot_by (typo)
    // 2) Type mismatch: @sort_by == 1 (String compared to Int literal)
    return HXX.hxx('<div>\n      <p>Sort by is: ${assigns.srot_by}</p>\n      <p selected={if @active, do: "yes", else: "no"}>Active?</p>\n      <p><%= if @sort_by == 1 do %>Wrong Type<% else %>OK<% end %></p>\n    </div>');
  }

  public static function main() {}
}
