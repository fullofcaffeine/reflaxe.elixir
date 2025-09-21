/**
 * Test for idiomatic enum pattern compilation
 *
 * This test ensures that enum patterns compile to idiomatic Elixir
 * with proper atom tags and direct pattern matching, similar to
 * the patterns used in Phoenix PubSub messages.
 */

enum TodoMessage {
    TodoCreated(todo: Dynamic);
    TodoUpdated(todo: Dynamic);
    TodoDeleted(id: Int);
    BulkUpdate(action: String);
    UserOnline(userId: Int);
    UserOffline(userId: Int);
    SystemAlert(message: String, level: String);
}

enum BulkAction {
    CompleteAll;
    DeleteCompleted;
    SetPriority(priority: String);
    AddTag(tag: String);
    RemoveTag(tag: String);
}

class Main {
    static function main() {
        testMessageConversion();
        testBulkActionToString();
        testNestedEnumPatterns();
    }

    // Similar to TodoPubSub.message_to_elixir
    static function messageToElixir(message: TodoMessage): Dynamic {
        var basePayload: Dynamic = switch(message) {
            case TodoCreated(todo):
                untyped {type: "todo_created", todo: todo};
            case TodoUpdated(todo):
                untyped {type: "todo_updated", todo: todo};
            case TodoDeleted(id):
                untyped {type: "todo_deleted", todoId: id};
            case BulkUpdate(action):
                untyped {type: "bulk_update", action: action};
            case UserOnline(userId):
                untyped {type: "user_online", userId: userId};
            case UserOffline(userId):
                untyped {type: "user_offline", userId: userId};
            case SystemAlert(message, level):
                untyped {type: "system_alert", message: message, level: level};
        };
        return addTimestamp(basePayload);
    }

    // Test bulk action conversion
    static function bulkActionToString(action: BulkAction): String {
        return switch(action) {
            case CompleteAll: "complete_all";
            case DeleteCompleted: "delete_completed";
            case SetPriority(priority): 'set_priority:$priority';
            case AddTag(tag): 'add_tag:$tag';
            case RemoveTag(tag): 'remove_tag:$tag';
        };
    }

    // Test nested enum patterns
    static function processComplexMessage(msg: TodoMessage): String {
        return switch(msg) {
            case BulkUpdate(action):
                var actionStr = switch(parseBulkAction(action)) {
                    case CompleteAll: "Completing all todos";
                    case DeleteCompleted: "Deleting completed todos";
                    case SetPriority(p): 'Setting priority to $p';
                    case AddTag(t): 'Adding tag: $t';
                    case RemoveTag(t): 'Removing tag: $t';
                };
                'Bulk operation: $actionStr';
            case TodoCreated(todo): 'New todo created';
            case TodoUpdated(todo): 'Todo updated';
            case TodoDeleted(id): 'Todo $id deleted';
            case UserOnline(userId): 'User $userId is online';
            case UserOffline(userId): 'User $userId is offline';
            case SystemAlert(msg, level): '$level: $msg';
        };
    }

    // Helper functions
    static function addTimestamp(payload: Dynamic): Dynamic {
        // Simulated timestamp addition
        return payload;
    }

    static function parseBulkAction(action: String): BulkAction {
        return switch(action) {
            case "complete_all": CompleteAll;
            case "delete_completed": DeleteCompleted;
            case str if (str.indexOf("set_priority:") == 0):
                SetPriority(str.substr(13));
            case str if (str.indexOf("add_tag:") == 0):
                AddTag(str.substr(8));
            case str if (str.indexOf("remove_tag:") == 0):
                RemoveTag(str.substr(11));
            case _: CompleteAll; // Default
        };
    }

    // Test functions
    static function testMessageConversion(): Void {
        var msg1 = TodoCreated({id: 1, title: "Test"});
        var msg2 = TodoDeleted(42);
        var msg3 = SystemAlert("Server restarting", "warning");

        var payload1 = messageToElixir(msg1);
        var payload2 = messageToElixir(msg2);
        var payload3 = messageToElixir(msg3);

        trace('Message conversions completed');
    }

    static function testBulkActionToString(): Void {
        var action1 = CompleteAll;
        var action2 = SetPriority("high");
        var action3 = AddTag("urgent");

        var str1 = bulkActionToString(action1);
        var str2 = bulkActionToString(action2);
        var str3 = bulkActionToString(action3);

        trace('Actions: $str1, $str2, $str3');
    }

    static function testNestedEnumPatterns(): Void {
        var msg1 = BulkUpdate("complete_all");
        var msg2 = BulkUpdate("set_priority:high");
        var msg3 = UserOnline(123);

        var result1 = processComplexMessage(msg1);
        var result2 = processComplexMessage(msg2);
        var result3 = processComplexMessage(msg3);

        trace('Results: $result1, $result2, $result3');
    }
}