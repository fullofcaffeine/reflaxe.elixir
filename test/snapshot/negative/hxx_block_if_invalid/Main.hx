package;

import HXX;

// Assigns structure used by render(assigns)
typedef Assigns = {
  var show_form: Bool; // valid field
}

class Main {
  // Intentionally references an unknown assigns field in an HXX inline expression
  // to mirror a block-if style conditional. This MUST fail at Haxe compile time.
  public static function render(assigns: Assigns): String {
    // Use HXX block-if with an unknown assigns field; this must fail type-checking
    return HXX.hxx('<div>\n      <if {assigns.show_forma}>\n        <p>FORM</p>\n      </if>\n      <!-- Force compile-time type check via inline expression as well -->\n      <p>${assigns.show_forma ? "on" : "off"}</p>\n    </div>');
  }

  public static function main() {}
}
