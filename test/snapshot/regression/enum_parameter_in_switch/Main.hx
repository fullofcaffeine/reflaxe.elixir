enum Msg {
  TodoCreated(todo: String);
  TodoUpdated(todo: String);
}

class Main {
  static function payload(m: Msg): Dynamic {
    return switch (m) {
      case TodoCreated(todo): { type: "todo_created", todo: todo };
      case TodoUpdated(todo): { type: "todo_updated", todo: todo };
    }
  }

  public static function main() {
    var p = payload(TodoCreated("X"));
    trace(p);
  }
}

