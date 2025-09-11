/**
 * REGRESSION TEST: Enum Constructor Snake_Case Conversion
 * 
 * BUG HISTORY: Found January 2025 in todo-app
 * - Enum constructors like `TodoUpdates` were incorrectly converted to `:todoupdates`
 * - Should have been `:todo_updates` for idiomatic Elixir
 * - Fixed by using ElixirAtom abstract type for automatic snake_case conversion
 * 
 * COMMIT: edcb270e (reserved keywords fix)
 * RELATED: src/reflaxe/elixir/ast/naming/ElixirAtom.hx
 * 
 * This test ensures multi-word enum constructors are properly converted to snake_case atoms
 * in generated Elixir pattern matching code.
 */

// Test enum with multi-word constructors (like PubSub topics)
enum PubSubTopic {
    TodoUpdates;           // Should become :todo_updates
    UserActivity;          // Should become :user_activity 
    SystemNotifications;   // Should become :system_notifications
    HTTPServerStart;       // Should become :http_server_start
    IOManagerReady;        // Should become :io_manager_ready
}

// Test enum with parameters (like PubSub messages)
enum PubSubMessage {
    TodoCreated(todo: Dynamic);           // Should become :todo_created
    TodoUpdated(todo: Dynamic);           // Should become :todo_updated
    TodoDeleted(id: Int);                 // Should become :todo_deleted
    BulkUpdate(action: String);           // Should become :bulk_update
    UserOnline(userId: Int);              // Should become :user_online
    UserOffline(userId: Int);             // Should become :user_offline
    SystemAlert(message: String, level: String);  // Should become :system_alert
}

// Test enum with complex names
enum ComplexNaming {
    XMLHttpRequest;        // Should become :xml_http_request
    JSONAPIResponse;       // Should become :jsonapi_response
    OTPSupervisor;        // Should become :otp_supervisor
    HTTPSConnection;      // Should become :https_connection
    WebSocketIOManager;   // Should become :web_socket_io_manager
}

class Main {
    static function main() {
        // Test topic conversion
        testTopicConversion();
        
        // Test message pattern matching
        testMessagePatterns();
        
        // Test complex naming
        testComplexNames();
    }
    
    static function testTopicConversion() {
        var topic = TodoUpdates;
        
        // Pattern matching should generate snake_case atoms
        var topicString = switch(topic) {
            case TodoUpdates: "todo:updates";
            case UserActivity: "user:activity";
            case SystemNotifications: "system:notifications";
            case HTTPServerStart: "http:server:start";
            case IOManagerReady: "io:manager:ready";
        }
        
        trace('Topic string: $topicString');
    }
    
    static function testMessagePatterns() {
        var message: PubSubMessage = TodoCreated({id: 1, title: "Test"});
        
        // Pattern matching with parameters should also use snake_case
        var result = switch(message) {
            case TodoCreated(todo): 
                'Created todo: $todo';
            case TodoUpdated(todo):
                'Updated todo: $todo';
            case TodoDeleted(id):
                'Deleted todo: $id';
            case BulkUpdate(action):
                'Bulk action: $action';
            case UserOnline(userId):
                'User $userId is online';
            case UserOffline(userId):
                'User $userId is offline';
            case SystemAlert(msg, level):
                'Alert [$level]: $msg';
        }
        
        trace(result);
    }
    
    static function testComplexNames() {
        var request = XMLHttpRequest;
        
        // Complex acronyms should be properly handled
        var description = switch(request) {
            case XMLHttpRequest: "XML HTTP Request";
            case JSONAPIResponse: "JSON API Response";
            case OTPSupervisor: "OTP Supervisor";
            case HTTPSConnection: "HTTPS Connection";
            case WebSocketIOManager: "WebSocket IO Manager";
        }
        
        trace(description);
    }
    
    // Test function that returns enum values (for pattern generation)
    static function getTopicAtom(topic: PubSubTopic): String {
        // This should generate a case statement with snake_case atoms
        return switch(topic) {
            case TodoUpdates: "todo_updates_atom";
            case UserActivity: "user_activity_atom";
            case SystemNotifications: "system_notifications_atom";
            case HTTPServerStart: "http_server_start_atom";
            case IOManagerReady: "io_manager_ready_atom";
        }
    }
}