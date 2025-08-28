package;

/**
 * Regression test for orphaned enum parameter extraction
 * 
 * This test ensures that the compiler correctly handles enum parameter
 * extraction in switch statements, particularly when cases have empty
 * bodies or fall-through behavior that results in orphaned TLocal references.
 * 
 * See: docs/03-compiler-development/ENUM_PARAMETER_EXTRACTION.md
 */
class Main {
    static function main() {
        // Test 1: Basic enum with parameters
        testBasicEnum();
        
        // Test 2: Multiple parameter extraction
        testMultipleParameters();
        
        // Test 3: Empty case bodies (primary issue case)
        testEmptyCases();
        
        // Test 4: Fall-through patterns
        testFallThrough();
        
        // Test 5: Nested enum patterns
        testNestedEnums();
        
        // Test 6: Mixed parameter and non-parameter cases
        testMixedCases();
    }
    
    static function testBasicEnum() {
        var msg = Message.Created("item");
        
        switch(msg) {
            case Created(content):
                trace('Created: $content');
            case Updated(id, content):
                trace('Updated $id: $content');
            case Deleted(id):
                trace('Deleted: $id');
            case Empty:
                trace('Empty message');
        }
    }
    
    static function testMultipleParameters() {
        var action = Action.Move(10, 20, 30);
        
        switch(action) {
            case Move(x, y, z):
                trace('Moving to ($x, $y, $z)');
            case Rotate(angle, axis):
                trace('Rotating $angle degrees on $axis');
            case Scale(factor):
                trace('Scaling by $factor');
        }
    }
    
    static function testEmptyCases() {
        // This is the problematic pattern that causes orphaned _g variables
        var event = Event.Click(100, 200);
        
        switch(event) {
            case Click(x, y):
                // Empty body - this creates orphaned TLocal(_g)
            case Hover(x, y):
                // Another empty body
            case KeyPress(key):
                // Yet another empty body
        }
        
        // Should compile without undefined variable errors
        trace("Empty cases handled");
    }
    
    static function testFallThrough() {
        var state = State.Loading(50);
        var description = "";
        
        switch(state) {
            case Loading(progress):
                // Fall through pattern
            case Processing(progress):
                description = 'Progress: $progress%';
            case Complete(result):
                description = 'Done: $result';
            case Error(msg):
                description = 'Error: $msg';
        }
        
        trace(description);
    }
    
    static function testNestedEnums() {
        var container = Container.Box(Content.Text("Hello"));
        
        switch(container) {
            case Box(content):
                switch(content) {
                    case Text(str):
                        trace('Box contains text: $str');
                    case Number(n):
                        trace('Box contains number: $n');
                    case Empty:
                        trace('Box is empty');
                }
            case List(items):
                trace('List with ${items.length} items');
            case Empty:
                trace('Container is empty');
        }
    }
    
    static function testMixedCases() {
        var result: Result = Result.Success("Done", 42);
        
        switch(result) {
            case Success(msg, code):
                trace('Success: $msg (code: $code)');
            case Warning(msg):
                // Empty body for warning
            case Error(msg, code):
                trace('Error: $msg (code: $code)');
            case Pending:
                trace('Still pending...');
        }
    }
}

// Test enums with various parameter configurations

enum Message {
    Created(content: String);
    Updated(id: Int, content: String);
    Deleted(id: Int);
    Empty;
}

enum Action {
    Move(x: Float, y: Float, z: Float);
    Rotate(angle: Float, axis: String);
    Scale(factor: Float);
}

enum Event {
    Click(x: Int, y: Int);
    Hover(x: Int, y: Int);
    KeyPress(key: String);
}

enum State {
    Loading(progress: Int);
    Processing(progress: Int);
    Complete(result: String);
    Error(message: String);
}

enum Content {
    Text(value: String);
    Number(value: Float);
    Empty;
}

enum Container {
    Box(content: Content);
    List(items: Array<Content>);
    Empty;
}

enum Result {
    Success(message: String, code: Int);
    Warning(message: String);
    Error(message: String, code: Int);
    Pending;
}