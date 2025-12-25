# Phoenix LiveView Architecture for Haxe→Elixir

This document outlines how to build idiomatic Phoenix LiveView applications using the Haxe→Elixir compiler, based on analysis of official Phoenix LiveView examples and best practices.

## 🎯 Phoenix LiveView Philosophy

### Core Principles

**Phoenix LiveView fundamentally changes the traditional web application architecture:**

1. **Server-Side Rendering with Real-Time Updates**
   - Server renders HTML and sends it to the client
   - WebSocket connection maintains real-time bidirectional communication
   - Client receives DOM patches, not JSON data

2. **Server as Single Source of Truth**
   - All business logic lives on the server
   - All data operations happen server-side
   - Client state is minimal and ephemeral

3. **Minimal Client JavaScript**
   - Client code should be < 200 lines for most applications
   - Focus on DOM enhancement, not data management
   - No client-side routing, API calls, or state management

### Traditional SPA vs Phoenix LiveView

| Traditional SPA | Phoenix LiveView |
|----------------|------------------|
| Complex client routing | Server-side routing |
| Client-side state management | Server-side state |
| JSON API endpoints | WebSocket events |
| Client data fetching | Server data streaming |
| 1000+ lines of JS | < 200 lines of JS |

## 📊 Reference Implementation Analysis

### Official Phoenix LiveView Chat Example

**File: `assets/js/app.js` (60 lines total)**

```javascript
// 1. Basic imports
import "phoenix_html"
import {Socket} from "phoenix"
import {LiveSocket} from "phoenix_live_view"
import topbar from "../vendor/topbar"

// 2. Single hook for form clearing
let Hooks = {}
Hooks.Form = {
  updated() {
    // Clear input if no validation errors
    if(document.getElementsByClassName('invalid-feedback').length == 0) {
      msg.value = '';
    }
  }
}

// 3. LiveSocket setup
let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
let liveSocket = new LiveSocket("/live", Socket, {
  params: {_csrf_token: csrfToken}, 
  hooks: Hooks
})

// 4. Progress bar integration
topbar.config({barColors: {0: "#29d"}, shadowColor: "rgba(0, 0, 0, .3)"})
window.addEventListener("phx:page-loading-start", info => topbar.show())
window.addEventListener("phx:page-loading-stop", info => topbar.hide())

// 5. Connect and expose for debugging
liveSocket.connect()
window.liveSocket = liveSocket
```

**Key Observations:**
- **No async/await patterns** - Not needed for LiveView
- **No data fetching** - Server pushes data via WebSocket
- **Single hook** - Only for DOM manipulation (form clearing)
- **No client-side routing** - Server handles all navigation
- **No error handling/retry logic** - LiveView handles reconnection

### Standard Phoenix Application

**File: `assets/js/app.js` (45 lines total)**

```javascript
import "phoenix_html"
import {Socket} from "phoenix"
import {LiveSocket} from "phoenix_live_view"
import topbar from "../vendor/topbar"

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
let liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: {_csrf_token: csrfToken}
})

// Progress bar integration
topbar.config({barColors: {0: "#29d"}, shadowColor: "rgba(0, 0, 0, .3)"})
window.addEventListener("phx:page-loading-start", _info => topbar.show(300))
window.addEventListener("phx:page-loading-stop", _info => topbar.hide())

liveSocket.connect()
window.liveSocket = liveSocket
```

**Even simpler:**
- **No hooks at all** - Pure LiveView with zero client customization
- **Just LiveSocket + progress bar** - Absolute minimum needed

## 🏗️ Haxe→Elixir Adaptation

### Architecture Mapping

```
Traditional JavaScript          →    Haxe→Elixir
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
app.js (60 lines)              →    TodoApp.hx (~150 lines)
Hooks = {} (object)            →    class Hooks (type-safe)
LiveSocket setup               →    PhoenixLiveView.createSocket()
Manual DOM queries             →    Type-safe Element references
Dynamic event handling        →    Strongly-typed event signatures
No compilation                →    Haxe compile-time validation
```

### Key Adaptations for Haxe

1. **Type-Safe Hook System**
   ```haxe
   // Instead of: Hooks.Form = { updated() { ... } }
   class FormHook implements LiveViewHook {
       public var el: Element;
       public function updated(): Void { ... }
   }
   ```

2. **Compile-Time Hook Registration**
   ```haxe
   class Hooks {
       public static function getAll(): Dynamic {
           return {
               Form: new FormHook(),
               AutoFocus: new AutoFocusHook(),
               ThemeToggle: new ThemeToggleHook()
           };
       }
   }
   ```

3. **Type-Safe Phoenix Integration**
   ```haxe
   class PhoenixLiveView {
       public static function createSocket(): LiveSocket {
           var csrfToken = getCsrfToken();
           return new LiveSocket("/live", Socket, {
               params: {_csrf_token: csrfToken},
               hooks: Hooks.getAll()
           });
       }
   }
   ```

## 🎨 Idiomatic Patterns for Haxe→Elixir

### ✅ Recommended Patterns

#### 1. Minimal Main Application
```haxe
class TodoApp {
    @:expose
    public static function main(): Void {
        // 1. Setup LiveSocket (essential)
        var liveSocket = PhoenixLiveView.createSocket();
        
        // 2. Progress bar (UX enhancement)
        PhoenixLiveView.enableProgressBar();
        
        // 3. Connect to server
        liveSocket.connect();
        
        // 4. UI preferences only (not data)
        DarkMode.initialize();
        
        // 5. Keyboard shortcuts (UX enhancement)
        setupKeyboardShortcuts();
        
        // Done! Server handles everything else
        trace("LiveView client ready");
    }
}
```

#### 2. DOM-Only Hooks
```haxe
class AutoFocusHook implements LiveViewHook {
    public var el: Element;
    
    public function mounted(): Void {
        // Simple DOM enhancement
        el.focus();
        positionCursorAtEnd();
    }
    
    public function updated(): Void {
        // React to server updates
        if (shouldRefocus()) el.focus();
    }
    
    // No data operations!
}
```

#### 3. Server Event Communication
```haxe
class TodoFormHook implements LiveViewHook {
    public var el: Element;
    
    public function updated(): Void {
        // Server handles validation, we just clear on success
        if (hasNoValidationErrors()) {
            clearForm();
        }
    }
    
    private function clearForm(): Void {
        var input = el.querySelector('input[type="text"]');
        if (input != null) input.value = '';
    }
}
```

### ❌ Anti-Patterns to Avoid

#### 1. Client-Side Data Fetching
```haxe
// ❌ WRONG: Client fetching data
@:async
public static function fetchTodosAsync(): js.lib.Promise<Array<Todo>> {
    // This violates LiveView philosophy!
    return fetch("/api/todos").then(response => response.json());
}

// ✅ CORRECT: Server pushes data
// No client code needed - LiveView handles it automatically
```

#### 2. Client-Side State Management
```haxe
// ❌ WRONG: Client managing state
class TodoStore {
    private static var todos: Array<Todo> = [];
    
    public static function addTodo(todo: Todo): Void {
        todos.push(todo);
        // Complex state synchronization...
    }
}

// ✅ CORRECT: Server manages state
// Just push events to server:
pushEvent("add_todo", {title: title});
```

#### 3. Complex Error Handling
```haxe
// ❌ WRONG: Client error handling/retry
@:async
private static function logErrorToServerAsync(error: String): js.lib.Promise<Void> {
    // Complex retry logic, queuing, batching...
    return retryWithBackoff(() => sendError(error));
}

// ✅ CORRECT: Server logs errors via Phoenix.Logger
// Client just reports to console (if anything):
trace('Client error: ${error}');
```

#### 4. Client-Side Routing
```haxe
// ❌ WRONG: Client-side routing
class Router {
    public static function navigateTo(path: String): Void {
        // Client-side route handling...
    }
}

// ✅ CORRECT: Server-side routing via Phoenix Router
// Use pushEvent or live_redirect:
pushEvent("navigate", {path: path});
```

## 🔧 Implementation Guidelines

### Client Code Size Limits

**Strict Guidelines:**
- **Main application file**: < 200 lines
- **Individual hooks**: < 50 lines each
- **Total client code**: < 500 lines for most apps
- **Zero async data operations** (except legitimate UI needs)

### Hook Lifecycle Usage

| Lifecycle Method | Purpose | Example Use Case |
|------------------|---------|------------------|
| `mounted()` | Initial DOM setup | Focus input, setup event listeners |
| `beforeUpdate()` | Pre-update preparation | Save scroll position |
| `updated()` | React to server changes | Clear form on success, restore scroll |
| `destroyed()` | Cleanup | Remove event listeners |
| `disconnected()` | Connection lost | Show offline indicator |
| `reconnected()` | Connection restored | Hide offline indicator |

### Server-Side Responsibilities

**Everything important happens on the server:**

1. **Data Operations**
   ```elixir
   # In LiveView module
   def handle_event("create_todo", %{"title" => title}, socket) do
     case Todos.create_todo(%{title: title}) do
       {:ok, todo} ->
         # Server handles success: broadcast to all clients
         TodoApp.PubSub.broadcast("todos", {:todo_created, todo})
         {:noreply, socket}
       {:error, changeset} ->
         # Server handles errors: show validation
         {:noreply, assign(socket, changeset: changeset)}
     end
   end
   ```

2. **Real-Time Updates**
   ```elixir
   # Server pushes updates to all connected clients
   def handle_info({:todo_created, todo}, socket) do
     {:noreply, assign(socket, todos: [todo | socket.assigns.todos])}
   end
   ```

3. **State Management**
   ```elixir
   # All state lives in socket.assigns
   def mount(_params, _session, socket) do
     if connected?(socket) do
       TodoApp.PubSub.subscribe("todos")
     end
     
     {:ok, assign(socket, todos: Todos.list_todos())}
   end
   ```

## 🧪 Testing Strategy

### Focus on Server-Side Testing

**Primary testing effort should be on LiveView modules:**

```elixir
test "creates todo and broadcasts to connected clients", %{conn: conn} do
  {:ok, view, html} = live(conn, "/")
  
  # Test server event handling
  view
  |> form("#todo-form", todo: %{title: "New todo"})
  |> render_submit()
  
  # Verify server state changed
  assert has_element?(view, "#todo-list li", "New todo")
end
```

### Minimal Client-Side Testing

**Only test DOM manipulation in hooks:**

```haxe
// Test hook behavior, not data logic
class AutoFocusHookTest {
    @:test
    public function testFocusesOnMount(): Void {
        var el = createMockElement();
        var hook = new AutoFocusHook();
        hook.el = el;
        
        hook.mounted();
        
        Assert.isTrue(el.focused);
    }
}
```

## 🚀 Performance Characteristics

### What LiveView Provides

1. **Automatic Optimization**
   - DOM diffing and minimal patches
   - Connection management and reconnection
   - Compression and batching

2. **Server-Side Benefits**
   - Database connection pooling
   - Shared memory across users
   - Efficient query optimization

3. **Client-Side Benefits**
   - No bundle size concerns (minimal JS)
   - No client-side memory leaks
   - Automatic cleanup on disconnection

### When to Use Async/Await in Haxe

**Legitimate use cases for async patterns:**

1. **File Operations**
   ```haxe
   @:async
   public static function uploadFileAsync(file: File): js.lib.Promise<Void> {
       // File upload with progress tracking
       return fileUploader.upload(file);
   }
   ```

2. **Client-Side Image Processing**
   ```haxe
   @:async
   public static function resizeImageAsync(image: ImageElement): js.lib.Promise<Blob> {
       // Canvas manipulation, image filtering
       return imageProcessor.resize(image);
   }
   ```

3. **Animation Sequences**
   ```haxe
   @:async
   public static function animateTransitionAsync(element: Element): js.lib.Promise<Void> {
       // Complex CSS animation chains
       return animator.fadeOut(element).then(() => animator.slideIn(element));
   }
   ```

**Key Point: Async is for client-side operations only, never for server communication in LiveView apps.**

## 📚 Reference Resources

- **Phoenix LiveView Docs**: https://hexdocs.pm/phoenix_live_view/
- **Example App**: [`examples/todo-app`](../../../../examples/todo-app/README.md)
- **Haxe→Elixir Patterns**: [`PHOENIX_LIVEVIEW_PATTERNS.md`](PHOENIX_LIVEVIEW_PATTERNS.md)
- **Implementation Guide**: [`guides/PHOENIX_LIVEVIEW_GUIDE.md`](guides/PHOENIX_LIVEVIEW_GUIDE.md)
- **Testing Approach**: [`PHOENIX_LIVEVIEW_TESTING.md`](PHOENIX_LIVEVIEW_TESTING.md)

---

**Remember: Phoenix LiveView's power comes from doing LESS on the client, not more. Embrace the simplicity!**
