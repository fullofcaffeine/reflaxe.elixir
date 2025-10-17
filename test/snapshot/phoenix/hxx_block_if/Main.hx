package;

import HXX;

typedef Assigns = {
  show_form: Bool,
  current_user: { name: String },
  total_todos: Int,
  completed_todos: Int,
  pending_todos: Int
}

class Main {
  public static function render(assigns: Assigns): String {
    var content = HXX.hxx('
      <div>
        <p>Welcome, ${assigns.current_user.name}!</p>
        <div class="stats">
          <span>${assigns.total_todos}</span>
          <span>${assigns.completed_todos}</span>
          <span>${assigns.pending_todos}</span>
        </div>
        ${assigns.show_form ? HXX.block('<div id="form">FORM</div>') : ""}
      </div>
    ');
    return untyped __elixir__('~H"""\n<%= Phoenix.HTML.raw(content) %>\n"""');
  }

  public static function main() {}
}
