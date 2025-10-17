package;

import HXX;

typedef Assigns = {
  current_user: { name: String },
  total_todos: Int
}

class Main {
  public static function render(assigns: Assigns): String {
    return HXX.hxx('<div>Welcome, ${assigns.current_user.name}! (${assigns.total_todos})</div>');
  }

  public static function main() {}
}
