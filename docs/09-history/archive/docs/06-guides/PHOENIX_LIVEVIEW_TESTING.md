# Phoenix LiveView Testing Guide for Haxe→Elixir

This comprehensive guide covers testing strategies, patterns, and tools for Phoenix LiveView applications built with Haxe→Elixir compiler.

## 🎯 Testing Philosophy

### Haxe Testing Advantages

**Traditional LiveView Testing Challenges**:
- Runtime type errors in test data
- Fragile string-based selectors
- No compile-time validation of event payloads
- Manual mocking of assigns and params

**✅ Haxe Testing Solutions**:
- **Compile-time test validation** - Invalid tests fail at compile time
- **Type-safe test data** - Test assigns guaranteed to match LiveView expectations
- **Refactoring safety** - Rename fields and tests update automatically
- **Zero test setup errors** - All mocks are type-checked

### Multi-Layer Testing Strategy

```
1. **Unit Tests** (Haxe)          - Individual functions and logic
     ↓
2. **Component Tests** (ExUnit)   - LiveView behavior and state
     ↓  
3. **Integration Tests** (ExUnit) - Full user flows and real-time features
     ↓
4. **E2E Tests** (Browser)        - Complete application workflows
```

## 🧪 Unit Testing with Haxe

### Testing Pure Functions

**File: `test/unit/TodoFilterTest.hx`**

```haxe
package test.unit;

import haxe.test.TestCase;
import haxe.test.Assert;
import types.Todo;

@:test
class TodoFilterTest extends TestCase {
    
    @:test
    public function testFilterAll(): Void {
        var todos = createTestTodos();
        var result = TodoFilter.apply(todos, All);
        
        Assert.equals(3, result.length);
        Assert.equals("Task 1", result[0].title);
    }
    
    @:test
    public function testFilterActive(): Void {
        var todos = createTestTodos();
        var result = TodoFilter.apply(todos, Active);
        
        Assert.equals(2, result.length);
        Assert.isFalse(result[0].completed);
        Assert.isFalse(result[1].completed);
    }
    
    @:test
    public function testFilterCompleted(): Void {
        var todos = createTestTodos();
        var result = TodoFilter.apply(todos, Completed);
        
        Assert.equals(1, result.length);
        Assert.isTrue(result[0].completed);
    }
    
    @:test
    public function testEmptyList(): Void {
        var result = TodoFilter.apply([], All);
        Assert.equals(0, result.length);
    }
    
    // Type-safe test data creation
    private function createTestTodos(): Array<Todo> {
        return [
            {id: 1, title: "Task 1", completed: false, inserted_at: Date.now()},
            {id: 2, title: "Task 2", completed: true, inserted_at: Date.now()},
            {id: 3, title: "Task 3", completed: false, inserted_at: Date.now()}
        ];
    }
}
```

### Testing Event Handlers

**File: `test/unit/TodoLiveLogicTest.hx`**

```haxe
package test.unit;

import live.TodoLive;
import types.Todo;

@:test 
class TodoLiveLogicTest extends TestCase {
    
    @:test
    public function testHandleCreateTodoSuccess(): Void {
        var liveView = new TodoLive();
        var initialAssigns: TodoAssigns = {
            todos: [],
            filter: All,
            editingId: null,
            newTodoTitle: ""
        };
        
        // Type-safe event parameters
        var params: CreateTodoParams = {title: "New task"};
        
        var result = liveView.handleCreateTodo(params);
        
        switch (result) {
            case Update(updateFn):
                var newAssigns = updateFn(initialAssigns);
                Assert.equals("", newAssigns.newTodoTitle); // Should clear input
            case _:
                Assert.fail("Expected Update result");
        }
    }
    
    @:test
    public function testHandleCreateTodoEmptyTitle(): Void {
        var liveView = new TodoLive();
        var params: CreateTodoParams = {title: "   "}; // Whitespace only
        
        var result = liveView.handleCreateTodo(params);
        
        // Should not create todo with empty title
        Assert.equals(NoOp, result);
    }
    
    @:test
    public function testHandleToggleTodoInvalidId(): Void {
        var liveView = new TodoLive();
        var params = {id: "invalid"};
        
        var result = liveView.handleToggleTodo(params);
        
        // Should handle invalid ID gracefully
        Assert.equals(NoOp, result);
    }
    
    @:test
    public function testFilteringLogic(): Void {
        var assigns: TodoAssigns = {
            todos: createTestTodos(),
            filter: All,
            editingId: null,
            newTodoTitle: ""
        };
        
        var liveView = new TodoLive();
        var result = liveView.handleFilterTodos({filter: "active"});
        
        switch (result) {
            case Update(updateFn):
                var newAssigns = updateFn(assigns);
                Assert.equals(Active, newAssigns.filter);
            case _:
                Assert.fail("Expected Update result");
        }
    }
}
```

## 🎭 Component Testing with ExUnit

### LiveView State Testing

**File: `test/live/todo_live_test.exs`**

```elixir
defmodule MyAppWeb.TodoLiveTest do
  use MyAppWeb.ConnCase
  import Phoenix.LiveViewTest

  test "displays todo list", %{conn: conn} do
    # Create test data
    todo1 = create_todo(%{title: "Learn Haxe", completed: false})
    todo2 = create_todo(%{title: "Build app", completed: true})

    {:ok, view, html} = live(conn, "/todos")

    # Test initial render
    assert html =~ "Learn Haxe"
    assert html =~ "Build app"
    assert html =~ "1 item left"  # Only incomplete todos count
  end

  test "creates new todo", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/todos")

    # Type-safe form submission (Haxe ensures correct structure)
    view
    |> form("#new-todo-form", todo: %{title: "New task"})
    |> render_submit()

    # Verify todo appears
    assert has_element?(view, "[data-testid='todo-item']", "New task")
    
    # Verify counter updated
    assert has_element?(view, ".todo-count", "1 item left")
  end

  test "toggles todo completion", %{conn: conn} do
    todo = create_todo(%{title: "Toggle me", completed: false})
    {:ok, view, _html} = live(conn, "/todos")

    # Click toggle button
    view
    |> element("[data-testid='toggle-#{todo.id}']")
    |> render_click()

    # Verify todo is marked completed
    assert has_element?(view, "[data-testid='todo-#{todo.id}'].completed")
    
    # Verify counter updated
    assert has_element?(view, ".todo-count", "0 items left")
  end

  test "filters todos", %{conn: conn} do
    create_todo(%{title: "Active task", completed: false})
    create_todo(%{title: "Done task", completed: true})

    {:ok, view, _html} = live(conn, "/todos")

    # Click "Active" filter
    view
    |> element("[data-filter='active']")
    |> render_click()

    # Only active todos visible
    assert has_element?(view, "[data-testid='todo-item']", "Active task")
    refute has_element?(view, "[data-testid='todo-item']", "Done task")

    # Click "Completed" filter  
    view
    |> element("[data-filter='completed']")
    |> render_click()

    # Only completed todos visible
    refute has_element?(view, "[data-testid='todo-item']", "Active task")
    assert has_element?(view, "[data-testid='todo-item']", "Done task")
  end

  test "handles invalid todo creation gracefully", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/todos")

    # Submit empty title
    view
    |> form("#new-todo-form", todo: %{title: ""})
    |> render_submit()

    # Should not create todo
    refute has_element?(view, "[data-testid='todo-item']")
    
    # Should show validation error (if implemented)
    # assert has_element?(view, ".error", "Title can't be blank")
  end

  # Helper for creating test todos
  defp create_todo(attrs) do
    MyApp.Todos.create_todo(attrs)
    |> case do
      {:ok, todo} -> todo
      {:error, changeset} -> raise "Failed to create test todo: #{inspect(changeset)}"
    end
  end
end
```

### Component Testing with Live Components

**File: `test/live/user_card_component_test.exs`**

```elixir
defmodule MyAppWeb.UserCardComponentTest do
  use MyAppWeb.ConnCase
  import Phoenix.LiveViewTest

  test "renders user information" do
    user = %{id: 1, name: "John Doe", email: "john@example.com", avatar: "/avatars/john.jpg"}

    html = render_component(MyAppWeb.UserCardComponent, user: user)

    assert html =~ "John Doe"
    assert html =~ "john@example.com"
    assert html =~ "src=\"/avatars/john.jpg\""
  end

  test "handles missing avatar gracefully" do
    user = %{id: 1, name: "Jane Doe", email: "jane@example.com", avatar: nil}

    html = render_component(MyAppWeb.UserCardComponent, user: user)

    assert html =~ "Jane Doe"
    assert html =~ "default-avatar.png"  # Fallback avatar
  end

  test "renders edit button for current user" do
    current_user = %{id: 1, name: "Current User"}
    target_user = %{id: 1, name: "Current User"}

    html = render_component(MyAppWeb.UserCardComponent, 
      user: target_user, 
      current_user: current_user
    )

    assert html =~ "Edit Profile"
  end

  test "hides edit button for other users" do
    current_user = %{id: 1, name: "Current User"}
    other_user = %{id: 2, name: "Other User"}

    html = render_component(MyAppWeb.UserCardComponent, 
      user: other_user, 
      current_user: current_user
    )

    refute html =~ "Edit Profile"
  end
end
```

## 🌐 Integration Testing

### Real-Time Features Testing

**File: `test/live/realtime_todo_test.exs`**

```elixir
defmodule MyAppWeb.RealtimeTodoTest do
  use MyAppWeb.ConnCase
  import Phoenix.LiveViewTest

  test "broadcasts todo creation to all connected clients", %{conn: conn} do
    # Start two LiveView sessions
    {:ok, view1, _html1} = live(conn, "/todos")
    {:ok, view2, _html2} = live(conn, "/todos")

    # Create todo in first session
    view1
    |> form("#new-todo-form", todo: %{title: "Shared task"})
    |> render_submit()

    # Both sessions should see the new todo
    assert has_element?(view1, "[data-testid='todo-item']", "Shared task")
    assert has_element?(view2, "[data-testid='todo-item']", "Shared task")
  end

  test "broadcasts todo updates to all clients", %{conn: conn} do
    todo = create_todo(%{title: "Update me", completed: false})

    {:ok, view1, _html1} = live(conn, "/todos")
    {:ok, view2, _html2} = live(conn, "/todos")

    # Toggle todo in first session
    view1
    |> element("[data-testid='toggle-#{todo.id}']")
    |> render_click()

    # Both sessions should see the update
    assert has_element?(view1, "[data-testid='todo-#{todo.id}'].completed")
    assert has_element?(view2, "[data-testid='todo-#{todo.id}'].completed")
  end

  test "handles client disconnection gracefully", %{conn: conn} do
    {:ok, view1, _html1} = live(conn, "/todos")
    {:ok, view2, _html2} = live(conn, "/todos")

    # Disconnect one client
    Process.exit(view1.pid, :kill)

    # Other client should continue working
    view2
    |> form("#new-todo-form", todo: %{title: "Still working"})
    |> render_submit()

    assert has_element?(view2, "[data-testid='todo-item']", "Still working")
  end
end
```

### File Upload Testing

**File: `test/live/upload_live_test.exs`**

```elixir
defmodule MyAppWeb.UploadLiveTest do
  use MyAppWeb.ConnCase
  import Phoenix.LiveViewTest

  test "uploads file successfully", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/upload")

    # Create test file
    file = %{
      last_modified: System.system_time(:millisecond),
      name: "test.jpg",
      content: File.read!("test/fixtures/test.jpg"),
      size: 1024,
      type: "image/jpeg"
    }

    # Upload file
    assert view
           |> file_input("#upload-form", :avatar, [file])
           |> render_upload("test.jpg")

    # Submit form
    view
    |> form("#upload-form")
    |> render_submit()

    # Verify file was processed
    assert has_element?(view, ".uploaded-file img[src*='test.jpg']")
  end

  test "rejects invalid file types", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/upload")

    file = %{
      last_modified: System.system_time(:millisecond),
      name: "document.pdf",
      content: "fake pdf content",
      size: 1024,
      type: "application/pdf"
    }

    # Try to upload invalid file type
    assert view
           |> file_input("#upload-form", :avatar, [file])
           |> render_upload("document.pdf") =~ "You have selected an unacceptable file type"
  end

  test "enforces file size limits", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/upload")

    # Create file larger than 5MB limit
    large_content = String.duplicate("x", 6_000_000)  # 6MB
    
    file = %{
      last_modified: System.system_time(:millisecond),
      name: "large.jpg",
      content: large_content,
      size: byte_size(large_content),
      type: "image/jpeg"
    }

    assert view
           |> file_input("#upload-form", :avatar, [file])
           |> render_upload("large.jpg") =~ "Too large"
  end
end
```

## 🎯 Hook Testing

### Client-Side Hook Testing (Haxe)

**File: `test/hooks/FormHookTest.hx`**

```haxe
package test.hooks;

import haxe.test.TestCase;
import haxe.test.Assert;
import hooks.FormHook;

// Mock DOM elements for testing
class MockElement {
    public var tagName: String;
    public var value: String;
    public var className: String;
    public var children: Array<MockElement>;
    
    public function new(tagName: String) {
        this.tagName = tagName;
        this.value = "";
        this.className = "";
        this.children = [];
    }
    
    public function querySelector(selector: String): Null<MockElement> {
        // Simple mock implementation
        return switch (selector) {
            case "input[type='text']": children.find(el -> el.tagName == "input");
            case _: null;
        };
    }
    
    public function getElementsByClassName(className: String): Array<MockElement> {
        return children.filter(el -> el.className.indexOf(className) >= 0);
    }
    
    public function appendChild(child: MockElement): Void {
        children.push(child);
    }
}

@:test
class FormHookTest extends TestCase {
    
    @:test
    public function testFormClearsOnSuccess(): Void {
        // Setup mock DOM
        var form = new MockElement("form");
        var input = new MockElement("input");
        input.tagName = "input";
        input.value = "test content";
        form.appendChild(input);
        
        // Create hook
        var hook = new FormHook();
        hook.el = cast form;  // Cast mock to real Element
        
        // Mock successful validation (no errors)
        MockDOM.setValidationErrors([]);
        
        // Trigger updated lifecycle
        hook.updated();
        
        // Assert form was cleared
        Assert.equals("", input.value);
    }
    
    @:test
    public function testFormKeepsContentOnError(): Void {
        var form = new MockElement("form");
        var input = new MockElement("input");
        input.value = "invalid content";
        form.appendChild(input);
        
        var hook = new FormHook();
        hook.el = cast form;
        
        // Mock validation errors
        var errorDiv = new MockElement("div");
        errorDiv.className = "invalid-feedback";
        form.appendChild(errorDiv);
        
        hook.updated();
        
        // Assert form content preserved on error
        Assert.equals("invalid content", input.value);
    }
    
    @:test
    public function testAutoFocusHook(): Void {
        var input = new MockElement("input");
        var focused = false;
        
        // Mock focus method
        input.focus = () -> focused = true;
        
        var hook = new AutoFocusHook();
        hook.el = cast input;
        
        hook.mounted();
        
        Assert.isTrue(focused);
    }
}

// Mock DOM utilities
class MockDOM {
    private static var validationErrors: Array<String> = [];
    
    public static function setValidationErrors(errors: Array<String>): Void {
        validationErrors = errors;
    }
    
    public static function getElementsByClassName(className: String): Array<MockElement> {
        return if (className == "invalid-feedback") {
            validationErrors.map(_ -> new MockElement("div"));
        } else {
            [];
        };
    }
}
```

### Server-Side Hook Integration Testing

**File: `test/live/hook_integration_test.exs`**

```elixir
defmodule MyAppWeb.HookIntegrationTest do
  use MyAppWeb.ConnCase
  import Phoenix.LiveViewTest

  test "form hook clears input on successful submission", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/todos")

    # Fill form and submit
    view
    |> form("#new-todo-form", todo: %{title: "Test todo"})
    |> render_submit()

    # Check that form was cleared (hook behavior)
    # Note: This tests the server-generated HTML after hook runs
    form_html = view
                |> element("#new-todo-form")
                |> render()

    assert form_html =~ "value=\"\""  # Input should be empty
  end

  test "auto-focus hook focuses correct element", %{conn: conn} do
    {:ok, view, html} = live(conn, "/edit-todo/1")

    # Check that the correct element has autofocus attribute
    assert html =~ "autofocus"
    assert html =~ "phx-hook=\"AutoFocus\""
  end

  test "theme toggle hook persists preference", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/todos")

    # Click theme toggle
    view
    |> element("[phx-hook='ThemeToggle']")
    |> render_click()

    # Verify theme class was applied (hook behavior)
    updated_html = render(view)
    assert updated_html =~ "theme-dark"
  end
end
```

## 🚀 End-to-End Testing

### Browser Testing with Wallaby

**File: `test/e2e/todo_workflow_test.exs`**

```elixir
defmodule MyAppWeb.TodoWorkflowTest do
  use MyAppWeb.FeatureCase, async: true

  feature "complete todo workflow", %{session: session} do
    session
    |> visit("/todos")
    |> assert_has(Query.text("0 items left"))

    # Create first todo
    session
    |> fill_in(Query.text_field("title"), with: "Learn Haxe")
    |> send_keys([:enter])
    |> assert_has(Query.text("Learn Haxe"))
    |> assert_has(Query.text("1 item left"))

    # Create second todo
    session
    |> fill_in(Query.text_field("title"), with: "Build app")
    |> send_keys([:enter])
    |> assert_has(Query.text("Build app"))
    |> assert_has(Query.text("2 items left"))

    # Complete first todo
    session
    |> click(Query.checkbox(at: 0))
    |> assert_has(Query.text("1 item left"))
    |> assert_has(Query.css(".todo-item.completed", text: "Learn Haxe"))

    # Filter to show only active
    session
    |> click(Query.link("Active"))
    |> refute_has(Query.text("Learn Haxe"))
    |> assert_has(Query.text("Build app"))

    # Filter to show completed
    session
    |> click(Query.link("Completed"))
    |> assert_has(Query.text("Learn Haxe"))
    |> refute_has(Query.text("Build app"))

    # Delete completed todo
    session
    |> click(Query.button("×"))
    |> accept_confirm()
    |> refute_has(Query.text("Learn Haxe"))

    # Return to all todos
    session
    |> click(Query.link("All"))
    |> assert_has(Query.text("Build app"))
    |> assert_has(Query.text("1 item left"))
  end

  feature "real-time collaboration", %{session: session} do
    # Start second browser session
    session2 = new_session()

    # Both users visit todo page
    session |> visit("/todos")
    session2 |> visit("/todos")

    # User 1 creates todo
    session
    |> fill_in(Query.text_field("title"), with: "Collaborative task")
    |> send_keys([:enter])

    # User 2 should see the todo appear immediately
    session2
    |> assert_has(Query.text("Collaborative task"))
    |> assert_has(Query.text("1 item left"))

    # User 2 completes the todo
    session2
    |> click(Query.checkbox())

    # User 1 should see the completion
    session
    |> assert_has(Query.css(".todo-item.completed"))
    |> assert_has(Query.text("0 items left"))
  end
end
```

## 📊 Test Coverage and Quality

### Coverage Configuration

**File: `mix.exs`**

```elixir
def project do
  [
    # ... other config
    test_coverage: [tool: ExCoveralls],
    preferred_cli_env: [
      coveralls: :test,
      "coveralls.detail": :test,
      "coveralls.post": :test,
      "coveralls.html": :test
    ]
  ]
end

defp deps do
  [
    # ... other deps
    {:excoveralls, "~> 0.18", only: :test}
  ]
end
```

### Quality Metrics

**File: `test/support/test_metrics.ex`**

```elixir
defmodule MyApp.TestMetrics do
  @moduledoc """
  Tracks test quality metrics for Haxe→LiveView applications
  """

  def coverage_goals do
    %{
      total: 90,           # 90% total coverage
      live_views: 95,      # 95% LiveView coverage (critical user flows)
      components: 85,      # 85% component coverage
      hooks: 80,           # 80% hook coverage (client-side logic)
      integration: 75      # 75% integration test coverage
    }
  end

  def type_safety_metrics do
    %{
      compile_errors_caught: count_compile_time_errors(),
      runtime_errors_prevented: count_prevented_runtime_errors(),
      refactoring_safety: measure_refactoring_impact()
    }
  end

  defp count_compile_time_errors do
    # Count errors caught by Haxe compiler vs runtime
    # Higher is better - means more errors caught early
  end
end
```

### Continuous Testing

**File: `.github/workflows/test.yml`**

```yaml
name: Test Suite

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    
    services:
      postgres:
        image: postgres:14
        env:
          POSTGRES_PASSWORD: postgres
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5

    steps:
    - uses: actions/checkout@v3
    
    - name: Setup Elixir
      uses: erlef/setup-beam@v1
      with:
        elixir-version: '1.15'
        otp-version: '26'
        
    - name: Setup Haxe
      uses: krdlab/setup-haxe@v1
      with:
        haxe-version: '4.3.6'
        
    - name: Install dependencies
      run: |
        mix deps.get
        npm install --prefix assets
        
    - name: Compile Haxe sources
      run: haxe build.hxml
      
    - name: Check Haxe compilation
      run: |
        # Ensure all Haxe files compile without errors
        find src_haxe -name "*.hx" -exec haxe -main {} --no-output \;
        
    - name: Run Haxe unit tests
      run: haxe test.hxml
      
    - name: Compile Elixir
      run: mix compile --warnings-as-errors
      
    - name: Run ExUnit tests
      run: mix test --cover
      
    - name: Run integration tests
      run: mix test test/live/
      
    - name: Upload coverage
      run: mix coveralls.github
      env:
        GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

## 🎯 Best Practices Summary

### Test Organization

```
test/
├── unit/              # Haxe unit tests
│   ├── logic/         # Business logic tests
│   ├── filters/       # Data filtering tests
│   └── utils/         # Utility function tests
├── live/              # LiveView integration tests
│   ├── *_live_test.exs
│   └── components/    # Live component tests
├── hooks/             # Hook tests (Haxe)
│   └── *_hook_test.hx
├── e2e/               # End-to-end browser tests
│   └── *_workflow_test.exs
└── support/           # Test helpers and utilities
```

### Testing Checklist

**✅ For Every LiveView**:
- [ ] Unit tests for all event handlers
- [ ] Integration tests for user flows  
- [ ] Real-time feature tests (if applicable)
- [ ] Error handling tests
- [ ] Type safety validation

**✅ For Every Component**:
- [ ] Render tests with various props
- [ ] Event handling tests
- [ ] Edge case tests (missing data, etc.)

**✅ For Every Hook**:
- [ ] Lifecycle method tests (mounted, updated, etc.)
- [ ] DOM manipulation tests
- [ ] Error handling tests

**✅ For Critical Flows**:
- [ ] End-to-end browser tests
- [ ] Performance tests
- [ ] Accessibility tests

---

**Key Insight**: Haxe's type system turns many runtime bugs into compile-time errors, making your test suite both more reliable and more focused on actual business logic rather than basic type safety.