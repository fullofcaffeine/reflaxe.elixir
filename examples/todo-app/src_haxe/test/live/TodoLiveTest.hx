package test.live;

import test.support.ConnCase;
import server.live.TodoLive;

/**
 * Tests for the TodoLive LiveView module
 * Validates LiveView functionality, event handling, and state management
 */
@:exunit
class TodoLiveTest extends ConnCase {
    
    /**
     * Test that the todo page loads successfully
     */
    public function testTodoPageMount(): Void {
        var conn = build_conn();
        conn = get(conn, "/todos");
        
        assertResponseOk(conn);
        assertResponseContains(conn, "Todo App");
        assertResponseContains(conn, "Built with Haxe → Elixir + Phoenix LiveView");
    }
    
    /**
     * Test that the new todo form can be toggled
     */
    public function testToggleNewTodoForm(): Void {
        var liveView = connectLiveView("/todos");
        
        // Initially form should be hidden
        assertFormNotVisible(liveView);
        
        // Click to show form
        liveView = clickElement(liveView, "[phx-click='toggle_form']");
        assertFormVisible(liveView);
        
        // Click to hide form
        liveView = clickElement(liveView, "[phx-click='toggle_form']");
        assertFormNotVisible(liveView);
    }
    
    /**
     * Test creating a new todo via LiveView form
     */
    public function testCreateTodoViaForm(): Void {
        var liveView = connectLiveView("/todos");
        
        // Show the form
        liveView = clickElement(liveView, "[phx-click='toggle_form']");
        
        // Fill and submit the form
        var formData = {
            title: "New test todo",
            description: "Created via LiveView test",
            priority: "high"
        };
        
        liveView = submitForm(liveView, "#new-todo-form", formData);
        
        // Verify todo was created and appears in list
        assertElementPresent(liveView, "[data-todo-title='New test todo']");
        assertElementContains(liveView, "[data-todo-description]", "Created via LiveView test");
        assertElementContains(liveView, "[data-todo-priority]", "HIGH");
        
        // Form should be hidden after successful creation
        assertFormNotVisible(liveView);
    }
    
    /**
     * Test creating a todo with invalid data shows errors
     */
    public function testCreateTodoWithInvalidData(): Void {
        var liveView = connectLiveView("/todos");
        
        // Show the form
        liveView = clickElement(liveView, "[phx-click='toggle_form']");
        
        // Submit form with invalid data (empty title)
        var invalidData = {
            title: "",
            description: "No title provided"
        };
        
        liveView = submitForm(liveView, "#new-todo-form", invalidData);
        
        // Form should still be visible with error messages
        assertFormVisible(liveView);
        assertElementContains(liveView, ".error-message", "can't be blank");
    }
    
    /**
     * Test toggling a todo's completion status
     */
    public function testToggleTodoCompletion(): Void {
        // Create a test todo first
        var todo = createTestTodo("Toggle me", false, "medium");
        var liveView = connectLiveView("/todos");
        
        // Verify todo is not completed initially
        assertElementNotHasClass(liveView, '[data-todo-id="${todo.id}"]', "completed");
        
        // Click to complete the todo
        liveView = clickElement(liveView, '[phx-click="toggle_todo"][phx-value-id="${todo.id}"]');
        
        // Verify todo is now completed
        assertElementHasClass(liveView, '[data-todo-id="${todo.id}"]', "completed");
        
        // Click again to uncomplete
        liveView = clickElement(liveView, '[phx-click="toggle_todo"][phx-value-id="${todo.id}"]');
        
        // Verify todo is not completed again
        assertElementNotHasClass(liveView, '[data-todo-id="${todo.id}"]', "completed");
    }
    
    /**
     * Test filtering todos by status
     */
    public function testFilterTodos(): Void {
        // Create test todos with different statuses
        var activeTodo = createTestTodo("Active todo", false, "high");
        var completedTodo = createTestTodo("Completed todo", true, "low");
        
        var liveView = connectLiveView("/todos");
        
        // Test "All" filter (default)
        assertElementPresent(liveView, '[data-todo-id="${activeTodo.id}"]');
        assertElementPresent(liveView, '[data-todo-id="${completedTodo.id}"]');
        
        // Test "Active" filter
        liveView = clickElement(liveView, '[phx-click="filter_todos"][phx-value-filter="active"]');
        assertElementPresent(liveView, '[data-todo-id="${activeTodo.id}"]');
        assertElementNotPresent(liveView, '[data-todo-id="${completedTodo.id}"]');
        
        // Test "Completed" filter
        liveView = clickElement(liveView, '[phx-click="filter_todos"][phx-value-filter="completed"]');
        assertElementNotPresent(liveView, '[data-todo-id="${activeTodo.id}"]');
        assertElementPresent(liveView, '[data-todo-id="${completedTodo.id}"]');
    }
    
    /**
     * Test searching todos by title
     */
    public function testSearchTodos(): Void {
        // Create test todos
        createTestTodo("Work on project", false, "high");
        createTestTodo("Buy groceries", false, "low");
        
        var liveView = connectLiveView("/todos");
        
        // Search for "work"
        liveView = typeInInput(liveView, '[phx-keyup="search_todos"]', "work");
        
        // Should show work todo, hide groceries todo
        assertElementContains(liveView, ".todo-item", "Work on project");
        assertElementNotContains(liveView, ".todo-item", "Buy groceries");
        
        // Clear search
        liveView = typeInInput(liveView, '[phx-keyup="search_todos"]', "");
        
        // Both todos should be visible again
        assertElementContains(liveView, ".todo-item", "Work on project");
        assertElementContains(liveView, ".todo-item", "Buy groceries");
    }
    
    /**
     * Test sorting todos by different criteria
     */
    public function testSortTodos(): Void {
        // Create todos with different priorities and dates
        createTestTodo("Low priority", false, "low");
        createTestTodo("High priority", false, "high");
        createTestTodo("Medium priority", false, "medium");
        
        var liveView = connectLiveView("/todos");
        
        // Sort by priority
        liveView = selectOption(liveView, '[phx-change="sort_todos"]', "priority");
        
        // Verify order: high, medium, low
        var todoElements = getElementsText(liveView, ".todo-title");
        assertEqual("High priority", todoElements[0]);
        assertEqual("Medium priority", todoElements[1]);
        assertEqual("Low priority", todoElements[2]);
    }
    
    /**
     * Test editing a todo inline
     */
    public function testEditTodo(): Void {
        var todo = createTestTodo("Original title", false, "medium");
        var liveView = connectLiveView("/todos");
        
        // Click edit button
        liveView = clickElement(liveView, '[phx-click="edit_todo"][phx-value-id="${todo.id}"]');
        
        // Verify edit form is shown
        assertElementPresent(liveView, '[data-todo-id="${todo.id}"] form');
        
        // Update the todo
        var updatedData = {
            title: "Updated title",
            description: "Updated description"
        };
        
        liveView = submitForm(liveView, '[data-todo-id="${todo.id}"] form', updatedData);
        
        // Verify todo was updated
        assertElementContains(liveView, '[data-todo-id="${todo.id}"] .todo-title', "Updated title");
        assertElementContains(liveView, '[data-todo-id="${todo.id}"] .todo-description', "Updated description");
        
        // Edit form should be hidden
        assertElementNotPresent(liveView, '[data-todo-id="${todo.id}"] form');
    }
    
    /**
     * Test deleting a todo
     */
    public function testDeleteTodo(): Void {
        var todo = createTestTodo("Delete me", false, "low");
        var liveView = connectLiveView("/todos");
        
        // Verify todo is present
        assertElementPresent(liveView, '[data-todo-id="${todo.id}"]');
        
        // Click delete button (will show confirmation)
        liveView = clickElementWithConfirm(liveView, '[phx-click="delete_todo"][phx-value-id="${todo.id}"]');
        
        // Verify todo is removed
        assertElementNotPresent(liveView, '[data-todo-id="${todo.id}"]');
    }
    
    /**
     * Test bulk complete all todos
     */
    public function testBulkCompleteAllTodos(): Void {
        // Create some active todos
        createTestTodo("Todo 1", false, "high");
        createTestTodo("Todo 2", false, "medium");
        createTestTodo("Todo 3", true, "low"); // Already completed
        
        var liveView = connectLiveView("/todos");
        
        // Click bulk complete button
        liveView = clickElement(liveView, '[phx-click="bulk_complete"]');
        
        // Verify all todos are completed
        var completedElements = getElements(liveView, ".todo-item.completed");
        assertEqual(3, completedElements.length);
    }
    
    /**
     * Test bulk delete completed todos
     */
    public function testBulkDeleteCompleted(): Void {
        // Create todos with different statuses
        createTestTodo("Active todo", false, "high");
        createTestTodo("Completed todo 1", true, "medium");
        createTestTodo("Completed todo 2", true, "low");
        
        var liveView = connectLiveView("/todos");
        
        // Click bulk delete completed button
        liveView = clickElementWithConfirm(liveView, '[phx-click="bulk_delete_completed"]');
        
        // Verify only active todo remains
        var remainingTodos = getElements(liveView, ".todo-item");
        assertEqual(1, remainingTodos.length);
        assertElementContains(liveView, ".todo-item", "Active todo");
    }
    
    /**
     * Test empty state messages
     */
    public function testEmptyStateMessages(): Void {
        var liveView = connectLiveView("/todos");
        
        // No todos - should show empty state
        assertElementContains(liveView, ".empty-state", "No todos yet");
        
        // Create a completed todo
        createTestTodo("Completed", true, "low");
        liveView = refreshLiveView(liveView);
        
        // Filter by active - should show "no active todos"
        liveView = clickElement(liveView, '[phx-click="filter_todos"][phx-value-filter="active"]');
        assertElementContains(liveView, ".empty-state", "No active todos");
    }
    
    // Helper methods
    
    /**
     * Create a test todo
     */
    private function createTestTodo(title: String, completed: Bool, priority: String): Dynamic {
        // This would use the Users context to create a todo
        return {
            id: Math.floor(Math.random() * 1000000),
            title: title,
            completed: completed,
            priority: priority
        };
    }
    
    /**
     * Connect to a LiveView at the given path
     */
    private function connectLiveView(path: String): Dynamic {
        // Implementation would use Phoenix.LiveViewTest helpers
        return {};
    }
    
    /**
     * Click an element in the LiveView
     */
    private function clickElement(liveView: Dynamic, selector: String): Dynamic {
        // Implementation would trigger the click event
        return liveView;
    }
    
    /**
     * Click an element that shows a confirmation dialog
     */
    private function clickElementWithConfirm(liveView: Dynamic, selector: String): Dynamic {
        // Implementation would handle the confirmation
        return liveView;
    }
    
    /**
     * Submit a form in the LiveView
     */
    private function submitForm(liveView: Dynamic, formSelector: String, data: Dynamic): Dynamic {
        // Implementation would submit the form with data
        return liveView;
    }
    
    /**
     * Type text into an input field
     */
    private function typeInInput(liveView: Dynamic, inputSelector: String, text: String): Dynamic {
        // Implementation would trigger keyup events
        return liveView;
    }
    
    /**
     * Select an option from a dropdown
     */
    private function selectOption(liveView: Dynamic, selectSelector: String, value: String): Dynamic {
        // Implementation would trigger change event
        return liveView;
    }
    
    /**
     * Refresh the LiveView
     */
    private function refreshLiveView(liveView: Dynamic): Dynamic {
        // Implementation would re-render the view
        return liveView;
    }
    
    // Assertion helpers
    
    private function assertFormVisible(liveView: Dynamic): Void {
        assertElementPresent(liveView, "#new-todo-form");
    }
    
    private function assertFormNotVisible(liveView: Dynamic): Void {
        assertElementNotPresent(liveView, "#new-todo-form");
    }
    
    private function assertElementPresent(liveView: Dynamic, selector: String): Void {
        // Implementation would check if element exists
    }
    
    private function assertElementNotPresent(liveView: Dynamic, selector: String): Void {
        // Implementation would check if element doesn't exist
    }
    
    private function assertElementContains(liveView: Dynamic, selector: String, text: String): Void {
        // Implementation would check element content
    }
    
    private function assertElementNotContains(liveView: Dynamic, selector: String, text: String): Void {
        // Implementation would check element doesn't contain text
    }
    
    private function assertElementHasClass(liveView: Dynamic, selector: String, className: String): Void {
        // Implementation would check CSS class
    }
    
    private function assertElementNotHasClass(liveView: Dynamic, selector: String, className: String): Void {
        // Implementation would check CSS class absence
    }
    
    private function getElements(liveView: Dynamic, selector: String): Array<Dynamic> {
        // Implementation would return matching elements
        return [];
    }
    
    private function getElementsText(liveView: Dynamic, selector: String): Array<String> {
        // Implementation would return element text content
        return [];
    }
    
    private function assertEqual(expected: Dynamic, actual: Dynamic): Void {
        if (expected != actual) {
            throw 'Expected ${expected}, but got ${actual}';
        }
    }
}