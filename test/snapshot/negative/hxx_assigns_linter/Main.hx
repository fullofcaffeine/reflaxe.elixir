package;

import HXX;

// Assigns structure used by render(assigns)
typedef Assigns = {
  var sort_by: String;
  var total: Int;
}

class Main {
  // Intentionally contains template errors:
  // 1) Unknown assigns field @sort_byy
  // 2) Type mismatch: @sort_by (String) compared to Int literal 1
  public static function render(assigns: Assigns): String {
    return HXX.hxx('<div>
      <p>Unknown field raw HEEx: <%= @sort_byy %></p>
      <p>Type mismatch raw HEEx: <%= @sort_by == 1 %></p>
      <p>HXX expr unknown assigns: ${assigns.sort_byy ? "on" : "off"}</p>
    </div>');
  }

  public static function main() {}
}

