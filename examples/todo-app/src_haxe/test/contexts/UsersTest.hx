package test.contexts;

import test.support.DataCase;
import server.contexts.Users;
import server.schemas.Todo;

/**
 * Tests for the Users context
 * Validates todo management functions and business logic
 */
@:exunit
class UsersTest extends DataCase {
    
    /**
     * Test creating a todo with valid attributes
     */
    public function testCreateTodo(): Void {
        var attrs = {
            title: "Test todo",
            description: "A test todo item",
            completed: false,
            priority: "medium"
        };
        
        var result = Users.createTodo(attrs);
        
        assertOkTuple(result);
        var todo = getTupleValue(result);
        assertEqual("Test todo", todo.title);
        assertEqual("A test todo item", todo.description);
        assertEqual(false, todo.completed);
        assertEqual("medium", todo.priority);
        assertNotNull(todo.id);
    }
    
    /**
     * Test creating a todo with invalid attributes
     */
    public function testCreateTodoWithInvalidAttributes(): Void {
        var attrs = {
            title: "", // Invalid: empty title
            completed: false
        };
        
        var result = Users.createTodo(attrs);
        
        assertErrorTuple(result);
        var changeset = getTupleValue(result);
        assertInvalidChangeset(changeset);
    }
    
    /**
     * Test listing all todos
     */
    public function testListTodos(): Void {
        // Create test todos
        createTestTodo("First todo", false, "high");
        createTestTodo("Second todo", true, "low");
        createTestTodo("Third todo", false, "medium");
        
        var todos = Users.listTodos();
        
        assertTrue(isArray(todos));
        assertEqual(3, arrayLength(todos));
    }
    
    /**
     * Test getting a specific todo by ID
     */
    public function testGetTodo(): Void {
        var createdTodo = createTestTodo("Get me", false, "high");
        
        var result = Users.getTodo(createdTodo.id);
        
        assertNotNull(result);
        assertEqual(createdTodo.id, result.id);
        assertEqual("Get me", result.title);
        assertEqual("high", result.priority);
    }
    
    /**
     * Test getting a non-existent todo returns null
     */
    public function testGetNonExistentTodo(): Void {
        var result = Users.getTodo(999999);
        assertNull(result);
    }
    
    /**
     * Test updating a todo with valid attributes
     */
    public function testUpdateTodo(): Void {
        var todo = createTestTodo("Original title", false, "low");
        
        var updateAttrs = {
            title: "Updated title",
            completed: true,
            priority: "high"
        };
        
        var result = Users.updateTodo(todo, updateAttrs);
        
        assertOkTuple(result);
        var updatedTodo = getTupleValue(result);
        assertEqual("Updated title", updatedTodo.title);
        assertEqual(true, updatedTodo.completed);
        assertEqual("high", updatedTodo.priority);
    }
    
    /**
     * Test updating a todo with invalid attributes
     */
    public function testUpdateTodoWithInvalidAttributes(): Void {
        var todo = createTestTodo("Valid todo", false, "medium");
        
        var updateAttrs = {
            title: "", // Invalid: empty title
            priority: "invalid_priority" // Invalid priority
        };
        
        var result = Users.updateTodo(todo, updateAttrs);
        
        assertErrorTuple(result);
        var changeset = getTupleValue(result);
        assertInvalidChangeset(changeset);
    }
    
    /**
     * Test deleting a todo
     */
    public function testDeleteTodo(): Void {
        var todo = createTestTodo("Delete me", false, "low");
        
        var result = Users.deleteTodo(todo);
        
        assertOkTuple(result);
        var deletedTodo = getTupleValue(result);
        assertEqual(todo.id, deletedTodo.id);
        
        // Verify todo is actually deleted
        var getTodo = Users.getTodo(todo.id);
        assertNull(getTodo);
    }
    
    /**
     * Test filtering todos by completion status
     */
    public function testFilterTodosByCompletion(): Void {
        createTestTodo("Completed todo", true, "high");
        createTestTodo("Pending todo 1", false, "medium");
        createTestTodo("Pending todo 2", false, "low");
        
        var completedTodos = Users.filterTodos("completed");
        var activeTodos = Users.filterTodos("active");
        var allTodos = Users.filterTodos("all");
        
        assertEqual(1, arrayLength(completedTodos));
        assertEqual(2, arrayLength(activeTodos));
        assertEqual(3, arrayLength(allTodos));
    }
    
    /**
     * Test sorting todos by priority
     */
    public function testSortTodosByPriority(): Void {
        createTestTodo("Low priority", false, "low");
        createTestTodo("High priority", false, "high");
        createTestTodo("Medium priority", false, "medium");
        
        var sortedTodos = Users.sortTodos("priority");
        
        assertEqual(3, arrayLength(sortedTodos));
        assertEqual("high", sortedTodos[0].priority);
        assertEqual("medium", sortedTodos[1].priority);
        assertEqual("low", sortedTodos[2].priority);
    }
    
    /**
     * Test searching todos by title
     */
    public function testSearchTodos(): Void {
        createTestTodo("Work on project", false, "high");
        createTestTodo("Buy groceries", false, "low");
        createTestTodo("Work meeting", false, "medium");
        
        var workTodos = Users.searchTodos("work");
        var buyTodos = Users.searchTodos("buy");
        
        assertEqual(2, arrayLength(workTodos));
        assertEqual(1, arrayLength(buyTodos));
    }
    
    /**
     * Test bulk operations on todos
     */
    public function testBulkCompleteAllTodos(): Void {
        createTestTodo("Todo 1", false, "high");
        createTestTodo("Todo 2", false, "medium");
        createTestTodo("Todo 3", true, "low"); // Already completed
        
        var result = Users.bulkCompleteAllTodos();
        
        assertEqual(2, result); // Should update 2 todos
        
        var allTodos = Users.listTodos();
        for (todo in allTodos) {
            assertTrue(todo.completed);
        }
    }
    
    /**
     * Test deleting completed todos
     */
    public function testDeleteCompletedTodos(): Void {
        createTestTodo("Active todo", false, "high");
        createTestTodo("Completed todo 1", true, "medium");
        createTestTodo("Completed todo 2", true, "low");
        
        var result = Users.deleteCompletedTodos();
        
        assertEqual(2, result); // Should delete 2 todos
        
        var remainingTodos = Users.listTodos();
        assertEqual(1, arrayLength(remainingTodos));
        assertEqual(false, remainingTodos[0].completed);
    }
    
    // Helper methods
    
    /**
     * Create a test todo with given attributes
     */
    private function createTestTodo(title: String, completed: Bool, priority: String): Dynamic {
        var attrs = {
            title: title,
            completed: completed,
            priority: priority
        };
        
        var result = Users.createTodo(attrs);
        assertOkTuple(result);
        return getTupleValue(result);
    }
    
    /**
     * Assert that result is an {:ok, value} tuple
     */
    private function assertOkTuple(result: Dynamic): Void {
        if (!isOkTuple(result)) {
            throw 'Expected {:ok, value} tuple, but got: ${result}';
        }
    }
    
    /**
     * Assert that result is an {:error, value} tuple
     */
    private function assertErrorTuple(result: Dynamic): Void {
        if (!isErrorTuple(result)) {
            throw 'Expected {:error, value} tuple, but got: ${result}';
        }
    }
    
    /**
     * Check if result is an {:ok, value} tuple
     */
    private function isOkTuple(result: Dynamic): Bool {
        return result.atom == "ok";
    }
    
    /**
     * Check if result is an {:error, value} tuple
     */
    private function isErrorTuple(result: Dynamic): Bool {
        return result.atom == "error";
    }
    
    /**
     * Get the value from a tuple
     */
    private function getTupleValue(tuple: Dynamic): Dynamic {
        return tuple.value;
    }
    
    /**
     * Check if value is an array
     */
    private function isArray(value: Dynamic): Bool {
        return Std.isOfType(value, Array);
    }
    
    /**
     * Get array length
     */
    private function arrayLength(array: Array<Dynamic>): Int {
        return array.length;
    }
    
    /**
     * Assert equality
     */
    private function assertEqual(expected: Dynamic, actual: Dynamic): Void {
        if (expected != actual) {
            throw 'Expected ${expected}, but got ${actual}';
        }
    }
    
    /**
     * Assert not null
     */
    private function assertNotNull(value: Dynamic): Void {
        if (value == null) {
            throw "Expected value to not be null";
        }
    }
    
    /**
     * Assert null
     */
    private function assertNull(value: Dynamic): Void {
        if (value != null) {
            throw 'Expected value to be null, but got: ${value}';
        }
    }
    
    /**
     * Assert true
     */
    private function assertTrue(value: Bool): Void {
        if (!value) {
            throw "Expected value to be true";
        }
    }
}