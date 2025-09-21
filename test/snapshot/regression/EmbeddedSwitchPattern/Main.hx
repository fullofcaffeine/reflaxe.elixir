package;

// Test for embedded switch patterns in if expressions
// This reproduces the TodoPubSub issue where patterns use 'g' but bodies reference undefined variables

enum BulkAction {
    CompleteAll;
    DeleteCompleted;
    SetPriority(priority: String);
}

enum Message {
    BulkUpdate(action: BulkAction);
    SystemAlert(message: String, level: String);
}

enum Option<T> {
    Some(value: T);
    None;
}

class Main {
    static function parseBulkAction(action: String): Option<BulkAction> {
        return switch(action) {
            case "complete_all": Some(CompleteAll);
            case "delete_completed": Some(DeleteCompleted);
            case "set_priority": Some(SetPriority("high"));
            case _: None;
        };
    }

    static function parseAlertLevel(level: String): Option<String> {
        return switch(level) {
            case "info" | "warning" | "error" | "critical": Some(level);
            case _: None;
        };
    }

    static function parseMessage(type: String, msg: Dynamic): Option<Message> {
        // This reproduces the embedded switch pattern from TodoPubSub
        return switch(type) {
            case "bulk_update":
                if (msg.action != null) {
                    var bulkAction = parseBulkAction(msg.action);
                    switch (bulkAction) {
                        case Some(action): Some(BulkUpdate(action));
                        case None: None;
                    }
                } else None;

            case "system_alert":
                if (msg.message != null && msg.level != null) {
                    var alertLevel = parseAlertLevel(msg.level);
                    switch (alertLevel) {
                        case Some(level): Some(SystemAlert(msg.message, level));
                        case None: None;
                    }
                } else None;

            case _:
                None;
        };
    }

    public static function main() {
        // Test bulk_update case
        var msg1 = {action: "complete_all", message: null, level: null};
        var result1 = parseMessage("bulk_update", msg1);
        trace(result1);

        // Test system_alert case
        var msg2 = {action: null, message: "System maintenance", level: "info"};
        var result2 = parseMessage("system_alert", msg2);
        trace(result2);

        // Test none case
        var msg3 = {action: null, message: null, level: null};
        var result3 = parseMessage("unknown", msg3);
        trace(result3);
    }
}