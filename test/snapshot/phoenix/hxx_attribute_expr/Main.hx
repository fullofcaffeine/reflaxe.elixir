package;

import HXX;

typedef Assigns = {
  var sort_by: String;
  var flag: Bool;
}

class Main {
  public static function render(assigns: Assigns): String {
    return HXX.hxx('<div>
      <option value="created" selected=${assigns.sort_by == "created"}></option>
      <div class=${assigns.flag ? "on" : "off"}></div>
    </div>');
  }

  public static function main() {}
}

