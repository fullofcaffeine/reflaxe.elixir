package;

enum Option<T> {
  Some(value:T);
  None;
}

class Main {
  static function parseAlertLevel(level:String):Option<String> {
    return switch (level) {
      case "info" | "warning" | "error" | "critical": Some(level);
      case _: None;
    }
  }

  static function parseMessage(msg:Dynamic):Option<{message:String, level:String}> {
    return if (msg.message != null && msg.level != null) {
      var alertLevel = parseAlertLevel(msg.level);
      switch (alertLevel) {
        case Some(level): Some({message: msg.message, level: level});
        case None: None;
      }
    } else None;
  }
}

