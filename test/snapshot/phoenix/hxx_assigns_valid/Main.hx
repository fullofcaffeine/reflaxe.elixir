package;

import HXX;

typedef Assigns = {
  var completed_todos: Int;
  var show_form: Bool;
}

class Main {
  public static function render(assigns: Assigns): String {
    return HXX.hxx('<div>
      <p><%= @completed_todos == 0 %></p>
      <p><%= @show_form == true %></p>
    </div>');
  }

  public static function main() {}
}

