package test.schemas;

import test.support.DataCase;
import server.schemas.Todo;
import ecto.Changeset;
import haxe.ds.Option;

using ecto.Changeset.ChangesetTools;

/**
 * Tests for the Todo schema
 * Validates changeset logic, validations, and field constraints
 */
@:exunit
class TodoTest extends DataCase {
    
    /**
     * Test that valid todo attributes create a valid changeset
     */
    @:test
    public function testValidChangeset(): Void {
        var attrs = {
            title: "Complete project",
            description: "Finish the Haxe→Elixir todo app",
            completed: false,
            priority: "medium",
            due_date: "2025-08-20",
            tags: "work, haxe, elixir"
        };
        
        var changeset: Changeset<Todo> = Todo.changeset(new Todo(), attrs);
        assertValidChangeset(changeset);
    }
    
    /**
     * Test that missing title makes changeset invalid
     */
    @:test
    public function testRequiredTitle(): Void {
        var attrs = {
            description: "Todo without title",
            completed: false
        };
        
        var changeset: Changeset<Todo> = Todo.changeset(new Todo(), attrs);
        assertInvalidChangeset(changeset);
        assertChangesetError(changeset, "title", "can't be blank");
    }
    
    /**
     * Test that empty title makes changeset invalid
     */
    public function testEmptyTitle(): Void {
        var attrs = {
            title: "",
            description: "Todo with empty title",
            completed: false
        };
        
        var changeset = Todo.changeset(Todo.new(), attrs);
        assertInvalidChangeset(changeset);
        assertChangesetError(changeset, "title", "can't be blank");
    }
    
    /**
     * Test that title length validation works
     */
    public function testTitleLength(): Void {
        // Title too long (over 200 characters)
        var longTitle = "";
        for (i in 0...210) {
            longTitle += "a";
        }
        
        var attrs = {
            title: longTitle,
            completed: false
        };
        
        var changeset = Todo.changeset(Todo.new(), attrs);
        assertInvalidChangeset(changeset);
        assertChangesetError(changeset, "title", "should be at most 200 character(s)");
    }
    
    /**
     * Test that priority validation works
     */
    public function testPriorityValidation(): Void {
        var attrs = {
            title: "Test todo",
            priority: "invalid_priority",
            completed: false
        };
        
        var changeset = Todo.changeset(Todo.new(), attrs);
        assertInvalidChangeset(changeset);
        assertChangesetError(changeset, "priority", "is invalid");
    }
    
    /**
     * Test valid priority values
     */
    public function testValidPriorities(): Void {
        var validPriorities = ["low", "medium", "high"];
        
        for (priority in validPriorities) {
            var attrs = {
                title: "Test todo",
                priority: priority,
                completed: false
            };
            
            var changeset = Todo.changeset(Todo.new(), attrs);
            assertValidChangeset(changeset);
        }
    }
    
    /**
     * Test that completed defaults to false
     */
    public function testCompletedDefault(): Void {
        var attrs = {
            title: "Test todo"
        };
        
        var changeset = Todo.changeset(Todo.new(), attrs);
        assertValidChangeset(changeset);
        
        var completed = getChangesetValue(changeset, "completed");
        assertEqual(false, completed);
    }
    
    /**
     * Test that description is optional
     */
    public function testOptionalDescription(): Void {
        var attrs = {
            title: "Todo without description",
            completed: false
        };
        
        var changeset = Todo.changeset(Todo.new(), attrs);
        assertValidChangeset(changeset);
    }
    
    /**
     * Test that due_date accepts valid dates
     */
    public function testValidDueDate(): Void {
        var attrs = {
            title: "Todo with due date",
            due_date: "2025-12-31",
            completed: false
        };
        
        var changeset = Todo.changeset(Todo.new(), attrs);
        assertValidChangeset(changeset);
    }
    
    /**
     * Test that tags are stored as comma-separated string
     */
    public function testTagsHandling(): Void {
        var attrs = {
            title: "Todo with tags",
            tags: "work, personal, urgent",
            completed: false
        };
        
        var changeset = Todo.changeset(Todo.new(), attrs);
        assertValidChangeset(changeset);
        
        var tags = getChangesetValue(changeset, "tags");
        assertEqual("work, personal, urgent", tags);
    }
    
    /**
     * Helper to assert specific changeset errors
     */
    private function assertChangesetError(changeset: Dynamic, field: String, message: String): Void {
        var errors = getChangesetErrors(changeset);
        var fieldErrors = getFieldErrors(errors, field);
        
        if (!arrayContains(fieldErrors, message)) {
            throw 'Expected changeset to have error "${message}" on field "${field}", but got: ${fieldErrors}';
        }
    }
    
    /**
     * Helper to get value from changeset
     */
    private function getChangesetValue(changeset: Dynamic, field: String): Dynamic {
        var changes = changeset.changes;
        return Reflect.field(changes, field);
    }
    
    /**
     * Helper to get field-specific errors
     */
    private function getFieldErrors(errors: Dynamic, field: String): Array<String> {
        var fieldErrors = Reflect.field(errors, field);
        return fieldErrors != null ? fieldErrors : [];
    }
    
    /**
     * Helper to check if array contains value
     */
    private function arrayContains(array: Array<String>, value: String): Bool {
        for (item in array) {
            if (item == value) return true;
        }
        return false;
    }
    
    /**
     * Helper to assert equality
     */
    private function assertEqual(expected: Dynamic, actual: Dynamic): Void {
        if (expected != actual) {
            throw 'Expected ${expected}, but got ${actual}';
        }
    }
}