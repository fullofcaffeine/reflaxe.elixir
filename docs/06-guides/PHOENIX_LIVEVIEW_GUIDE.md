# Phoenix LiveView Implementation Guide for Haxe→Elixir

This step-by-step guide shows how to build idiomatic Phoenix LiveView applications using Haxe, with practical examples and best practices.

## 🚀 Quick Start: Your First LiveView

### Step 1: Project Setup

```bash
# Create Phoenix application
mix phx.new my_app --live
cd my_app

# Add Haxe→Elixir compiler
# (Follow GETTING_STARTED.md for detailed setup)

# Create Haxe source directory
mkdir src_haxe
mkdir src_haxe/live
```

### Step 2: Basic LiveView in Haxe

**File: `src_haxe/live/CounterLive.hx`**

```haxe
package live;

import phoenix.LiveView;

typedef CounterAssigns = {
    count: Int,
    step: Int
}

@:liveview
@:native("MyAppWeb.CounterLive")
class CounterLive {
    
    public function mount(params: Dynamic, session: Dynamic): MountResult<CounterAssigns> {
        return Ok({
            count: 0,
            step: 1
        });
    }
    
    @:event("increment")
    public function handleIncrement(): UpdateResult<CounterAssigns> {
        return Update(assigns -> ({...assigns, count: assigns.count + assigns.step}));
    }
    
    @:event("decrement")
    public function handleDecrement(): UpdateResult<CounterAssigns> {
        return Update(assigns -> ({...assigns, count: assigns.count - assigns.step}));
    }
    
    @:event("set_step")
    public function handleSetStep(params: {step: String}): UpdateResult<CounterAssigns> {
        var step = Std.parseInt(params.step);
        return switch (step) {
            case null: NoOp; // Invalid number, ignore
            case value: Update(assigns -> ({...assigns, step: value}));
        };
    }
}
```

### Step 3: HXX Template

**File: `src_haxe/live/CounterTemplate.hx`**

```haxe
package live;

@:hxx
class CounterTemplate {
    public static function render(assigns: CounterAssigns): HxxElement {
        return jsx('
            <div class="counter-container">
                <h1>Counter: {assigns.count}</h1>
                
                <div class="controls">
                    <button phx-click="decrement" class="btn btn-outline">
                        - {assigns.step}
                    </button>
                    
                    <button phx-click="increment" class="btn btn-primary">
                        + {assigns.step}
                    </button>
                </div>
                
                <div class="step-control">
                    <label for="step">Step size:</label>
                    <input 
                        type="number" 
                        id="step" 
                        value={Std.string(assigns.step)}
                        phx-change="set_step" 
                        name="step"
                    />
                </div>
            </div>
        ');
    }
}
```

### Step 4: Compile and Test

```bash
# Compile Haxe to Elixir
haxe build.hxml

# Start Phoenix server
mix phx.server

# Visit http://localhost:4000/counter
```

## 🏗️ Building Real-World Features

### Feature 1: Real-Time Todo List

#### Define Data Types

**File: `src_haxe/types/Todo.hx`**

```haxe
package types;

typedef Todo = {
    id: Int,
    title: String,
    completed: Bool,
    inserted_at: Date
}

enum TodoFilter {
    All;
    Active; 
    Completed;
}

typedef TodoAssigns = {
    todos: Array<Todo>,
    filter: TodoFilter,
    editingId: Null<Int>,
    newTodoTitle: String
}
```

#### Implement LiveView Logic

**File: `src_haxe/live/TodoLive.hx`**

```haxe
package live;

import types.Todo;
import phoenix.LiveView;
import phoenix.PubSub;

@:liveview
@:native("MyAppWeb.TodoLive")
class TodoLive {
    
    public function mount(params: Dynamic, session: Dynamic): MountResult<TodoAssigns> {
        // Subscribe to real-time updates if connected
        if (LiveView.connected()) {
            PubSub.subscribe("todos");
        }
        
        return Ok({
            todos: TodoRepo.listTodos(),
            filter: All,
            editingId: null,
            newTodoTitle: ""
        });
    }
    
    @:event("create_todo")
    public function handleCreateTodo(params: {title: String}): UpdateResult<TodoAssigns> {
        var title = StringTools.trim(params.title);
        
        if (title.length == 0) {
            return NoOp; // Don't create empty todos
        }
        
        return switch (TodoRepo.createTodo({title: title})) {
            case Ok(todo):
                // Broadcast to all connected clients
                PubSub.broadcast("todos", {todo_created: todo});
                Update(assigns -> ({...assigns, newTodoTitle: ""}));
                
            case Error(changeset):
                ShowFlash("error", "Failed to create todo");
        };
    }
    
    @:event("toggle_todo")
    public function handleToggleTodo(params: {id: String}): UpdateResult<TodoAssigns> {
        var id = Std.parseInt(params.id);
        return switch (id) {
            case null: NoOp;
            case todoId:
                switch (TodoRepo.toggleTodo(todoId)) {
                    case Ok(todo):
                        PubSub.broadcast("todos", {todo_updated: todo});
                        NoOp; // Will update via PubSub message
                    case Error(_):
                        ShowFlash("error", "Failed to update todo");
                }
        };
    }
    
    @:event("delete_todo")
    public function handleDeleteTodo(params: {id: String}): UpdateResult<TodoAssigns> {
        var id = Std.parseInt(params.id);
        return switch (id) {
            case null: NoOp;
            case todoId:
                switch (TodoRepo.deleteTodo(todoId)) {
                    case Ok(_):
                        PubSub.broadcast("todos", {todo_deleted: todoId});
                        NoOp; // Will update via PubSub message
                    case Error(_):
                        ShowFlash("error", "Failed to delete todo");
                }
        };
    }
    
    @:event("filter_todos")
    public function handleFilterTodos(params: {filter: String}): UpdateResult<TodoAssigns> {
        var filter = switch (params.filter) {
            case "all": All;
            case "active": Active;
            case "completed": Completed;
            case _: All;
        };
        
        return Update(assigns -> ({...assigns, filter: filter}));
    }
    
    // Handle real-time updates from other clients
    @:info("todo_created")
    public function handleTodoCreated(todo: Todo): UpdateResult<TodoAssigns> {
        return Update(assigns -> ({...assigns, todos: [todo, ...assigns.todos]}));
    }
    
    @:info("todo_updated")
    public function handleTodoUpdated(updatedTodo: Todo): UpdateResult<TodoAssigns> {
        var newTodos = assigns.todos.map(todo -> 
            todo.id == updatedTodo.id ? updatedTodo : todo
        );
        return Update(assigns -> ({...assigns, todos: newTodos}));
    }
    
    @:info("todo_deleted")
    public function handleTodoDeleted(todoId: Int): UpdateResult<TodoAssigns> {
        var newTodos = assigns.todos.filter(todo -> todo.id != todoId);
        return Update(assigns -> ({...assigns, todos: newTodos}));
    }
}
```

#### Create Rich Template with HXX

**File: `src_haxe/live/TodoTemplate.hx`**

```haxe
package live;

import types.Todo;

@:hxx
class TodoTemplate {
    public static function render(assigns: TodoAssigns): HxxElement {
        var filteredTodos = filterTodos(assigns.todos, assigns.filter);
        var activeCount = assigns.todos.filter(todo -> !todo.completed).length;
        
        return jsx('
            <div class="todo-app">
                <header class="header">
                    <h1>Todo App</h1>
                    <form phx-submit="create_todo" class="new-todo-form">
                        <input 
                            type="text"
                            name="title"
                            placeholder="What needs to be done?"
                            class="new-todo-input"
                            value={assigns.newTodoTitle}
                            autofocus
                        />
                    </form>
                </header>
                
                <main class="main">
                    {renderTodoList(filteredTodos, assigns.editingId)}
                </main>
                
                <footer class="footer">
                    {renderFooter(activeCount, assigns.filter)}
                </footer>
            </div>
        ');
    }
    
    private static function renderTodoList(todos: Array<Todo>, editingId: Null<Int>): HxxElement {
        if (todos.length == 0) {
            return jsx('<div class="empty-state">No todos yet!</div>');
        }
        
        return jsx('
            <ul class="todo-list">
                {todos.map(todo -> renderTodoItem(todo, editingId))}
            </ul>
        ');
    }
    
    private static function renderTodoItem(todo: Todo, editingId: Null<Int>): HxxElement {
        var isEditing = editingId == todo.id;
        var itemClass = todo.completed ? "completed" : "";
        
        return jsx('
            <li class={"todo-item " + itemClass} key={Std.string(todo.id)}>
                <div class="view">
                    <input 
                        type="checkbox"
                        class="toggle"
                        checked={todo.completed}
                        phx-click="toggle_todo"
                        phx-value-id={Std.string(todo.id)}
                    />
                    <label class="todo-title">{todo.title}</label>
                    <button 
                        class="destroy"
                        phx-click="delete_todo"
                        phx-value-id={Std.string(todo.id)}
                        phx-confirm="Are you sure?"
                    >
                        ×
                    </button>
                </div>
            </li>
        ');
    }
    
    private static function renderFooter(activeCount: Int, filter: TodoFilter): HxxElement {
        var itemText = activeCount == 1 ? "item" : "items";
        
        return jsx('
            <div class="todo-footer">
                <span class="todo-count">
                    <strong>{Std.string(activeCount)}</strong> {itemText} left
                </span>
                
                <ul class="filters">
                    {renderFilterLink("All", "all", filter == All)}
                    {renderFilterLink("Active", "active", filter == Active)}
                    {renderFilterLink("Completed", "completed", filter == Completed)}
                </ul>
            </div>
        ');
    }
    
    private static function renderFilterLink(text: String, value: String, isActive: Bool): HxxElement {
        var className = isActive ? "selected" : "";
        
        return jsx('
            <li>
                <a 
                    href="#"
                    class={className}
                    phx-click="filter_todos"
                    phx-value-filter={value}
                >
                    {text}
                </a>
            </li>
        ');
    }
    
    private static function filterTodos(todos: Array<Todo>, filter: TodoFilter): Array<Todo> {
        return switch (filter) {
            case All: todos;
            case Active: todos.filter(todo -> !todo.completed);
            case Completed: todos.filter(todo -> todo.completed);
        };
    }
}
```

### Feature 2: File Upload with Progress

#### File Upload LiveView

**File: `src_haxe/live/UploadLive.hx`**

```haxe
package live;

typedef UploadAssigns = {
    uploads: Dynamic, // Phoenix LiveView uploads
    uploadedFiles: Array<String>
}

@:liveview
@:native("MyAppWeb.UploadLive")
class UploadLive {
    
    public function mount(params: Dynamic, session: Dynamic): MountResult<UploadAssigns> {
        var socket = LiveView.allowUpload("avatar", {
            accept: [".jpg", ".jpeg", ".png"],
            max_entries: 1,
            max_file_size: 5_000_000 // 5MB
        });
        
        return Ok({
            uploads: socket.assigns.uploads,
            uploadedFiles: []
        });
    }
    
    @:event("validate_upload")
    public function handleValidateUpload(): UpdateResult<UploadAssigns> {
        // Validation happens automatically by Phoenix LiveView
        return NoOp;
    }
    
    @:event("cancel_upload")
    public function handleCancelUpload(params: {ref: String}): UpdateResult<UploadAssigns> {
        LiveView.cancelUpload("avatar", params.ref);
        return NoOp;
    }
    
    @:event("save_upload")
    public function handleSaveUpload(): UpdateResult<UploadAssigns> {
        var uploadedFiles = LiveView.consumeUploadedEntries("avatar", (meta, entry) -> {
            var dest = "priv/static/uploads/" + entry.uuid + "_" + entry.client_name;
            File.copy(meta.path, dest);
            return "/uploads/" + entry.uuid + "_" + entry.client_name;
        });
        
        return Update(assigns -> ({
            ...assigns, 
            uploadedFiles: [...assigns.uploadedFiles, ...uploadedFiles]
        }));
    }
}
```

#### Upload Template with Progress

**File: `src_haxe/live/UploadTemplate.hx`**

```haxe
@:hxx
class UploadTemplate {
    public static function render(assigns: UploadAssigns): HxxElement {
        return jsx('
            <div class="upload-container">
                <h2>File Upload</h2>
                
                <form phx-submit="save_upload" phx-change="validate_upload">
                    <div 
                        class="upload-dropzone"
                        phx-drop-target={assigns.uploads.avatar.ref}
                    >
                        <input 
                            type="file"
                            phx-hook="FileUpload"
                            phx-update="ignore"
                            {...LiveView.uploadInputProps("avatar", assigns.uploads)}
                        />
                        <p>Drag files here or click to browse</p>
                    </div>
                    
                    {renderUploadProgress(assigns.uploads.avatar)}
                    
                    <button 
                        type="submit"
                        class="upload-btn"
                        disabled={!LiveView.hasUploads("avatar", assigns.uploads)}
                    >
                        Upload Files
                    </button>
                </form>
                
                {renderUploadedFiles(assigns.uploadedFiles)}
            </div>
        ');
    }
    
    private static function renderUploadProgress(upload: Dynamic): HxxElement {
        return jsx('
            <div class="upload-entries">
                {LiveView.uploadEntries(upload).map(entry -> jsx('
                    <div class="upload-entry" key={entry.ref}>
                        <div class="entry-info">
                            <span class="filename">{entry.client_name}</span>
                            <span class="filesize">{formatFileSize(entry.client_size)}</span>
                        </div>
                        
                        <div class="progress-bar">
                            <div 
                                class="progress-fill"
                                style={"width: " + entry.progress + "%"}
                            ></div>
                        </div>
                        
                        <button 
                            type="button"
                            phx-click="cancel_upload"
                            phx-value-ref={entry.ref}
                            class="cancel-btn"
                        >
                            Cancel
                        </button>
                        
                        {renderUploadErrors(entry.errors)}
                    </div>
                '))}
            </div>
        ');
    }
    
    private static function renderUploadErrors(errors: Array<String>): HxxElement {
        if (errors.length == 0) {
            return jsx('<span></span>');
        }
        
        return jsx('
            <div class="upload-errors">
                {errors.map(error -> jsx('<div class="error">{error}</div>'))}
            </div>
        ');
    }
    
    private static function renderUploadedFiles(files: Array<String>): HxxElement {
        if (files.length == 0) {
            return jsx('<span></span>');
        }
        
        return jsx('
            <div class="uploaded-files">
                <h3>Uploaded Files</h3>
                {files.map(file -> jsx('
                    <div class="uploaded-file" key={file}>
                        <img src={file} alt="Uploaded file" class="thumbnail" />
                        <span class="filename">{extractFilename(file)}</span>
                    </div>
                '))}
            </div>
        ');
    }
    
    private static function formatFileSize(bytes: Int): String {
        if (bytes < 1024) return bytes + " B";
        if (bytes < 1024 * 1024) return Math.round(bytes / 1024) + " KB";
        return Math.round(bytes / (1024 * 1024)) + " MB";
    }
    
    private static function extractFilename(path: String): String {
        var parts = path.split("/");
        return parts[parts.length - 1];
    }
}
```

## 🎯 Advanced Patterns

### Pattern 1: Component Communication

#### Parent Component

```haxe
@:liveview
class DashboardLive {
    @:event("user_selected")
    public function handleUserSelected(params: {userId: String}): UpdateResult<DashboardAssigns> {
        var userId = Std.parseInt(params.userId);
        
        // Send targeted event to UserDetails component
        LiveView.sendUpdate("UserDetails", {user_id: userId});
        
        return Update(assigns -> ({...assigns, selectedUserId: userId}));
    }
}
```

#### Child Component

```haxe
@:live_component
@:native("MyAppWeb.UserDetailsComponent")
class UserDetailsComponent {
    @:update("user_id")
    public function handleUserIdUpdate(assigns: ComponentAssigns, userId: Int): UpdateResult<ComponentAssigns> {
        var user = UserRepo.getUser(userId);
        return Update({...assigns, user: user});
    }
}
```

### Pattern 2: Form Validation with Changesets

```haxe
typedef UserFormAssigns = {
    changeset: Changeset,
    user: Null<User>
}

@:liveview
class UserFormLive {
    @:event("validate_user")
    public function handleValidateUser(params: {user: Dynamic}): UpdateResult<UserFormAssigns> {
        var changeset = User.changeset(assigns.user ?? new User(), params.user);
        var validatedChangeset = Changeset.validate(changeset);
        
        return Update(assigns -> ({...assigns, changeset: validatedChangeset}));
    }
    
    @:event("save_user")
    public function handleSaveUser(params: {user: Dynamic}): UpdateResult<UserFormAssigns> {
        var changeset = User.changeset(assigns.user ?? new User(), params.user);
        
        return switch (UserRepo.insertOrUpdate(changeset)) {
            case Ok(user):
                LiveView.redirect("/users/" + user.id);
            case Error(changeset):
                Update(assigns -> ({...assigns, changeset: changeset}));
        };
    }
}
```

## 🧪 Testing Your LiveView

### Integration Testing

**File: `test/live/TodoLiveTest.hx`**

```haxe
package test.live;

@:test
class TodoLiveTest extends LiveViewTestCase {
    @:test
    public function testTodoCreation(): Void {
        var liveView = LiveViewTestHelpers.renderComponent(TodoLive);
        
        // Submit new todo form
        var form = LiveViewTestHelpers.findForm(liveView, "#new-todo-form");
        LiveViewTestHelpers.submitForm(form, {title: "Learn Haxe"});
        
        // Assert todo appears in list
        Assert.isTrue(LiveViewTestHelpers.hasElement(liveView, "[data-todo='Learn Haxe']"));
        
        // Assert todo count updated
        var countElement = LiveViewTestHelpers.findElement(liveView, ".todo-count strong");
        Assert.equals("1", countElement.textContent);
    }
    
    @:test
    public function testRealTimeUpdates(): Void {
        // Start two LiveView sessions
        var session1 = LiveViewTestHelpers.renderComponent(TodoLive);
        var session2 = LiveViewTestHelpers.renderComponent(TodoLive);
        
        // Create todo in session 1
        LiveViewTestHelpers.submitForm(session1, "#new-todo-form", {title: "Shared todo"});
        
        // Assert both sessions see the todo
        Assert.isTrue(LiveViewTestHelpers.hasElement(session1, "[data-todo='Shared todo']"));
        Assert.isTrue(LiveViewTestHelpers.hasElement(session2, "[data-todo='Shared todo']"));
    }
}
```

### Hook Testing

**File: `test/hooks/FileUploadHookTest.hx`**

```haxe
@:test
class FileUploadHookTest extends HookTestCase {
    @:test
    public function testFileSelection(): Void {
        var mockElement = MockDOM.createFileInput();
        var hook = new FileUploadHook();
        hook.el = mockElement;
        
        // Simulate file selection
        var file = MockFile.create("test.jpg", "image/jpeg", 1024);
        MockDOM.triggerFileSelect(mockElement, [file]);
        
        // Assert hook processes file
        Assert.equals(1, hook.selectedFiles.length);
        Assert.equals("test.jpg", hook.selectedFiles[0].name);
    }
}
```

## 🚀 Performance Optimization

### 1. Efficient Rendering with Keys

```haxe
// Always use keys for dynamic lists
{todos.map(todo -> jsx('
    <TodoItem key={Std.string(todo.id)} todo={todo} />
'))}
```

### 2. Selective Updates

```haxe
@:event("update_todo_title")
public function handleUpdateTodoTitle(params: {id: String, title: String}): UpdateResult<TodoAssigns> {
    var id = Std.parseInt(params.id);
    
    // Only update the specific todo, not the entire list
    return Update(assigns -> ({
        ...assigns,
        todos: assigns.todos.map(todo -> 
            todo.id == id ? {...todo, title: params.title} : todo
        )
    }));
}
```

### 3. Debounced Events

```haxe
@:event("search_todos")
@:debounce(300) // Wait 300ms after last keystroke
public function handleSearchTodos(params: {query: String}): UpdateResult<TodoAssigns> {
    var filteredTodos = TodoSearch.search(params.query);
    return Update(assigns -> ({...assigns, filteredTodos: filteredTodos}));
}
```

## 📚 Next Steps

1. **Read the Architecture docs**: [`PHOENIX_LIVEVIEW_ARCHITECTURE.md`](../PHOENIX_LIVEVIEW_ARCHITECTURE.md)
2. **Study the Patterns**: [`PHOENIX_LIVEVIEW_PATTERNS.md`](../PHOENIX_LIVEVIEW_PATTERNS.md)  
3. **Learn Testing**: [`PHOENIX_LIVEVIEW_TESTING.md`](../PHOENIX_LIVEVIEW_TESTING.md)
4. **Explore Examples**: Check out the `examples/todo-app` for a complete implementation
5. **Join the Community**: Share your Haxe LiveView applications and get help

---

**Pro Tip**: Start small with a simple counter or todo list, then gradually add real-time features, file uploads, and complex interactions. Haxe's type system will guide you toward correct implementations and catch errors early in the development process.