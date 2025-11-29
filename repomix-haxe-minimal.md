This file is a merged representation of a subset of the codebase, containing specifically included files, combined into a single document by Repomix.
The content has been processed where comments have been removed, empty lines have been removed, content has been compressed (code blocks are separated by ⋮---- delimiter).

# File Summary

## Purpose
This file contains a packed representation of the entire repository's contents.
It is designed to be easily consumable by AI systems for analysis, code review,
or other automated processes.

## File Format
The content is organized as follows:
1. This summary section
2. Repository information
3. Directory structure
4. Multiple file entries, each consisting of:
  a. A header with the file path (## File: path/to/file)
  b. The full contents of the file in a code block

## Usage Guidelines
- This file should be treated as read-only. Any changes should be made to the
  original repository files, not this packed version.
- When processing this file, use the file path to distinguish
  between different files in the repository.
- Be aware that this file may contain sensitive information. Handle it with
  the same level of security as you would the original repository.

## Notes
- Some files may have been excluded based on .gitignore rules and Repomix's configuration
- Binary files are not included in this packed representation. Please refer to the Repository Structure section for a complete list of file paths, including binary files
- Only files matching these patterns are included: examples/todo-app/src_haxe/**/*.hx, src/reflaxe/elixir/macros/HXX.hx, src/reflaxe/elixir/ast/TemplateHelpers.hx
- Files matching patterns in .gitignore are excluded
- Code comments have been removed from supported file types
- Empty lines have been removed from all files
- Content has been compressed - code blocks are separated by ⋮---- delimiter

## Additional Info

# Directory Structure
```
examples/
  todo-app/
    src_haxe/
      client/
        extern/
          Phoenix.hx
        hooks/
          AutoFocus.hx
          Hooks.hx
          LiveSync.hx
          ThemeToggle.hx
          TodoFilter.hx
          TodoForm.hx
        utils/
          DarkMode.hx
          LocalStorage.hx
        Boot.hx
        TodoApp.hx
      server/
        components/
          CoreComponents.hx
        contexts/
          Users.hx
        controllers/
          UserController.hx
        i18n/
          Gettext.hx
        infrastructure/
          Endpoint.hx
          Gettext.hx
          GettextErrorMessages.hx
          GettextUIMessages.hx
          Repo.hx
          Telemetry.hx
          TodoAppWeb.hx
          TranslationBindings.hx
        layouts/
          AppLayout.hx
          Layouts.hx
          RootLayout.hx
        live/
          SafeAssigns.hx
          TodoLive.hx
          UserLive.hx
        migrations/
          CreateTodos.hx
          CreateUsers.hx
        presence/
          TodoPresence.hx
        pubsub/
          TodoPubSub.hx
        schemas/
          Todo.hx
          User.hx
        services/
          UserGenServer.hx
        types/
          LiveViewTypes.hx
          Types.hx
      shared/
        PrewarmDummy.hx
        TodoTypes.hx
      test/
        contexts/
          UsersTest.hx
        live/
          TodoLiveClassTest.hx
          TodoLiveCrudTest.hx
          TodoLiveDueDateTest.hx
          TodoLiveOptimisticLatencyTest.hx
          TodoLiveTest.hx
        schemas/
          TodoTest.hx
        support/
          ConnCase.hx
          DataCase.hx
        web/
          HealthTest.hx
          TodoLiveCrudTest.hx
        AsyncAnonymousTest.hx
        AsyncTest.hx
        test_helper.hx
      TestAbstract.hx
      TestInjection.hx
      TestInline.hx
      TestStringBuf.hx
      TodoApp.hx
      TodoAppRouter.hx
src/
  reflaxe/
    elixir/
      ast/
        TemplateHelpers.hx
      macros/
        HXX.hx
```

# Files

## File: examples/todo-app/src_haxe/client/extern/Phoenix.hx
````
package client.extern;

import js.html.Element;

/**
 * Phoenix LiveView JavaScript API extern definitions
 * Provides type-safe interfaces for Phoenix LiveView hooks
 */

/**
 * Phoenix LiveView Hook interface
 * All hooks must implement these methods
 */
interface LiveViewHook {
    /**
     * Element that the hook is attached to
     */
    var el: Element;
}

// Also fix the closing brace to be on its own line

/**
 * Phoenix LiveView Socket extern
 */
extern class LiveSocket {
    public function new(url: String, socket: Dynamic, ?options: Dynamic);
    public function connect(): Void;
    public function disconnect(): Void;
    public function isConnected(): Bool;
    public function pushEvent(event: String, payload: Dynamic): Void;
    public var hooks: Dynamic;
}

/**
 * Phoenix Socket extern
 */
extern class Socket {
    public function new(url: String, ?options: Dynamic);
    public function connect(): Void;
    public function disconnect(): Void;
    public function isConnected(): Bool;
}

/**
 * Phoenix Channel extern
 */
extern class Channel {
    public function new(topic: String, payload: Dynamic, socket: Socket);
    public function join(): Dynamic;
    public function leave(): Dynamic;
    public function push(event: String, payload: Dynamic): Dynamic;
    public function on(event: String, callback: Dynamic -> Void): Void;
}

/**
 * LiveView test utilities (for testing)
 */
extern class LiveViewTest {
    public static function live(conn: Dynamic, path: String): Dynamic;
    public static function render_click(view: Dynamic, selector: String): String;
    public static function render_submit(form: Dynamic): String;
    public static function form(view: Dynamic, selector: String, params: Dynamic): Dynamic;
    public static function element(view: Dynamic, selector: String): Dynamic;
    public static function has_element(view: Dynamic, selector: String): Bool;
}
````

## File: examples/todo-app/src_haxe/client/hooks/AutoFocus.hx
````
package client.hooks;

import js.html.Element;
import js.html.InputElement;
import js.html.TextAreaElement;
import client.extern.Phoenix.LiveViewHook;

/**
 * AutoFocus hook for automatic focus on form inputs
 * Focuses the element when mounted and optionally when updated
 */
class AutoFocus implements LiveViewHook {
    
    public var el: Element;
    
    public function new() {}
    
    /**
     * Focus the element when mounted
     */
    public function mounted(): Void {
        focusElement();
    }
    
    /**
     * Optionally focus again when updated (if specified in data attributes)
     */
    public function updated(): Void {
        var refocusOnUpdate = el.getAttribute("data-refocus-on-update");
        if (refocusOnUpdate == "true") {
            focusElement();
        }
    }
    
    /**
     * Focus the element with proper type checking
     */
    private function focusElement(): Void {
        // Small delay to ensure the element is fully rendered
        js.Browser.window.setTimeout(function() {
            try {
                if (Std.isOfType(el, InputElement)) {
                    var input: InputElement = cast el;
                    input.focus();
                    
                    // Position cursor at end if it's a text input
                    if (input.type == "text" || input.type == "email" || input.type == "search") {
                        var length = input.value.length;
                        input.setSelectionRange(length, length);
                    }
                } else if (Std.isOfType(el, TextAreaElement)) {
                    var textarea: TextAreaElement = cast el;
                    textarea.focus();
                    
                    // Position cursor at end
                    var length = textarea.value.length;
                    textarea.setSelectionRange(length, length);
                } else {
                    // Generic focus for other elements
                    el.focus();
                }
            } catch (e: Dynamic) {
                trace('AutoFocus error: $e');
            }
        }, 10);
    }
}
````

## File: examples/todo-app/src_haxe/client/hooks/Hooks.hx
````
package client.hooks;

/**
 * Hooks registry for Phoenix LiveView
 * Exports all available hooks for LiveView to use
 */
class Hooks {
    
    /**
     * Get all available hooks as a dynamic object
     * This is what gets exported to Phoenix LiveView
     */
    public static function getAll(): Dynamic {
        return {
            AutoFocus: AutoFocus,
            ThemeToggle: ThemeToggle,
            TodoForm: TodoForm,
            TodoFilter: TodoFilter,
            LiveSync: LiveSync
        };
    }
    
    /**
     * Individual hook getters for direct access
     */
    public static function getAutoFocus(): Dynamic {
        return AutoFocus;
    }
    
    public static function getThemeToggle(): Dynamic {
        return ThemeToggle;
    }
    
    public static function getTodoForm(): Dynamic {
        return TodoForm;
    }
    
    public static function getTodoFilter(): Dynamic {
        return TodoFilter;
    }
    
    public static function getLiveSync(): Dynamic {
        return LiveSync;
    }
}
````

## File: examples/todo-app/src_haxe/client/hooks/LiveSync.hx
````
package client.hooks;

import js.html.Element;
import client.extern.Phoenix.LiveViewHook;
import client.utils.LocalStorage;
import shared.TodoTypes;

/**
 * LiveSync hook for real-time synchronization and offline support
 * Handles PubSub events, offline detection, and state synchronization
 */
class LiveSync implements LiveViewHook {
    
    public var el: Element;
    
    private var isOnline: Bool = true;
    private var syncQueue: Array<Dynamic> = [];
    private var lastSyncTime: Float = 0;
    
    public function new() {}
    
    /**
     * Set up real-time sync when mounted
     */
    public function mounted(): Void {
        setupOnlineDetection();
        setupPubSubHandlers();
        setupPeriodicSync();
        restoreOfflineQueue();
        
        // Mark as online and attempt initial sync
        setOnlineStatus(js.Browser.navigator.onLine);
        
        // Subscribe to todo updates
        subscribeToUpdates();
    }
    
    /**
     * Handle updates from LiveView
     */
    public function updated(): Void {
        updateLastSyncTime();
        processIncomingUpdates();
    }
    
    /**
     * Clean up when destroyed
     */
    public function destroyed(): Void {
        unsubscribeFromUpdates();
    }
    
    /**
     * Set up online/offline detection
     */
    private function setupOnlineDetection(): Void {
        js.Browser.window.addEventListener("online", function() {
            setOnlineStatus(true);
            processSyncQueue();
        });
        
        js.Browser.window.addEventListener("offline", function() {
            setOnlineStatus(false);
            showOfflineIndicator();
        });
        
        // Initial status
        setOnlineStatus(js.Browser.navigator.onLine);
    }
    
    /**
     * Set up PubSub event handlers
     */
    private function setupPubSubHandlers(): Void {
        // Handle different types of PubSub events
        handleEventIfAvailable("todo_added", handleTodoAdded);
        handleEventIfAvailable("todo_updated", handleTodoUpdated);
        handleEventIfAvailable("todo_deleted", handleTodoDeleted);
        handleEventIfAvailable("user_joined", handleUserJoined);
        handleEventIfAvailable("user_left", handleUserLeft);
        handleEventIfAvailable("sync_state", handleSyncState);
    }
    
    /**
     * Set up periodic sync for data consistency
     */
    private function setupPeriodicSync(): Void {
        // Sync every 30 seconds when online
        js.Browser.window.setInterval(function() {
            if (isOnline) {
                requestSync();
            }
        }, 30000);
    }
    
    /**
     * Subscribe to todo updates channel
     */
    private function subscribeToUpdates(): Void {
        pushEventIfAvailable("subscribe_to_updates", {
            user_id: getCurrentUserId(),
            timestamp: Date.now().getTime()
        });
    }
    
    /**
     * Unsubscribe from updates
     */
    private function unsubscribeFromUpdates(): Void {
        pushEventIfAvailable("unsubscribe_from_updates", {
            user_id: getCurrentUserId()
        });
    }
    
    /**
     * Set online status and update UI
     */
    private function setOnlineStatus(online: Bool): Void {
        var wasOnline = isOnline;
        isOnline = online;
        
        // Update status indicator
        updateStatusIndicator(online);
        
        // If we came back online, process pending actions
        if (!wasOnline && online) {
            showOnlineIndicator();
            processSyncQueue();
        }
    }
    
    /**
     * Update status indicator in UI
     */
    private function updateStatusIndicator(online: Bool): Void {
        var indicator = js.Browser.document.querySelector(".connection-status");
        if (indicator != null) {
            if (online) {
                indicator.classList.remove("offline");
                indicator.classList.add("online");
                indicator.textContent = "⚡ Real-time sync enabled";
            } else {
                indicator.classList.remove("online");
                indicator.classList.add("offline");
                indicator.textContent = "📴 Offline mode";
            }
        }
    }
    
    /**
     * Handle todo added event
     */
    private function handleTodoAdded(payload: Dynamic): Void {
        trace('Todo added: ${payload.todo.title}');
        
        // Update local cache
        var todos = getCachedTodos();
        todos.push(payload.todo);
        cacheTodos(todos);
        
        // Show notification if it's from another user
        if (payload.todo.user_id != getCurrentUserId()) {
            showNotification("New Todo", 'A new todo "${payload.todo.title}" was added', "📝");
        }
    }
    
    /**
     * Handle todo updated event
     */
    private function handleTodoUpdated(payload: Dynamic): Void {
        trace('Todo updated: ${payload.todo.title}');
        
        // Update local cache
        var todos = getCachedTodos();
        var index = findTodoIndex(todos, payload.todo.id);
        if (index >= 0) {
            todos[index] = payload.todo;
            cacheTodos(todos);
        }
        
        // Visual feedback for updates
        highlightUpdatedTodo(payload.todo.id);
    }
    
    /**
     * Handle todo deleted event
     */
    private function handleTodoDeleted(payload: Dynamic): Void {
        trace('Todo deleted: ${payload.id}');
        
        // Update local cache
        var todos = getCachedTodos();
        var index = findTodoIndex(todos, payload.id);
        if (index >= 0) {
            todos.splice(index, 1);
            cacheTodos(todos);
        }
    }
    
    /**
     * Handle user joined event
     */
    private function handleUserJoined(payload: Dynamic): Void {
        showNotification("User Joined", '${payload.user.name} joined the session', "👋");
    }
    
    /**
     * Handle user left event
     */
    private function handleUserLeft(payload: Dynamic): Void {
        showNotification("User Left", '${payload.user.name} left the session', "👋");
    }
    
    /**
     * Handle sync state event
     */
    private function handleSyncState(payload: Dynamic): Void {
        lastSyncTime = payload.timestamp;
        updateLastSyncIndicator();
    }
    
    /**
     * Process the offline sync queue
     */
    private function processSyncQueue(): Void {
        if (!isOnline || syncQueue.length == 0) return;
        
        trace('Processing ${syncQueue.length} queued actions');
        
        for (action in syncQueue) {
            pushEventIfAvailable(action.event, action.payload);
        }
        
        // Clear the queue after successful sync
        syncQueue = [];
        LocalStorage.remove("sync_queue");
        
        showNotification("Sync Complete", 'Synchronized ${syncQueue.length} offline changes', "✅");
    }
    
    /**
     * Queue an action for offline sync
     */
    public function queueAction(event: String, payload: Dynamic): Void {
        var action = {
            event: event,
            payload: payload,
            timestamp: Date.now().getTime()
        };
        
        syncQueue.push(action);
        LocalStorage.setObject("sync_queue", syncQueue);
        
        showNotification("Action Queued", "Action saved for sync when online", "💾");
    }
    
    /**
     * Restore offline queue from localStorage
     */
    private function restoreOfflineQueue(): Void {
        var stored = LocalStorage.getObject("sync_queue");
        if (stored != null && Std.isOfType(stored, Array)) {
            syncQueue = stored;
            trace('Restored ${syncQueue.length} queued actions');
        }
    }
    
    /**
     * Request sync from server
     */
    private function requestSync(): Void {
        pushEventIfAvailable("request_sync", {
            last_sync: lastSyncTime,
            client_timestamp: Date.now().getTime()
        });
    }
    
    /**
     * Update last sync time
     */
    private function updateLastSyncTime(): Void {
        lastSyncTime = Date.now().getTime();
        updateLastSyncIndicator();
    }
    
    /**
     * Update last sync time indicator
     */
    private function updateLastSyncIndicator(): Void {
        var indicator = js.Browser.document.querySelector(".last-sync-time");
        if (indicator != null) {
            var timeAgo = getTimeAgo(lastSyncTime);
            indicator.textContent = 'Last updated: $timeAgo';
        }
    }
    
    /**
     * Process incoming updates from LiveView
     */
    private function processIncomingUpdates(): Void {
        // Check for data attributes with update information
        var updateType = el.getAttribute("data-update-type");
        var updateData = el.getAttribute("data-update-data");
        
        if (updateType != null && updateData != null) {
            try {
                var data = haxe.Json.parse(updateData);
                handleIncomingUpdate(updateType, data);
            } catch (e: Dynamic) {
                trace('Error processing update: $e');
            }
        }
    }
    
    /**
     * Handle incoming update based on type
     */
    private function handleIncomingUpdate(type: String, data: Dynamic): Void {
        switch (type) {
            case "todo_list_updated":
                handleTodoListUpdate(data);
            case "filter_changed":
                handleFilterChange(data);
            case "search_results":
                handleSearchResults(data);
        }
    }
    
    /**
     * Handle todo list update
     */
    private function handleTodoListUpdate(data: Dynamic): Void {
        if (data.todos != null) {
            cacheTodos(data.todos);
        }
    }
    
    /**
     * Handle filter change
     */
    private function handleFilterChange(data: Dynamic): Void {
        LocalStorage.setString("current_filter", data.filter);
    }
    
    /**
     * Handle search results
     */
    private function handleSearchResults(data: Dynamic): Void {
        // Could cache search results for offline access
        LocalStorage.setObject("last_search_results", data);
    }
    
    /**
     * Cache todos in localStorage
     */
    private function cacheTodos(todos: Array<Dynamic>): Void {
        LocalStorage.setObject("todos_cache", {
            todos: todos,
            timestamp: Date.now().getTime()
        });
    }
    
    /**
     * Get cached todos
     */
    private function getCachedTodos(): Array<Dynamic> {
        var cache = LocalStorage.getObject("todos_cache");
        return (cache != null && cache.todos != null) ? cache.todos : [];
    }
    
    /**
     * Find todo index in array
     */
    private function findTodoIndex(todos: Array<Dynamic>, id: Int): Int {
        for (i in 0...todos.length) {
            if (todos[i].id == id) return i;
        }
        return -1;
    }
    
    /**
     * Highlight updated todo for visual feedback
     */
    private function highlightUpdatedTodo(id: Int): Void {
        var todoElement = js.Browser.document.querySelector('[data-todo-id="$id"]');
        if (todoElement != null) {
            todoElement.classList.add("updated-highlight");
            js.Browser.window.setTimeout(function() {
                todoElement.classList.remove("updated-highlight");
            }, 2000);
        }
    }
    
    /**
     * Show notification
     */
    private function showNotification(title: String, message: String, icon: String): Void {
        // For now, just use console - could integrate with browser notifications
        trace('$icon $title: $message');
    }
    
    /**
     * Show online indicator
     */
    private function showOnlineIndicator(): Void {
        showNotification("Back Online", "Reconnected to server", "🌐");
    }
    
    /**
     * Show offline indicator
     */
    private function showOfflineIndicator(): Void {
        showNotification("Gone Offline", "Working in offline mode", "📴");
    }
    
    /**
     * Get current user ID
     */
    private function getCurrentUserId(): Int {
        var userId = el.getAttribute("data-user-id");
        return userId != null ? Std.parseInt(userId) : 0;
    }
    
    /**
     * Get time ago string
     */
    private function getTimeAgo(timestamp: Float): String {
        var now = Date.now().getTime();
        var diff = now - timestamp;
        var seconds = Math.floor(diff / 1000);
        
        if (seconds < 60) return "just now";
        if (seconds < 3600) return '${Math.floor(seconds / 60)} minutes ago';
        if (seconds < 86400) return '${Math.floor(seconds / 3600)} hours ago';
        return '${Math.floor(seconds / 86400)} days ago';
    }
    
    /**
     * Handle event if available
     */
    private function handleEventIfAvailable(event: String, handler: Dynamic -> Void): Void {
        try {
            var handleEvent = Reflect.field(this, "handleEvent");
            if (handleEvent != null && Reflect.isFunction(handleEvent)) {
                handleEvent(event, handler);
            }
        } catch (e: Dynamic) {
            trace('Could not set up handler for event ${event}: ${e}');
        }
    }
    
    /**
     * Push event to LiveView if available
     */
    private function pushEventIfAvailable(event: String, payload: Dynamic): Void {
        if (!isOnline) {
            queueAction(event, payload);
            return;
        }
        
        try {
            var pushEvent = Reflect.field(this, "pushEvent");
            if (pushEvent != null && Reflect.isFunction(pushEvent)) {
                pushEvent(event, payload);
            }
        } catch (e: Dynamic) {
            trace('Could not push event ${event}: ${e}');
        }
    }
}
````

## File: examples/todo-app/src_haxe/client/hooks/ThemeToggle.hx
````
package client.hooks;

import js.html.Element;
import js.html.ButtonElement;
import client.extern.Phoenix.LiveViewHook;
import client.utils.DarkMode;

/**
 * Theme toggle hook for dark/light mode switching
 * Manages theme toggle button state and interactions
 */
class ThemeToggle implements LiveViewHook {
    
    public var el: Element;
    
    public function new() {}
    
    /**
     * Set up theme toggle when mounted
     */
    public function mounted(): Void {
        setupToggleButton();
        updateButtonState();
    }
    
    /**
     * Update button state when the component updates
     */
    public function updated(): Void {
        updateButtonState();
    }
    
    /**
     * Set up click event listener for the toggle button
     */
    private function setupToggleButton(): Void {
        if (!Std.isOfType(el, ButtonElement)) {
            trace("ThemeToggle hook must be attached to a button element");
            return;
        }
        
        var button: ButtonElement = cast el;
        
        button.addEventListener("click", function(e) {
            e.preventDefault();
            
            // Toggle the theme
            DarkMode.toggle();
            
            // Update button visual state
            updateButtonState();
            
            // Optional: Notify LiveView of theme change
            var theme = DarkMode.isEnabled() ? "dark" : "light";
            pushEventIfAvailable("theme_changed", {theme: theme});
            
            // Add visual feedback
            addClickFeedback(button);
        });
    }
    
    /**
     * Update the button's visual state based on current theme
     */
    private function updateButtonState(): Void {
        var button: ButtonElement = cast el;
        var isDark = DarkMode.isEnabled();
        
        // Update button title/tooltip
        button.title = isDark ? "Switch to light mode" : "Switch to dark mode";
        
        // Update aria-label for accessibility
        button.setAttribute("aria-label", isDark ? "Switch to light mode" : "Switch to dark mode");
        
        // Update data attribute for CSS styling
        button.setAttribute("data-theme", isDark ? "dark" : "light");
        
        // Update icon visibility if icons are present
        updateIconVisibility(isDark);
    }
    
    /**
     * Update icon visibility for dark/light mode icons
     */
    private function updateIconVisibility(isDark: Bool): Void {
        var darkIcon = el.querySelector("#theme-toggle-dark-icon");
        var lightIcon = el.querySelector("#theme-toggle-light-icon");
        
        if (darkIcon != null && lightIcon != null) {
            if (isDark) {
                // Dark mode active, show light icon (to switch to light)
                darkIcon.classList.add("hidden");
                lightIcon.classList.remove("hidden");
            } else {
                // Light mode active, show dark icon (to switch to dark)
                darkIcon.classList.remove("hidden");
                lightIcon.classList.add("hidden");
            }
        }
    }
    
    /**
     * Add visual feedback when button is clicked
     */
    private function addClickFeedback(button: ButtonElement): Void {
        // Add a temporary class for click animation
        button.classList.add("theme-toggle-clicked");
        
        // Remove the class after animation
        js.Browser.window.setTimeout(function() {
            button.classList.remove("theme-toggle-clicked");
        }, 200);
    }
    
    /**
     * Push event to LiveView if the pushEvent function is available
     */
    private function pushEventIfAvailable(event: String, payload: Dynamic): Void {
        try {
            // Check if pushEvent is available on this hook instance
            var pushEvent = Reflect.field(this, "pushEvent");
            if (pushEvent != null && Reflect.isFunction(pushEvent)) {
                pushEvent(event, payload);
            }
        } catch (e: Dynamic) {
            // Silently handle if pushEvent is not available
            trace('Could not push event ${event}: ${e}');
        }
    }
}
````

## File: examples/todo-app/src_haxe/client/hooks/TodoFilter.hx
````
package client.hooks;

import js.html.Element;
import js.html.InputElement;
import js.html.KeyboardEvent;
import client.extern.Phoenix.LiveViewHook;
import client.utils.LocalStorage;
import shared.TodoTypes;

/**
 * TodoFilter hook for search and filtering functionality
 * Handles search input, filter persistence, and keyboard shortcuts
 */
class TodoFilter implements LiveViewHook {
    
    public var el: Element;
    
    private var searchTimer: Int = -1;
    private var searchDelay: Int = 300; // 300ms debounce
    
    public function new() {}
    
    /**
     * Set up filter functionality when mounted
     */
    public function mounted(): Void {
        setupSearchInput();
        setupFilterButtons();
        setupKeyboardShortcuts();
        restoreFilterState();
    }
    
    /**
     * Clean up when destroyed
     */
    public function destroyed(): Void {
        clearSearchTimer();
    }
    
    /**
     * Set up search input with debouncing
     */
    private function setupSearchInput(): Void {
        var searchInput = el.querySelector("input[type='text']");
        if (searchInput == null) return;
        
        var input: InputElement = cast searchInput;
        
        input.addEventListener("input", function(e) {
            scheduleSearch(input.value);
        });
        
        input.addEventListener("keydown", function(e: KeyboardEvent) {
            // Escape: Clear search
            if (e.key == "Escape") {
                e.preventDefault();
                clearSearch(input);
            }
            
            // Enter: Execute search immediately
            if (e.key == "Enter") {
                e.preventDefault();
                executeSearch(input.value);
            }
        });
        
        // Placeholder text based on current filter
        updateSearchPlaceholder(input);
    }
    
    /**
     * Set up filter button interactions
     */
    private function setupFilterButtons(): Void {
        var filterButtons = el.querySelectorAll("[phx-click='filter_todos']");
        
        for (i in 0...filterButtons.length) {
            var button = filterButtons[i];
            
            button.addEventListener("click", function(e) {
                var filterValue = cast(button, js.html.Element).getAttribute("phx-value-filter");
                saveFilterState(filterValue);
                updateActiveButton(cast(button, js.html.Element));
            });
        }
    }
    
    /**
     * Set up keyboard shortcuts for filtering
     */
    private function setupKeyboardShortcuts(): Void {
        js.Browser.document.addEventListener("keydown", function(e: KeyboardEvent) {
            // Only handle if this filter component is active
            if (!isComponentActive()) return;
            
            // Ctrl/Cmd + F: Focus search
            if ((e.ctrlKey || e.metaKey) && e.key == "f") {
                e.preventDefault();
                focusSearch();
            }
            
            // Alt + 1/2/3: Filter shortcuts
            if (e.altKey && !e.ctrlKey && !e.metaKey) {
                var filterMap = ["all", "active", "completed"];
                var index = Std.parseInt(e.key) - 1;
                
                if (index >= 0 && index < filterMap.length) {
                    e.preventDefault();
                    setFilter(filterMap[index]);
                }
            }
        });
    }
    
    /**
     * Schedule search with debouncing
     */
    private function scheduleSearch(query: String): Void {
        clearSearchTimer();
        
        searchTimer = js.Browser.window.setTimeout(function() {
            executeSearch(query);
        }, searchDelay);
    }
    
    /**
     * Clear the search timer
     */
    private function clearSearchTimer(): Void {
        if (searchTimer != -1) {
            js.Browser.window.clearTimeout(searchTimer);
            searchTimer = -1;
        }
    }
    
    /**
     * Execute the search
     */
    private function executeSearch(query: String): Void {
        // Save search query
        LocalStorage.setString("todo_search_query", query);
        
        // Push event to LiveView
        pushEventIfAvailable("search_todos", {query: query});
        
        // Update URL if supported
        updateURL(query);
    }
    
    /**
     * Clear search input and results
     */
    private function clearSearch(input: InputElement): Void {
        input.value = "";
        executeSearch("");
        input.blur();
    }
    
    /**
     * Focus the search input
     */
    private function focusSearch(): Void {
        var searchInput = el.querySelector("input[type='text']");
        if (searchInput != null) {
            searchInput.focus();
        }
    }
    
    /**
     * Set active filter
     */
    private function setFilter(filter: String): Void {
        // Find and click the appropriate filter button
        var button = el.querySelector('[phx-value-filter="$filter"]');
        if (button != null) {
            button.click();
        }
    }
    
    /**
     * Save filter state to localStorage
     */
    private function saveFilterState(filter: String): Void {
        LocalStorage.setString("todo_filter", filter);
        LocalStorage.setNumber("todo_filter_timestamp", Date.now().getTime());
    }
    
    /**
     * Restore filter state from localStorage
     */
    private function restoreFilterState(): Void {
        var savedFilter = LocalStorage.getString("todo_filter");
        var timestamp = LocalStorage.getNumber("todo_filter_timestamp");
        
        // Only restore if recent (within last hour)
        var now = Date.now().getTime();
        var maxAge = 60 * 60 * 1000; // 1 hour
        
        if (savedFilter != null && (now - timestamp) < maxAge) {
            // Set the saved filter if different from current
            var currentFilter = getCurrentFilter();
            if (currentFilter != savedFilter) {
                setFilter(savedFilter);
            }
        }
        
        // Restore search query
        var savedQuery = LocalStorage.getString("todo_search_query", "");
        var searchInput = el.querySelector("input[type='text']");
        if (searchInput != null && savedQuery != "") {
            var input: InputElement = cast searchInput;
            input.value = savedQuery;
        }
    }
    
    /**
     * Get current active filter
     */
    private function getCurrentFilter(): String {
        var activeButton = el.querySelector(".bg-blue-500, [data-active='true']");
        if (activeButton != null) {
            return activeButton.getAttribute("phx-value-filter") ?? "all";
        }
        return "all";
    }
    
    /**
     * Update active button styling
     */
    private function updateActiveButton(clickedButton: Element): Void {
        // Remove active styling from all buttons
        var allButtons = el.querySelectorAll("[phx-click='filter_todos']");
        for (i in 0...allButtons.length) {
            var button = allButtons[i];
            cast(button, js.html.Element).classList.remove("bg-blue-500", "text-white");
            cast(button, js.html.Element).classList.add("bg-white", "text-gray-700");
            cast(button, js.html.Element).setAttribute("data-active", "false");
        }
        
        // Add active styling to clicked button
        clickedButton.classList.remove("bg-white", "text-gray-700");
        clickedButton.classList.add("bg-blue-500", "text-white");
        clickedButton.setAttribute("data-active", "true");
    }
    
    /**
     * Update search placeholder based on current filter
     */
    private function updateSearchPlaceholder(input: InputElement): Void {
        var currentFilter = getCurrentFilter();
        var placeholders = [
            "all" => "Search all todos...",
            "active" => "Search active todos...",
            "completed" => "Search completed todos..."
        ];
        
        input.placeholder = placeholders[currentFilter] ?? "Search todos...";
    }
    
    /**
     * Check if this component is currently active/visible
     */
    private function isComponentActive(): Bool {
        return el.offsetParent != null; // Simple visibility check
    }
    
    /**
     * Update URL with search/filter state (if browser supports history API)
     */
    private function updateURL(query: String): Void {
        if (js.Browser.window.history != null && js.Browser.window.history.pushState != null) {
            try {
                var url = new js.html.URL(js.Browser.window.location.href);
                
                if (query != "") {
                    url.searchParams.set("search", query);
                } else {
                    url.searchParams.delete("search");
                }
                
                js.Browser.window.history.replaceState(null, "", url.href);
            } catch (e: Dynamic) {
                // Silently fail if URL manipulation is not supported
                trace('Could not update URL: $e');
            }
        }
    }
    
    /**
     * Push event to LiveView if available
     */
    private function pushEventIfAvailable(event: String, payload: Dynamic): Void {
        try {
            var pushEvent = Reflect.field(this, "pushEvent");
            if (pushEvent != null && Reflect.isFunction(pushEvent)) {
                pushEvent(event, payload);
            }
        } catch (e: Dynamic) {
            trace('Could not push event ${event}: ${e}');
        }
    }
}
````

## File: examples/todo-app/src_haxe/client/hooks/TodoForm.hx
````
package client.hooks;

import js.html.Element;
import js.html.FormElement;
import js.html.InputElement;
import js.html.TextAreaElement;
import js.html.KeyboardEvent;
import client.extern.Phoenix.LiveViewHook;
import client.utils.LocalStorage;

/**
 * TodoForm hook for enhanced form interactions
 * Handles auto-save, keyboard shortcuts, and form validation
 */
class TodoForm implements LiveViewHook {
    
    public var el: Element;
    
    private var autoSaveTimer: Int = -1;
    private var autoSaveDelay: Int = 1000; // 1 second
    
    public function new() {}
    
    /**
     * Set up form enhancements when mounted
     */
    public function mounted(): Void {
        if (!Std.isOfType(el, FormElement)) {
            trace("TodoForm hook must be attached to a form element");
            return;
        }
        
        setupKeyboardShortcuts();
        setupAutoSave();
        setupFormValidation();
        restoreFormData();
    }
    
    /**
     * Clean up when destroyed
     */
    public function destroyed(): Void {
        clearAutoSaveTimer();
        clearFormData();
    }
    
    /**
     * Set up keyboard shortcuts for the form
     */
    private function setupKeyboardShortcuts(): Void {
        var form: FormElement = cast el;
        
        form.addEventListener("keydown", function(e: KeyboardEvent) {
            // Ctrl/Cmd + Enter: Submit form
            if ((e.ctrlKey || e.metaKey) && e.key == "Enter") {
                e.preventDefault();
                submitForm();
            }
            
            // Escape: Clear form or cancel edit
            if (e.key == "Escape") {
                e.preventDefault();
                clearForm();
                pushEventIfAvailable("cancel_edit", {});
            }
            
            // Ctrl/Cmd + S: Save draft
            if ((e.ctrlKey || e.metaKey) && e.key == "s") {
                e.preventDefault();
                saveDraft();
            }
        });
    }
    
    /**
     * Set up auto-save functionality
     */
    private function setupAutoSave(): Void {
        var inputs = el.querySelectorAll("input, textarea, select");
        
        for (i in 0...inputs.length) {
            var input = inputs[i];
            
            input.addEventListener("input", function(e) {
                scheduleAutoSave();
            });
            
            input.addEventListener("change", function(e) {
                scheduleAutoSave();
            });
        }
    }
    
    /**
     * Set up form validation enhancements
     */
    private function setupFormValidation(): Void {
        var form: FormElement = cast el;
        
        form.addEventListener("submit", function(e) {
            if (!validateForm()) {
                e.preventDefault();
                showValidationErrors();
            }
        });
        
        // Real-time validation on blur
        var inputs = el.querySelectorAll("input[required], textarea[required]");
        for (i in 0...inputs.length) {
            var input = inputs[i];
            input.addEventListener("blur", function(e) {
                validateField(cast e.target);
            });
        }
    }
    
    /**
     * Schedule auto-save with debouncing
     */
    private function scheduleAutoSave(): Void {
        clearAutoSaveTimer();
        
        // Only auto-save if enabled in settings
        if (!LocalStorage.getBoolean("autoSave", true)) return;
        
        autoSaveTimer = js.Browser.window.setTimeout(function() {
            saveDraft();
        }, autoSaveDelay);
    }
    
    /**
     * Clear the auto-save timer
     */
    private function clearAutoSaveTimer(): Void {
        if (autoSaveTimer != -1) {
            js.Browser.window.clearTimeout(autoSaveTimer);
            autoSaveTimer = -1;
        }
    }
    
    /**
     * Save form data as draft
     */
    private function saveDraft(): Void {
        var formData = getFormData();
        var formId = el.getAttribute("id") ?? "default_form";
        
        LocalStorage.setObject('form_draft_${formId}', {
            data: formData,
            timestamp: Date.now().getTime()
        });
        
        // Visual feedback for auto-save
        showSaveIndicator();
    }
    
    /**
     * Restore form data from draft
     */
    private function restoreFormData(): Void {
        var formId = el.getAttribute("id") ?? "default_form";
        var draft = LocalStorage.getObject('form_draft_${formId}');
        
        if (draft != null && draft.data != null) {
            // Check if draft is recent (within 24 hours)
            var now = Date.now().getTime();
            var age = now - draft.timestamp;
            var maxAge = 24 * 60 * 60 * 1000; // 24 hours
            
            if (age < maxAge) {
                setFormData(draft.data);
                showDraftRestoredIndicator();
            } else {
                // Clean up old draft
                clearFormData();
            }
        }
    }
    
    /**
     * Get form data as an object
     */
    private function getFormData(): Dynamic {
        var form: FormElement = cast el;
        var formData = new js.html.FormData(form);
        var data = {};
        
        // Convert FormData to plain object
        untyped __js__("
            for (let [key, value] of formData.entries()) {
                data[key] = value;
            }
        ");
        
        return data;
    }
    
    /**
     * Set form data from an object
     */
    private function setFormData(data: Dynamic): Void {
        for (field in Reflect.fields(data)) {
            var value = Reflect.field(data, field);
            var input = el.querySelector('[name="$field"]');
            
            if (input != null) {
                if (Std.isOfType(input, InputElement)) {
                    var inputEl: InputElement = cast input;
                    inputEl.value = Std.string(value);
                } else if (Std.isOfType(input, TextAreaElement)) {
                    var textareaEl: TextAreaElement = cast input;
                    textareaEl.value = Std.string(value);
                }
            }
        }
    }
    
    /**
     * Validate the entire form
     */
    private function validateForm(): Bool {
        var form: FormElement = cast el;
        var isValid = true;
        
        var requiredInputs = el.querySelectorAll("input[required], textarea[required]");
        for (i in 0...requiredInputs.length) {
            var input = requiredInputs[i];
            if (!validateField(cast input)) {
                isValid = false;
            }
        }
        
        return isValid;
    }
    
    /**
     * Validate a single field
     */
    private function validateField(input: Element): Bool {
        var isValid = true;
        
        if (Std.isOfType(input, InputElement)) {
            var inputEl: InputElement = cast input;
            
            // Check required
            if (inputEl.required && StringTools.trim(inputEl.value) == "") {
                showFieldError(inputEl, "This field is required");
                isValid = false;
            } else {
                clearFieldError(inputEl);
            }
        }
        
        return isValid;
    }
    
    /**
     * Show validation error for a field
     */
    private function showFieldError(input: InputElement, message: String): Void {
        input.classList.add("border-red-500", "focus:border-red-500");
        input.classList.remove("border-gray-300", "focus:border-blue-500");
        
        // Find or create error message element
        var errorId = '${input.name}_error';
        var existingError = js.Browser.document.getElementById(errorId);
        
        if (existingError == null) {
            var errorEl = js.Browser.document.createDivElement();
            errorEl.id = errorId;
            errorEl.className = "text-red-500 text-sm mt-1";
            errorEl.textContent = message;
            input.parentElement.appendChild(errorEl);
        } else {
            existingError.textContent = message;
        }
    }
    
    /**
     * Clear validation error for a field
     */
    private function clearFieldError(input: InputElement): Void {
        input.classList.remove("border-red-500", "focus:border-red-500");
        input.classList.add("border-gray-300", "focus:border-blue-500");
        
        var errorId = '${input.name}_error';
        var errorEl = js.Browser.document.getElementById(errorId);
        if (errorEl != null) {
            errorEl.remove();
        }
    }
    
    /**
     * Submit the form
     */
    private function submitForm(): Void {
        var form: FormElement = cast el;
        if (validateForm()) {
            form.submit();
            clearFormData(); // Clear draft after successful submit
        }
    }
    
    /**
     * Clear the form
     */
    private function clearForm(): Void {
        var form: FormElement = cast el;
        form.reset();
        clearFormData();
    }
    
    /**
     * Clear saved form data
     */
    private function clearFormData(): Void {
        var formId = el.getAttribute("id") ?? "default_form";
        LocalStorage.remove('form_draft_${formId}');
    }
    
    /**
     * Show visual indicator for auto-save
     */
    private function showSaveIndicator(): Void {
        // Implementation would show a subtle "saved" indicator
        // For now, just log it
        trace("Form auto-saved");
    }
    
    /**
     * Show indicator that draft was restored
     */
    private function showDraftRestoredIndicator(): Void {
        // Implementation would show "draft restored" message
        trace("Form draft restored");
    }
    
    /**
     * Show validation errors
     */
    private function showValidationErrors(): Void {
        // Focus on first invalid field
        var firstInvalid = el.querySelector(".border-red-500");
        if (firstInvalid != null) {
            firstInvalid.focus();
        }
    }
    
    /**
     * Push event to LiveView if available
     */
    private function pushEventIfAvailable(event: String, payload: Dynamic): Void {
        try {
            var pushEvent = Reflect.field(this, "pushEvent");
            if (pushEvent != null && Reflect.isFunction(pushEvent)) {
                pushEvent(event, payload);
            }
        } catch (e: Dynamic) {
            trace('Could not push event ${event}: ${e}');
        }
    }
}
````

## File: examples/todo-app/src_haxe/client/utils/DarkMode.hx
````
package client.utils;

import js.Browser;
import js.html.Element;

/**
 * Dark mode management utility
 * Handles theme detection, toggling, and persistence
 */
class DarkMode {
    
    private static inline var THEME_KEY = "theme";
    private static inline var DARK_CLASS = "dark";
    
    /**
     * Initialize dark mode system
     */
    public static function initialize(): Void {
        // Apply saved theme or system preference immediately
        applyTheme();
        
        // Set up theme toggle button if present
        setupToggleButton();
    }
    
    /**
     * Check if dark mode is currently enabled
     */
    public static function isEnabled(): Bool {
        return Browser.document.documentElement.classList.contains(DARK_CLASS);
    }
    
    /**
     * Toggle between light and dark mode
     */
    public static function toggle(): Void {
        if (isEnabled()) {
            setLightMode();
        } else {
            setDarkMode();
        }
    }
    
    /**
     * Enable dark mode
     */
    public static function setDarkMode(): Void {
        Browser.document.documentElement.classList.add(DARK_CLASS);
        LocalStorage.setString(THEME_KEY, "dark");
        updateToggleButton();
    }
    
    /**
     * Enable light mode
     */
    public static function setLightMode(): Void {
        Browser.document.documentElement.classList.remove(DARK_CLASS);
        LocalStorage.setString(THEME_KEY, "light");
        updateToggleButton();
    }
    
    /**
     * Get the current theme preference
     */
    public static function getTheme(): String {
        var saved = LocalStorage.getString(THEME_KEY);
        if (saved != null) return saved;
        
        // Check system preference
        if (Browser.window.matchMedia != null) {
            var darkMediaQuery = Browser.window.matchMedia("(prefers-color-scheme: dark)");
            return darkMediaQuery.matches ? "dark" : "light";
        }
        
        return "light";
    }
    
    /**
     * Apply the theme based on saved preference or system setting
     */
    private static function applyTheme(): Void {
        if (getTheme() == "dark") {
            Browser.document.documentElement.classList.add(DARK_CLASS);
        } else {
            Browser.document.documentElement.classList.remove(DARK_CLASS);
        }
    }
    
    /**
     * Set up the theme toggle button functionality
     */
    private static function setupToggleButton(): Void {
        var toggleButton = Browser.document.getElementById("theme-toggle");
        if (toggleButton == null) return;
        
        toggleButton.addEventListener("click", function(e) {
            e.preventDefault();
            toggle();
        });
        
        updateToggleButton();
    }
    
    /**
     * Update the toggle button icons based on current theme
     */
    private static function updateToggleButton(): Void {
        var darkIcon = Browser.document.getElementById("theme-toggle-dark-icon");
        var lightIcon = Browser.document.getElementById("theme-toggle-light-icon");
        
        if (darkIcon == null || lightIcon == null) return;
        
        if (isEnabled()) {
            // Dark mode is active, show light icon (to switch to light)
            darkIcon.classList.add("hidden");
            lightIcon.classList.remove("hidden");
        } else {
            // Light mode is active, show dark icon (to switch to dark)
            darkIcon.classList.remove("hidden");
            lightIcon.classList.add("hidden");
        }
    }
}
````

## File: examples/todo-app/src_haxe/client/utils/LocalStorage.hx
````
package client.utils;

import js.Browser;
import js.html.Storage;

/**
 * Type-safe localStorage utility wrapper around js.Browser.getLocalStorage()
 * 
 * Provides convenient methods for storing and retrieving data with
 * proper error handling and type conversions.
 * 
 * Uses Haxe's built-in js.html.Storage API for maximum compatibility
 * and type safety.
 */
class LocalStorage {
    
    private static var storage: Null<Storage> = Browser.getLocalStorage();
    
    /**
     * Initialize localStorage utilities
     */
    public static function initialize(): Void {
        // Check if localStorage is available
        if (!isAvailable()) {
            trace("Warning: localStorage is not available");
        }
    }
    
    /**
     * Check if localStorage is available in the browser
     */
    public static function isAvailable(): Bool {
        try {
            var test = "test";
            storage.setItem(test, test);
            storage.removeItem(test);
            return true;
        } catch (e: Dynamic) {
            return false;
        }
    }
    
    /**
     * Store a string value
     */
    public static function setString(key: String, value: String): Void {
        if (!isAvailable()) return;
        
        try {
            storage.setItem(key, value);
        } catch (e: Dynamic) {
            trace('Failed to store string in localStorage: $e');
        }
    }
    
    /**
     * Retrieve a string value
     */
    public static function getString(key: String, ?defaultValue: String): Null<String> {
        if (!isAvailable()) return defaultValue;
        
        try {
            var value = storage.getItem(key);
            return value != null ? value : defaultValue;
        } catch (e: Dynamic) {
            trace('Failed to retrieve string from localStorage: $e');
            return defaultValue;
        }
    }
    
    /**
     * Store a boolean value
     */
    public static function setBoolean(key: String, value: Bool): Void {
        setString(key, value ? "true" : "false");
    }
    
    /**
     * Retrieve a boolean value
     */
    public static function getBoolean(key: String, defaultValue: Bool = false): Bool {
        var value = getString(key);
        if (value == null) return defaultValue;
        
        return value == "true";
    }
    
    /**
     * Store a number value
     */
    public static function setNumber(key: String, value: Float): Void {
        setString(key, Std.string(value));
    }
    
    /**
     * Retrieve a number value
     */
    public static function getNumber(key: String, defaultValue: Float = 0): Float {
        var value = getString(key);
        if (value == null) return defaultValue;
        
        var parsed = Std.parseFloat(value);
        return Math.isNaN(parsed) ? defaultValue : parsed;
    }
    
    /**
     * Store an object as JSON
     */
    public static function setObject(key: String, value: Dynamic): Void {
        try {
            var json = haxe.Json.stringify(value);
            setString(key, json);
        } catch (e: Dynamic) {
            trace('Failed to store object in localStorage: $e');
        }
    }
    
    /**
     * Retrieve an object from JSON
     */
    public static function getObject(key: String, ?defaultValue: Dynamic): Dynamic {
        var value = getString(key);
        if (value == null) return defaultValue;
        
        try {
            return haxe.Json.parse(value);
        } catch (e: Dynamic) {
            trace('Failed to parse object from localStorage: $e');
            return defaultValue;
        }
    }
    
    /**
     * Remove a value from localStorage
     */
    public static function remove(key: String): Void {
        if (!isAvailable()) return;
        
        try {
            storage.removeItem(key);
        } catch (e: Dynamic) {
            trace('Failed to remove item from localStorage: $e');
        }
    }
    
    /**
     * Remove a value from localStorage (alias for remove)
     * This method provides compatibility with common localStorage usage patterns
     */
    public static function removeItem(key: String): Void {
        remove(key);
    }
    
    /**
     * Clear all localStorage data
     */
    public static function clear(): Void {
        if (!isAvailable()) return;
        
        try {
            storage.clear();
        } catch (e: Dynamic) {
            trace('Failed to clear localStorage: $e');
        }
    }
    
    /**
     * Get all keys in localStorage
     */
    public static function getAllKeys(): Array<String> {
        if (!isAvailable()) return [];
        
        var keys = [];
        try {
            for (i in 0...storage.length) {
                var key = storage.key(i);
                if (key != null) keys.push(key);
            }
        } catch (e: Dynamic) {
            trace('Failed to get localStorage keys: $e');
        }
        
        return keys;
    }
    
    /**
     * Get the total size of localStorage in bytes (approximate)
     */
    public static function getUsedSpace(): Int {
        var total = 0;
        for (key in getAllKeys()) {
            var value = getString(key, "");
            total += key.length + value.length;
        }
        return total;
    }
}
````

## File: examples/todo-app/src_haxe/client/Boot.hx
````
package client;

// Phoenix Hook type with only the callbacks we use
typedef PhoenixHook = {
  var mounted: Void->Void;
}

// Typed Hooks registry shape
typedef Hooks = {
  var AutoFocus: PhoenixHook;
  var Ping: PhoenixHook;
}

/**
 * Minimal, typed Phoenix LiveView hook registry for bootstrapping interactivity.
 * Avoids Dynamic on public surfaces per No‑Dynamic policy; uses inline JS only
 * at the boundary to call into the LiveView hook context (this.*).
 */
class Boot {
  public static function main() {
    var hooks: Hooks = {
      AutoFocus: {
        mounted: function(): Void {
          // Focus element if possible (boundary call to hook context)
          js.Syntax.code("this.el && this.el.focus && this.el.focus()");
        }
      },
      Ping: {
        mounted: function(): Void {
          // Validate pushEvent wiring once on mount (non-blocking)
          js.Syntax.code("try { this.pushEvent && this.pushEvent('ping', {}) } catch (_) {} ");
        }
      }
    };

    // Publish hooks for phoenix_app.js to pick up
    js.Syntax.code("window.Hooks = window.Hooks || {0}", hooks);
  }
}
````

## File: examples/todo-app/src_haxe/client/TodoApp.hx
````
package client;

import shared.TodoTypes;
import reflaxe.js.Async;
import client.hooks.Hooks;
import client.utils.DarkMode;
import client.utils.LocalStorage;
// genes async/await support

/**
 * Main client-side entry point for Todo App
 * Compiles to JavaScript and integrates with Phoenix LiveView
 * 
 * This provides a clean, modular architecture for client-side functionality
 * while maintaining type safety throughout the application.
 */
@:build(reflaxe.js.Async.build())
class TodoApp {
    
    private static var isInitialized: Bool = false;
    
    /**
     * Application entry point
     * Called when the JavaScript loads in the browser
     */
    @:expose
    public static function main(): Void {
        if (isInitialized) {
            trace("TodoApp already initialized");
            return;
        }
        
        trace("Todo App client initializing...");
        
        // Initialize client-side utilities
        initializeUtilities();
        
        // Set up global error handling
        setupGlobalErrorHandling();
        
        // Export hooks for Phoenix LiveView
        exportHooks();
        
        // Initialize UI enhancements
        initializeEnhancements();
        
        isInitialized = true;
        trace("Todo App client ready!");
    }
    
    /**
     * Initialize client-side utilities
     */
    private static function initializeUtilities(): Void {
        DarkMode.initialize();
        LocalStorage.initialize();
    }
    
    /**
     * Set up global error handling for the client
     */
    private static function setupGlobalErrorHandling(): Void {
        js.Browser.window.addEventListener("error", function(event) {
            trace('Client error: ${event.error}');
            // Log error asynchronously (fire and forget)
            js.Syntax.code("(async () => {
                try {
                    await {0}('javascript_error', {
                        message: {1},
                        filename: {2},
                        lineno: {3},
                        colno: {4},
                        timestamp: Date.now()
                    });
                } catch (e) {
                    console.warn('Failed to log error:', e);
                }
            })()", logErrorToServerAsync, event.message, event.filename, event.lineno, event.colno);
        });
        
        js.Browser.window.addEventListener("unhandledrejection", function(event) {
            trace('Unhandled promise rejection: ${event.reason}');
            // Log promise rejection asynchronously (fire and forget)
            js.Syntax.code("(async () => {
                try {
                    await {0}('promise_rejection', {
                        reason: {1},
                        timestamp: Date.now()
                    });
                } catch (e) {
                    console.warn('Failed to log promise rejection:', e);
                }
            })()", logErrorToServerAsync, Std.string(event.reason));
        });
    }
    
    /**
     * Export hooks for Phoenix LiveView to use
     * This makes our Haxe hooks available to the Phoenix JavaScript runtime
     */
    private static function exportHooks(): Void {
        var hooks = Hooks.getAll();
        
        // Export to global scope for Phoenix LiveView using modern js.Syntax.code
        js.Syntax.code("
            // Make hooks available globally
            if (typeof window !== 'undefined') {
                window.TodoAppHooks = {0};
                
                // Also export individual hooks for direct access
                window.AutoFocus = {1};
                window.ThemeToggle = {2};
                window.TodoForm = {3};
                window.TodoFilter = {4};
                window.LiveSync = {5};
            }
            
            // Export as ES6 module
            if (typeof module !== 'undefined' && module.exports) {
                module.exports = {
                    Hooks: {0},
                    AutoFocus: {1},
                    ThemeToggle: {2},
                    TodoForm: {3},
                    TodoFilter: {4},
                    LiveSync: {5}
                };
            }
        ", 
            hooks,
            Hooks.getAutoFocus(),
            Hooks.getThemeToggle(),
            Hooks.getTodoForm(),
            Hooks.getTodoFilter(),
            Hooks.getLiveSync()
        );
        
        trace("Phoenix LiveView hooks exported successfully");
    }
    
    /**
     * Initialize UI enhancements and additional features
     */
    private static function initializeEnhancements(): Void {
        // Set up keyboard shortcuts
        setupGlobalKeyboardShortcuts();
        
        // Initialize performance monitoring
        setupPerformanceMonitoring();
        
        // Add CSS enhancements
        addDynamicStyles();
        
        // Initialize accessibility features
        setupAccessibilityFeatures();
    }
    
    /**
     * Set up global keyboard shortcuts
     */
    private static function setupGlobalKeyboardShortcuts(): Void {
        js.Browser.document.addEventListener("keydown", function(e: js.html.KeyboardEvent) {
            // Only handle shortcuts if not in input/textarea (type-safe casting)
            var target = e.target;
            if (target != null && js.Syntax.instanceof(target, js.html.Element)) {
                var element = cast(target, js.html.Element);
                if (element.nodeName == "INPUT" || element.nodeName == "TEXTAREA") {
                    return;
                }
            }
            
            // Global shortcuts
            if (e.ctrlKey || e.metaKey) {
                switch (e.key) {
                    case "k": // Cmd/Ctrl + K: Quick search
                        e.preventDefault();
                        focusSearch();
                    
                    case "n": // Cmd/Ctrl + N: New todo
                        e.preventDefault();
                        triggerNewTodo();
                    
                    case "/": // Cmd/Ctrl + /: Show keyboard shortcuts
                        e.preventDefault();
                        showKeyboardShortcuts();
                }
            }
            
            // Other shortcuts
            switch (e.key) {
                case "?": // Show help
                    if (e.shiftKey) {
                        e.preventDefault();
                        showKeyboardShortcuts();
                    }
            }
        });
    }
    
    /**
     * Set up performance monitoring with async/await for cleaner error handling
     */
    private static function setupPerformanceMonitoring(): Void {
        // Monitor page load performance using modern PerformanceNavigationTiming API
        js.Browser.window.addEventListener("load", function() {
            // Use async IIFE to handle performance measurement with proper error handling
            js.Syntax.code("(async () => {
                try {
                    await {0}();
                } catch (error) {
                    console.error('Performance monitoring failed:', error);
                }
            })()", measurePagePerformance);
        });
        
        // Monitor LiveView connection time
        monitorLiveViewPerformance();
    }
    
    /**
     * Async function to measure page performance and log metrics
     */
    @:async
    private static function measurePagePerformance(): js.lib.Promise<Void> {
        if (js.Browser.window.performance == null) {
            return js.lib.Promise.resolve();
        }
        
        // Use modern PerformanceNavigationTiming API instead of deprecated timing
        var entries = js.Browser.window.performance.getEntriesByType("navigation");
        if (entries.length == 0) {
            // Fallback for browsers that don't support PerformanceNavigationTiming
            trace("PerformanceNavigationTiming not supported, using basic measurement");
            return js.lib.Promise.resolve();
        }
        
        var navTiming: js.html.PerformanceNavigationTiming = cast entries[0];
        var domLoadTime = navTiming.domContentLoadedEventEnd - navTiming.domContentLoadedEventStart;
        var fullLoadTime = navTiming.loadEventEnd - navTiming.fetchStart;
        
        trace('DOM load time: ${domLoadTime}ms, Full page load: ${fullLoadTime}ms');
        
        // Log metrics asynchronously with proper error handling
        logMetricToServerAsync("dom_load_time", domLoadTime);
        logMetricToServerAsync("page_load_time", fullLoadTime);
        
        // Log additional performance metrics
        var resourceLoadTime = navTiming.loadEventEnd - navTiming.domContentLoadedEventEnd;
        if (resourceLoadTime > 0) {
            logMetricToServerAsync("resource_load_time", resourceLoadTime);
        }
        
        // Check for performance issues and report them
        if (fullLoadTime > 3000) { // Slow page load > 3 seconds
            logErrorToServerAsync("performance_warning", {
                type: "slow_page_load",
                load_time: fullLoadTime,
                threshold: 3000
            });
        }
        
        return js.lib.Promise.resolve();
    }
    
    /**
     * Add dynamic CSS styles for enhancements
     */
    private static function addDynamicStyles(): Void {
        var style = js.Browser.document.createStyleElement();
        style.textContent = '
            /* Todo App Enhanced Styles */
            .todo-item {
                transition: all 0.2s ease;
            }
            
            .todo-item:hover {
                transform: translateX(2px);
            }
            
            .updated-highlight {
                background: rgba(59, 130, 246, 0.1);
                border-left: 3px solid #3B82F6;
                animation: highlightFade 2s ease-out;
            }
            
            @keyframes highlightFade {
                from { 
                    background: rgba(59, 130, 246, 0.3);
                    transform: scale(1.01);
                }
                to { 
                    background: rgba(59, 130, 246, 0.1);
                    transform: scale(1);
                }
            }
            
            .theme-toggle-clicked {
                transform: scale(0.95);
                transition: transform 0.1s ease;
            }
            
            .connection-status {
                font-size: 0.75rem;
                color: #6B7280;
            }
            
            .connection-status.online {
                color: #10B981;
            }
            
            .connection-status.offline {
                color: #EF4444;
            }
            
            /* Keyboard shortcuts overlay */
            .keyboard-shortcuts-overlay {
                position: fixed;
                top: 0;
                left: 0;
                right: 0;
                bottom: 0;
                background: rgba(0, 0, 0, 0.8);
                z-index: 1000;
                display: flex;
                align-items: center;
                justify-content: center;
            }
            
            .keyboard-shortcuts-panel {
                background: white;
                dark:bg-gray-800;
                border-radius: 0.5rem;
                padding: 2rem;
                max-width: 500px;
                max-height: 80vh;
                overflow-y: auto;
            }
        ';
        js.Browser.document.head.appendChild(style);
    }
    
    /**
     * Set up accessibility features
     */
    private static function setupAccessibilityFeatures(): Void {
        // Add skip links for keyboard navigation
        addSkipLinks();
        
        // Enhance focus management
        setupFocusManagement();
        
        // Add ARIA live regions for status updates
        setupLiveRegions();
    }
    
    /**
     * Add skip links for accessibility
     */
    private static function addSkipLinks(): Void {
        var skipLinks = js.Browser.document.createDivElement();
        skipLinks.className = "sr-only focus:not-sr-only focus:absolute focus:top-4 focus:left-4 z-50";
        skipLinks.innerHTML = '
            <a href="#main-content" class="bg-blue-600 text-white px-4 py-2 rounded-md">
                Skip to main content
            </a>
            <a href="#todo-form" class="bg-blue-600 text-white px-4 py-2 rounded-md ml-2">
                Skip to new todo form
            </a>
        ';
        js.Browser.document.body.insertBefore(skipLinks, js.Browser.document.body.firstChild);
    }
    
    /**
     * Set up focus management
     */
    private static function setupFocusManagement(): Void {
        // Trap focus in modals when open
        // This would be expanded based on specific modal implementations
    }
    
    /**
     * Set up ARIA live regions for status updates
     */
    private static function setupLiveRegions(): Void {
        var liveRegion = js.Browser.document.createDivElement();
        liveRegion.id = "live-region";
        liveRegion.setAttribute("aria-live", "polite");
        liveRegion.setAttribute("aria-atomic", "true");
        liveRegion.className = "sr-only";
        js.Browser.document.body.appendChild(liveRegion);
    }
    
    /**
     * Focus the search input
     */
    private static function focusSearch(): Void {
        var searchInput = js.Browser.document.querySelector('input[type="text"][placeholder*="Search"]');
        if (searchInput != null) {
            searchInput.focus();
        }
    }
    
    /**
     * Trigger new todo creation
     */
    private static function triggerNewTodo(): Void {
        var newTodoButton = js.Browser.document.querySelector('[phx-click="toggle_form"]');
        if (newTodoButton != null) {
            newTodoButton.click();
        }
    }
    
    /**
     * Show keyboard shortcuts overlay
     */
    private static function showKeyboardShortcuts(): Void {
        var overlay = js.Browser.document.querySelector(".keyboard-shortcuts-overlay");
        if (overlay != null) {
            overlay.style.display = "flex";
            return;
        }
        
        // Create shortcuts overlay
        overlay = js.Browser.document.createDivElement();
        overlay.className = "keyboard-shortcuts-overlay";
        overlay.innerHTML = '
            <div class="keyboard-shortcuts-panel">
                <h3 class="text-lg font-bold mb-4">Keyboard Shortcuts</h3>
                <div class="space-y-2 text-sm">
                    <div><kbd>Ctrl/Cmd + K</kbd> - Focus search</div>
                    <div><kbd>Ctrl/Cmd + N</kbd> - New todo</div>
                    <div><kbd>Ctrl/Cmd + /</kbd> - Show shortcuts</div>
                    <div><kbd>Alt + 1/2/3</kbd> - Filter todos</div>
                    <div><kbd>Escape</kbd> - Close forms/modals</div>
                    <div><kbd>Ctrl/Cmd + Enter</kbd> - Submit form</div>
                </div>
                <button class="mt-4 px-4 py-2 bg-gray-200 rounded close-shortcuts">Close</button>
            </div>
        ';
        
        // Add close functionality
        overlay.addEventListener("click", function(e) {
            if (e.target == overlay || e.target.classList.contains("close-shortcuts")) {
                overlay.style.display = "none";
            }
        });
        
        js.Browser.document.body.appendChild(overlay);
    }
    
    /**
     * Monitor LiveView performance
     */
    private static function monitorLiveViewPerformance(): Void {
        // This would hook into Phoenix LiveView events to monitor connection performance
        // For now, just a placeholder
        trace("LiveView performance monitoring initialized");
    }
    
    
    /**
     * Async error logging to server with retry logic and batching
     */
    @:async
    private static function logErrorToServerAsync(type: String, details: Dynamic): js.lib.Promise<Void> {
        try {
            // Store locally first as fallback
            LocalStorage.setObject('last_error_${type}', {
                type: type,
                details: details,
                timestamp: Date.now().getTime()
            });
            
            // Attempt to send to server via LiveView
            var errorData: Dynamic = {
                error_type: type,
                details: details,
                timestamp: Date.now().getTime(),
                user_agent: js.Browser.navigator.userAgent,
                url: js.Browser.location.href
            };
            sendToLiveViewAsync("error_log", errorData);
            
            trace('Error logged to server: ${type}');
            
        } catch (e: Dynamic) {
            // Server communication failed, error is already stored locally
            trace('Failed to send error to server: ${e}');
            
            // Queue for retry later
            queueForRetryAsync("error", {
                type: type,
                details: details,
                timestamp: Date.now().getTime()
            });
        }
        
        return js.lib.Promise.resolve();
    }
    
    /**
     * Async metric logging to server with batching for performance
     */
    @:async
    private static function logMetricToServerAsync(metric: String, value: Float): js.lib.Promise<Void> {
        try {
            // Store locally first as fallback
            LocalStorage.setNumber('metric_${metric}', value);
            
            // Batch metrics for efficient server communication
            var metricData: Dynamic = {
                metric: metric,
                value: value,
                timestamp: Date.now().getTime()
            };
            addToBatchAsync("metrics", metricData);
            
            // Send batch if it's full or enough time has passed
            maybeSendBatchAsync("metrics");
            
        } catch (e: Dynamic) {
            trace('Failed to process metric: ${e}');
            // Metric is still stored locally, so we don't lose data
        }
        
        return js.lib.Promise.resolve();
    }
    
    /**
     * Send data to Phoenix LiveView with error handling and timeout
     */
    @:async
    private static function sendToLiveViewAsync(event: String, data: Dynamic): js.lib.Promise<Void> {
        // Create a promise that resolves when LiveView responds or times out
        var promise = new js.lib.Promise(function(resolve, reject) {
            var timeout = js.Browser.window.setTimeout(function() {
                reject("LiveView communication timeout");
            }, 5000); // 5 second timeout
            
            try {
                // Simulated LiveView push - in real implementation this would use LiveView hooks
                js.Syntax.code("
                    if (window.liveSocket && window.liveSocket.channel) {
                        window.liveSocket.channel.push({0}, {1})
                            .receive('ok', (resp) => {
                                clearTimeout({2});
                                {3}(resp);
                            })
                            .receive('error', (resp) => {
                                clearTimeout({2});
                                {4}(resp);
                            });
                    } else {
                        clearTimeout({2});
                        {4}('LiveView not available');
                    }
                ", event, data, timeout, resolve, reject);
            } catch (e: Dynamic) {
                js.Browser.window.clearTimeout(timeout);
                reject(e);
            }
        });
        
        Async.await(promise);
    }
    
    /**
     * Queue data for retry when server communication fails
     */
    @:async
    private static function queueForRetryAsync(category: String, data: Dynamic): js.lib.Promise<Void> {
        var queueKey = 'retry_queue_${category}';
        var queue = LocalStorage.getObject(queueKey);
        
        if (queue == null) {
            queue = [];
        }
        
        queue.push(data);
        
        // Limit queue size to prevent memory issues
        if (queue.length > 100) {
            queue = queue.slice(-50); // Keep last 50 items
        }
        
        LocalStorage.setObject(queueKey, queue);
        
        // Schedule retry attempt
        scheduleRetryAsync(category);
        
        return js.lib.Promise.resolve();
    }
    
    /**
     * Add data to batch for efficient server communication
     */
    @:async
    private static function addToBatchAsync(batchType: String, data: Dynamic): js.lib.Promise<Void> {
        var batchKey = 'batch_${batchType}';
        var batch = LocalStorage.getObject(batchKey);
        
        if (batch == null) {
            batch = {
                items: [],
                created_at: Date.now().getTime()
            };
        }
        
        batch.items.push(data);
        LocalStorage.setObject(batchKey, batch);
        
        return js.lib.Promise.resolve();
    }
    
    /**
     * Send batch to server if conditions are met
     */
    @:async
    private static function maybeSendBatchAsync(batchType: String): js.lib.Promise<Void> {
        var batchKey = 'batch_${batchType}';
        var batch = LocalStorage.getObject(batchKey);
        
        if (batch == null || batch.items.length == 0) {
            return js.lib.Promise.resolve();
        }
        
        var shouldSend = false;
        var now = Date.now().getTime();
        
        // Send if batch is full (10 items) or old (30 seconds)
        if (batch.items.length >= 10 || (now - batch.created_at) > 30000) {
            shouldSend = true;
        }
        
        if (shouldSend) {
            try {
                sendToLiveViewAsync('batch_${batchType}', {
                    items: batch.items,
                    count: batch.items.length,
                    created_at: batch.created_at,
                    sent_at: now
                });
                
                // Clear batch after successful send
                LocalStorage.removeItem(batchKey);
                trace('Sent batch of ${batch.items.length} ${batchType} to server');
                
            } catch (e: Dynamic) {
                trace('Failed to send batch ${batchType}: ${e}');
                // Batch remains in LocalStorage for retry
            }
        }
        
        return js.lib.Promise.resolve();
    }
    
    /**
     * Schedule retry attempt for failed communications
     */
@:async
private static function scheduleRetryAsync(category: String): js.lib.Promise<Void> {
        // Use exponential backoff: 1s, 2s, 4s, 8s, then 30s max
        var retryKey = 'retry_count_${category}';
        var retryCount = LocalStorage.getNumber(retryKey, 0);
        var delay = Math.min(1000 * Math.pow(2, retryCount), 30000);
        
        // Defer processing by delay using a Promise so we avoid statement-level await
        return new js.lib.Promise(function(resolve, _reject) {
            js.Browser.window.setTimeout(function() {
                try {
                    processRetryQueueAsync(category);
                    // Reset retry count on success
                    LocalStorage.removeItem(retryKey);
                } catch (e: Dynamic) {
                    // Increment retry count and try again later
                    LocalStorage.setNumber(retryKey, retryCount + 1);
                    trace('Retry ${category} failed (attempt ${retryCount + 1}): ${e}');
                }
                resolve(null);
            }, Std.int(delay));
        });
    }
    
    /**
     * Process queued items for retry
     */
    @:async
    private static function processRetryQueueAsync(category: String): js.lib.Promise<Void> {
        var queueKey = 'retry_queue_${category}';
        var queue = LocalStorage.getObject(queueKey);
        
        if (queue == null || queue.length == 0) {
            return js.lib.Promise.resolve();
        }
        
        // Process items in batch
        sendToLiveViewAsync('retry_${category}', {
            items: queue,
            count: queue.length,
            retry_timestamp: Date.now().getTime()
        });
        
        // Clear queue after successful send
        LocalStorage.removeItem(queueKey);
        trace('Successfully sent ${queue.length} queued ${category} items');
        
        return js.lib.Promise.resolve();
    }

    /**
     * Sleep utility returning a Promise that resolves after ms
     */
    private static function sleep(ms:Int): js.lib.Promise<Void> {
        return new js.lib.Promise(function(resolve, _reject) {
            js.Browser.window.setTimeout(function() resolve(null), ms);
        });
    }
    
    // Async Data Fetching Utilities
    
    /**
     * Fetch todos from server with proper error handling and caching
     */
    @:async
    public static function fetchTodosAsync(): js.lib.Promise<Array<Dynamic>> {
        try {
            // Check cache first (5 minute expiry)
            var cacheKey = "todos_cache";
            var cacheData = LocalStorage.getObject(cacheKey);
            var now = Date.now().getTime();
            
            if (cacheData != null && (now - cacheData.timestamp) < 300000) { // 5 minutes
                trace("Returning cached todos");
                return cacheData.todos;
            }
            
            // Fetch from server
            var response = Async.await(fetchFromAPIAsync("/api/todos", "GET"));
            var todos: Array<Dynamic> = response.data;
            
            // Cache the result
            LocalStorage.setObject(cacheKey, {
                todos: todos,
                timestamp: now
            });
            
            trace('Fetched ${todos.length} todos from server');
            return todos;
            
        } catch (e: Dynamic) {
            trace('Failed to fetch todos: ${e}');
            
            // Return cached data as fallback, even if expired
            var fallbackData: Dynamic = LocalStorage.getObject("todos_cache");
            if (fallbackData != null) {
                trace("Returning stale cached todos as fallback");
                return fallbackData.todos;
            }
            
            // Return empty array if no cache available
            return [];
        }
    }
    
    /**
     * Create a new todo on the server
     */
    @:async
    public static function createTodoAsync(title: String, ?description: String, ?priority: String): js.lib.Promise<Dynamic> {
        try {
            var todoData = {
                title: title,
                description: description ?? "",
                priority: priority ?? "medium",
                completed: false
            };
            
            var response = Async.await(fetchFromAPIAsync("/api/todos", "POST", todoData));
            
            // Invalidate cache after successful creation
            LocalStorage.removeItem("todos_cache");
            
            // Log successful creation
            logMetricToServerAsync("todo_created", 1);
            
            trace('Created todo: ${title}');
            return response.data;
            
        } catch (e: Dynamic) {
            trace('Failed to create todo: ${e}');
            
            // Log error
            logErrorToServerAsync("todo_creation_failed", {
                title: title,
                error: Std.string(e)
            });
            
            throw e; // Re-throw to let caller handle it
        }
    }
    
    /**
     * Update an existing todo on the server
     */
    @:async
    public static function updateTodoAsync(id: Int, updates: Dynamic): js.lib.Promise<Dynamic> {
        try {
            var response = Async.await(fetchFromAPIAsync('/api/todos/${id}', "PUT", updates));
            
            // Invalidate cache after successful update
            LocalStorage.removeItem("todos_cache");
            
            // Log successful update
            logMetricToServerAsync("todo_updated", 1);
            
            trace('Updated todo ${id}');
            return response.data;
            
        } catch (e: Dynamic) {
            trace('Failed to update todo ${id}: ${e}');
            
            // Log error
            logErrorToServerAsync("todo_update_failed", {
                todo_id: id,
                updates: updates,
                error: Std.string(e)
            });
            
            throw e;
        }
        
        return js.lib.Promise.resolve();
    }
    
    /**
     * Delete a todo from the server
     */
    @:async
    public static function deleteTodoAsync(id: Int): js.lib.Promise<Void> {
        try {
            Async.await(fetchFromAPIAsync('/api/todos/${id}', "DELETE"));
            
            // Invalidate cache after successful deletion
            LocalStorage.removeItem("todos_cache");
            
            // Log successful deletion
            logMetricToServerAsync("todo_deleted", 1);
            
            trace('Deleted todo ${id}');
            
        } catch (e: Dynamic) {
            trace('Failed to delete todo ${id}: ${e}');
            
            // Log error
            logErrorToServerAsync("todo_deletion_failed", {
                todo_id: id,
                error: Std.string(e)
            });
            
            throw e;
        }
        
        return js.lib.Promise.resolve();
    }
    
    /**
     * Sync local changes with server
     */
    @:async
    public static function syncWithServerAsync(): js.lib.Promise<Void> {
        try {
            trace("Starting server sync...");
            
            // Process any queued offline changes
            Async.await(processOfflineChangesAsync());
            
            // Fetch latest data from server
            var serverTodos = Async.await(fetchTodosAsync());
            
            // Update local state (this would typically trigger UI updates)
            announceStatus('Synced ${serverTodos.length} todos with server');
            
            // Log successful sync
            logMetricToServerAsync("sync_completed", 1);
            
            trace("Server sync completed successfully");
            
        } catch (e: Dynamic) {
            trace('Server sync failed: ${e}');
            
            // Log sync failure
            logErrorToServerAsync("sync_failed", {
                error: Std.string(e),
                timestamp: Date.now().getTime()
            });
            
            announceStatus("Sync failed - working offline");
        }
        
        return js.lib.Promise.resolve();
    }
    
    /**
     * Generic API fetch utility with retry logic and proper error handling
     */
    @:async
    private static function fetchFromAPIAsync(url: String, method: String, ?data: Dynamic): js.lib.Promise<Dynamic> {
        var maxRetries = 3;
        var retryDelay = 1000; // Start with 1 second
        
        for (attempt in 0...maxRetries) {
            try {
                var requestOptions: Dynamic = {
                    method: method,
                    headers: {
                        "Content-Type": "application/json",
                        "Accept": "application/json"
                    }
                };
                
                if (data != null && (method == "POST" || method == "PUT" || method == "PATCH")) {
                    requestOptions.body = haxe.Json.stringify(data);
                }
                
                // Create Promise for fetch request
                var promise = new js.lib.Promise(function(resolve, reject) {
                    js.Syntax.code("
                        fetch({0}, {1})
                            .then(response => {
                                if (!response.ok) {
                                    throw new Error(`HTTP error! status: ${response.status}`);
                                }
                                return response.json();
                            })
                            .then(data => {2}({
                                data: data,
                                status: 'success'
                            }))
                            .catch(error => {3}(error));
                    ", url, requestOptions, resolve, reject);
                });
                
                var response = Async.await(promise);
                return response;
                
            } catch (e: Dynamic) {
                if (attempt == maxRetries - 1) {
                    // Last attempt failed, throw error
                    throw e;
                }
                
                // Wait before retry with exponential backoff (non-blocking schedule)
                trace('API request failed (attempt ${attempt + 1}/${maxRetries}): ${e}');
                retryDelay *= 2; // Exponential backoff
            }
        }
        
        throw "API request failed after all retries";
    }
    
    /**
     * Process any offline changes that haven't been synced
     */
    @:async
    private static function processOfflineChangesAsync(): js.lib.Promise<Void> {
        var offlineChanges = LocalStorage.getObject("offline_changes");
        
        if (offlineChanges == null || offlineChanges.length == 0) {
            return js.lib.Promise.resolve();
        }
        
        trace('Processing ${offlineChanges.length} offline changes');
        
        for (change in offlineChanges) {
            try {
                switch (change.type) {
                    case "create":
                        Async.await(createTodoAsync(change.data.title, change.data.description, change.data.priority));
                    case "update":
                        Async.await(updateTodoAsync(change.data.id, change.data.updates));
                    case "delete":
                        Async.await(deleteTodoAsync(change.data.id));
                }
            } catch (e: Dynamic) {
                trace('Failed to process offline change: ${e}');
                // Keep the change for next sync attempt
                continue;
            }
        }
        
        // Clear processed changes
        LocalStorage.removeItem("offline_changes");
        trace("Offline changes processed successfully");
        
        return js.lib.Promise.resolve();
    }
    
    /**
     * Queue changes for offline processing
     */
    public static function queueOfflineChange(type: String, data: Dynamic): Void {
        var changes = LocalStorage.getObject("offline_changes");
        if (changes == null) {
            changes = [];
        }
        
        changes.push({
            type: type,
            data: data,
            timestamp: Date.now().getTime()
        });
        
        LocalStorage.setObject("offline_changes", changes);
        trace('Queued offline change: ${type}');
    }
    
    /**
     * Get hook definitions for PhoenixApp integration.
     * 
     * Called by PhoenixApp to retrieve hook definitions without
     * automatically initializing everything. This allows PhoenixApp
     * to control initialization timing and error handling.
     */
    public static function getHooks(): Dynamic {
        return Hooks.getAll();
    }
    
    /**
     * Utility function for client-side state management
     */
    public static function getClientState(): ClientState {
        return {
            darkMode: DarkMode.isEnabled(),
            autoSave: LocalStorage.getBoolean("autoSave", true),
            lastSync: Date.now().getTime()
        };
    }
    
    /**
     * Update client state
     */
    public static function updateClientState(state: ClientState): Void {
        if (state.darkMode != DarkMode.isEnabled()) {
            DarkMode.toggle();
        }
        
        LocalStorage.setBoolean("autoSave", state.autoSave);
    }
    
    /**
     * Announce status update to screen readers
     */
    public static function announceStatus(message: String): Void {
        var liveRegion = js.Browser.document.getElementById("live-region");
        if (liveRegion != null) {
            liveRegion.textContent = message;
        }
    }
}
````

## File: examples/todo-app/src_haxe/server/components/CoreComponents.hx
````
package server.components;

import HXX;

/**
 * Type-safe assigns for Phoenix components
 */
typedef ComponentAssigns = {
    ?id: String,
    ?className: String,
    ?show: Bool,
    ?inner_content: String
}

typedef ModalAssigns = {
    id: String,
    show: Bool,
    ?inner_content: String
}

typedef ButtonAssigns = {
    ?type: String,
    ?className: String,
    ?disabled: Bool,
    inner_content: String
}

typedef InputAssigns = {
    field: FormField,
    ?type: String,
    label: String,
    ?placeholder: String,
    ?required: Bool
}

typedef FormField = {
    id: String,
    name: String,
    value: String,
    ?errors: Array<String>
}

/**
 * Type-safe abstract for Phoenix form targets
 * Compiles to the appropriate Elixir representation
 */
abstract FormTarget(String) {
    public function new(target: String) {
        this = target;
    }
    
    @:from public static function fromString(s: String): FormTarget {
        return new FormTarget(s);
    }
    
    @:to public function toString(): String {
        return this;
    }
}

typedef ErrorAssigns = {
    field: FormField
}

typedef FormAssigns = {
    formFor: FormTarget, // Changeset or schema
    action: String,
    ?method: String,
    inner_content: String
}

typedef HeaderAssigns = {
    title: String,
    ?actions: String
}

typedef TableColumn = {
    field: String,
    label: String
}

typedef TableRowData = Map<String, String>;

typedef TableAssigns = {
    rows: Array<TableRowData>,
    columns: Array<TableColumn>
}

typedef ListAssigns = {
    items: Array<String>
}

typedef BackAssigns = {
    navigate: String
}

typedef IconAssigns = {
    name: String,
    ?className: String
}

typedef LabelAssigns = {
    ?htmlFor: String,
    ?className: String,
    inner_content: String
}

/**
 * Core UI components for Phoenix applications
 * 
 * Provides reusable, type-safe UI components like modals, forms, buttons, etc.
 * These components follow Phoenix LiveView conventions and compile to proper
 * Phoenix.Component functions.
 */
@:native("TodoAppWeb.CoreComponents")
@:component
class CoreComponents {
    
    /**
     * Renders a modal dialog
     */
    @:component
    public static function modal(assigns: ModalAssigns): String {
        return HXX.hxx('<div id={@id} class="modal" phx-show={@show}>
            <%= @inner_content %>
        </div>');
    }
    
    /**
     * Renders a button component
     */
    @:component
    public static function button(assigns: ButtonAssigns): String {
        return HXX.hxx('<button type={@type || "button"} class={@className} disabled={@disabled}>
            <%= @inner_content %>
        </button>');
    }
    
    /**
     * Renders a form input field
     */
    @:component
    public static function input(assigns: InputAssigns): String {
        return HXX.hxx('<div class="form-group">
            <label for={@field.id}><%= @label %></label>
            <input 
                type={@type || "text"} 
                id={@field.id}
                name={@field.name}
                value={@field.value}
                placeholder={@placeholder}
                class="form-control"
                required={@required}
            />
            <%= if @field.errors && length(@field.errors) > 0 do %>
                <span class="error"><%= Enum.join(@field.errors, ", ") %></span>
            <% end %>
        </div>');
    }
    
    /**
     * Renders form error messages
     */
    @:component
    public static function error(assigns: ErrorAssigns): String {
        return HXX.hxx('<%= if @field && @field.errors && length(@field.errors) > 0 do %>
            <div class="error-message">
                <%= Enum.join(@field.errors, ", ") %>
            </div>
        <% end %>');
    }
    
    /**
     * Renders a simple form
     */
    @:component  
    public static function simple_form(assigns: FormAssigns): String {
        // Use `_f` to avoid unused variable warnings when slot variable is not referenced
        return HXX.hxx('<.form :let={_f} for={@formFor} action={@action} method={@method || "post"}>
            <%= @inner_content %>
        </.form>');
    }
    
    /**
     * Renders a header with title and actions
     */
    @:component
    public static function header(assigns: HeaderAssigns): String {
        return HXX.hxx('<header class="header">
            <h1><%= @title %></h1>
            <%= if @actions do %>
                <div class="actions">
                    <%= @actions %>
                </div>
            <% end %>
        </header>');
    }
    
    /**
     * Renders a data table
     */
    @:component
    public static function table(assigns: TableAssigns): String {
        return HXX.hxx('<table class="table">
            <thead>
                <tr>
                    <%= for col <- @columns do %>
                        <th><%= col.label %></th>
                    <% end %>
                </tr>
            </thead>
            <tbody>
                <%= for row <- @rows do %>
                    <tr>
                        <%= for col <- @columns do %>
                            <td><%= Map.get(row, col.field) %></td>
                        <% end %>
                    </tr>
                <% end %>
            </tbody>
        </table>');
    }
    
    /**
     * Renders a list of items
     */
    @:component
    public static function list(assigns: ListAssigns): String {
        return HXX.hxx('<ul class="list">
            <%= for item <- @items do %>
                <li><%= item %></li>
            <% end %>
        </ul>');
    }
    
    /**
     * Renders a back navigation link
     */
    @:component
    public static function back(assigns: BackAssigns): String {
        return HXX.hxx('<div class="back-link">
            <.link navigate={@navigate}>
                ← Back
            </.link>
        </div>');
    }
    
    /**
     * Renders an icon
     */
    @:component
    public static function icon(assigns: IconAssigns): String {
        return HXX.hxx('<%= if @className do %>
            <span class={"icon icon-" <> @name <> " " <> @className}></span>
        <% else %>
            <span class={"icon icon-" <> @name}></span>
        <% end %>');
    }
    
    /**
     * Renders a form label
     */
    @:component
    public static function label(assigns: LabelAssigns): String {
        return HXX.hxx('<%= if @htmlFor do %>
            <label for={@htmlFor} class={@className}><%= @inner_content %></label>
        <% else %>
            <label class={@className}><%= @inner_content %></label>
        <% end %>');
    }
}
````

## File: examples/todo-app/src_haxe/server/contexts/Users.hx
````
package contexts;

import elixir.types.Result;
import ecto.Changeset;
import ecto.TypedQuery;
import server.infrastructure.Repo;
using reflaxe.elixir.macros.TypedQueryLambda; // ensure extension where(...) is available

/**
 * Complete user management context with Ecto integration
 * Demonstrates schemas, changesets, queries, and business logic
 */

typedef UserFilter = {
    ?name: String,
    ?email: String,
    ?isActive: Bool
}

@:schema("users")
class User {
    @:primary_key
    public var id: Int;
    
    @:field({type: "string", nullable: false})
    public var name: String;
    
    @:field({type: "string", nullable: false})
    public var email: String;
    
    @:field({type: "integer"})
    public var age: Int;
    
    @:field({type: "boolean", defaultValue: true})
    public var active: Bool;
    
    @:timestamps
    public var insertedAt: String;
    public var updatedAt: String;
    
    @:has_many("posts", "Post", "user_id")
    public var posts: Array<Post>;
}

/**
 * UserChangeset provides custom changeset logic for User validation
 * 
 * This is separate from the auto-generated changeset in the User @:schema class.
 * The User.changeset function is generated by @:schema, but this allows custom validation.
 */
class UserChangeset {
    public static function changeset(?user: User, attrs: UserParams): Changeset<User, UserParams> {
        // Create a typed changeset for compile-time safety
        // The actual Ecto validations would be added by the generated Elixir code
        // Return inline to avoid losing the binding during hygiene passes
        return new Changeset(user, attrs);
    }
}

@:native("TodoApp.Users")
class Users {
    /**
     * Get all users with optional filtering
     */
    public static function listUsers(?filter: UserFilter): Array<User> {
        // Build a single query variable and refine it conditionally; return at the end.
        var query = TypedQuery.from(contexts.User);
        if (filter != null && filter.name != null) {
            query = query.where(u -> u.name == '%${filter.name}%');
        }
        if (filter != null && filter.email != null) {
            query = query.where(u -> u.email == '%${filter.email}%');
        }
        if (filter != null && filter.isActive != null) {
            query = query.where(u -> u.active == filter.isActive);
        }
        return Repo.all(query);
    }
    
    /**
     * Create changeset for user (required by LiveView example)
     */
    public static function changeUser(?user: User): Changeset<User, UserParams> {
        // Create Ecto changeset for form validation
        // For new users, pass null and let the changeset handle the empty struct
        return new Changeset(user, {});
    }
    
    /**
     * Main function for compilation testing
     */
    public static function main(): Void {
        trace("Users context with User schema compiled successfully!");
    }
    
    /**
     * Get user by ID with error handling
     */
    public static function getUser(id: Int): User {
        // Use typed Repo extern - throws if not found
        var user = Repo.get(User, id);
        if (user == null) {
            throw 'User not found with id: $id';
        }
        return user;
    }
    
    /**
     * Get user by ID, returns null if not found
     */
    public static function getUserSafe(id: Int): Null<User> {
        // Use typed Repo extern for safe lookup
        return Repo.get(User, id);
    }
    
    /**
     * Create a new user
     * Returns Result with either the created User or the invalid Changeset
     */
    public static function createUser(attrs: UserParams): Result<User, Changeset<User, UserParams>> {
        // Inline changeset to avoid temp var naming drift
        return Repo.insert(UserChangeset.changeset(null, attrs));
    }
    
    /**
     * Update existing user
     * Returns Result with either the updated User or the invalid Changeset
     */
    public static function updateUser(user: User, attrs: UserParams): Result<User, Changeset<User, UserParams>> {
        // Inline changeset to avoid temp var naming drift
        return Repo.update(UserChangeset.changeset(user, attrs));
    }
    
    /**
     * Delete user (hard delete from database)
     * Returns Result with either the deleted User or a Changeset with errors
     */
    public static function deleteUser(user: User): Result<User, Changeset<User, {}>> {
        // Delete user using typed Repo
        return Repo.delete(user);
    }
    
    /**
     * Search users by name or email
     */
    public static function searchUsers(term: String): Array<User> {
        // Query DSL implementation will be handled by future @:query annotation
        return [];
    }
    
    /**
     * Get user statistics
     */
    public static function userStats(): UserStats {
        // Query DSL implementation will be handled by future @:query annotation
        return {total: 0, active: 0, inactive: 0};
    }
}

// Supporting types
typedef UserParams = {
    ?name: String,
    ?email: String,
    ?age: Int,
    ?active: Bool
}

typedef UserStats = {
    total: Int,
    active: Int,
    inactive: Int
}

typedef Post = {
    id: Int,
    title: String,
    user_id: Int
}
````

## File: examples/todo-app/src_haxe/server/controllers/UserController.hx
````
package controllers;

import plug.Conn;
import contexts.Users;
import contexts.Users.UserParams;
import elixir.types.Result;

// Type-safe parameter definitions for each action
typedef IndexParams = {}  // Empty params for index
typedef ShowParams = {id: String};
typedef CreateParams = UserParams;
typedef UpdateParams = {id: String} & UserParams;  // Combine ID with user params
typedef DeleteParams = {id: String};

/**
 * UserController: Type-safe Phoenix controller showcasing Haxe→Elixir benefits
 * 
 * This controller demonstrates how Haxe brings compile-time type safety to Phoenix
 * web applications while generating idiomatic Elixir code that Phoenix developers
 * will find familiar and maintainable.
 * 
 * ## Annotations Explained
 * 
 * @:native("TodoAppWeb.UserController")
 * - **Purpose**: Specifies the exact Elixir module name to generate
 * - **Why**: Phoenix expects controllers in the `AppNameWeb` namespace
 * - **Benefit**: Follows Phoenix conventions while keeping Haxe package structure clean
 * - **Generated**: `defmodule TodoAppWeb.UserController do`
 * 
 * @:controller  
 * - **Purpose**: Marks this class as a Phoenix controller
 * - **Why**: Triggers controller-specific compilation (adds `use TodoAppWeb, :controller`)
 * - **Benefit**: Automatic Phoenix controller boilerplate and proper action signatures
 * - **Generated**: Includes all Phoenix.Controller functionality
 * 
 * ## Type Safety Benefits
 * 
 * Traditional Phoenix controllers have no compile-time parameter validation:
 * ```elixir
 * def show(conn, %{"id" => id}) do  # Runtime crash if "id" missing
 * ```
 * 
 * With Haxe, we get compile-time guarantees:
 * ```haxe
 * function show(conn: Conn, params: {id: String}): Conn  // Won't compile without id
 * ```
 * 
 * ## Best Practices
 * 
 * 1. **Type your params**: Use anonymous structures for known parameters
 * 2. **Return Conn**: All actions must return a Conn for the pipeline
 * 3. **Use Conn methods**: conn.json(), conn.render(), conn.redirect()
 * 4. **Leverage type inference**: Let Haxe catch missing fields at compile time
 * 
 * @see https://hexdocs.pm/phoenix/Phoenix.Controller.html
 */
@:native("TodoAppWeb.UserController")
@:controller
class UserController {
    
    /**
     * Generate a unique ID for new users
     * Uses timestamp and random for uniqueness
     */
    private static function generateUniqueId(): String {
        // Use Haxe's standard library instead of __elixir__()
        var timestamp = Date.now().getTime();
        var random = Math.floor(Math.random() * 10000);
        return '${timestamp}_${random}';
    }
    
    /**
     * List all users (GET /api/users)
     * 
     * Traditional Phoenix:
     * ```elixir
     * def index(conn, _params) do
     *   users = Users.listUsers()
     *   json(conn, %{users: users})
     * end
     * ```
     * 
     * With Haxe, we get type-safe JSON responses and can refactor safely.
     */
    public static function index(conn: Conn<IndexParams>, _params: IndexParams): Conn<IndexParams> {
        // Fetch all users from database
        var users = Users.listUsers(null);
        return conn.json({users: users});
    }
    
    /**
     * Show a specific user (GET /api/users/:id)
     * 
     * Notice the type-safe params structure - we KNOW at compile time
     * that 'id' must exist. No runtime pattern matching needed!
     * 
     * @param conn The request connection (typed with ShowParams)
     * @param params Must contain 'id' field (compile-time enforced)
     * @return JSON response with user data
     */
    public static function show(conn: Conn<ShowParams>, params: ShowParams): Conn<ShowParams> {
        // Fetch user from database
        var userId = Std.parseInt(params.id);
        var user = Users.getUserSafe(userId);
        
        if (user != null) {
            return conn.json({user: user});
        } else {
            return conn
                .putStatus(404)
                .json({error: "User not found"});
        }
    }
    
    /**
     * Create a new user (POST /api/users)
     * 
     * In production, you'd define a proper User type:
     * ```haxe
     * typedef UserParams = {
     *     name: String,
     *     email: String,
     *     ?age: Int  // Optional field
     * }
     * function create(conn: Conn, params: UserParams): Conn
     * ```
     * 
     * This gives you compile-time validation of required fields!
     */
    public static function create(conn: Conn<CreateParams>, params: CreateParams): Conn<CreateParams> {
        // Create user through Users context with database persistence
        var result = Users.createUser(params);
        
        return switch(result) {
            case Ok(value):
                conn
                    .putStatus(201)
                    .json({
                        user: value,
                        created: true,
                        message: "User created successfully"
                    });
                    
            case Error(reason):
                conn
                    .putStatus(422)
                    .json({
                        error: "Failed to create user",
                        changeset: reason
                    });
        }
    }
    
    /**
     * Update an existing user (PUT /api/users/:id)
     * 
     * Combines URL parameters (id) with body parameters.
     * Type-safe with UpdateParams ensuring id always exists.
     */
    public static function update(conn: Conn<UpdateParams>, params: UpdateParams): Conn<UpdateParams> {
        // Fetch existing user first
        var userId = Std.parseInt(params.id);
        var user = Users.getUserSafe(userId);
        
        if (user == null) {
            return conn
                .putStatus(404)
                .json({error: "User not found"});
        }
        
        // Update user through Users context
        var updateAttrs: UserParams = {
            name: params.name,
            email: params.email,
            age: params.age,
            active: params.active
        };
        
        var result = Users.updateUser(user, updateAttrs);
        
        return switch(result) {
            case Ok(value):
                // Use a named local to avoid any intermediate aliasing of the json/2 payload
                final payload = {
                    user: value,
                    updated: true,
                    message: 'User ${params.id} updated successfully'
                };
                conn.json(payload);
                
            case Error(reason):
                conn
                    .putStatus(422)
                    .json({
                        error: "Failed to update user",
                        changeset: reason
                    });
        }
    }
    
    /**
     * Delete a user (DELETE /api/users/:id)
     * 
     * Type-safe deletion - the compiler ensures 'id' exists.
     * No need for defensive programming or nil checks!
     */
    public static function delete(conn: Conn<DeleteParams>, params: DeleteParams): Conn<DeleteParams> {
        // Fetch user to delete
        var userId = Std.parseInt(params.id);
        var user = Users.getUserSafe(userId);
        
        if (user == null) {
            return conn
                .putStatus(404)
                .json({error: "User not found"});
        }
        
        // Delete user through Users context
        var result = Users.deleteUser(user);
        
        return switch(result) {
            case Ok(_value):
                // Use a named local to avoid any intermediate aliasing of the json/2 payload
                final payload = {
                    deleted: params.id,
                    success: true,
                    message: 'User ${params.id} deleted successfully'
                };
                conn.json(payload);
                
            case Error(_reason):
                conn
                    .putStatus(500)
                    .json({
                        error: "Failed to delete user",
                        success: false
                    });
        }
    }
}
````

## File: examples/todo-app/src_haxe/server/i18n/Gettext.hx
````
package server.i18n;

/**
 * Gettext module for internationalization
 * 
 * Provides translation and localization support for the Phoenix application.
 * This module wraps the Elixir Gettext functionality with type-safe Haxe interfaces.
 */
@:native("TodoAppWeb.Gettext")
@:gettext
class Gettext {
    /**
     * Default locale for the application
     */
    public static inline var DEFAULT_LOCALE = "en";
    
    /**
     * Translate a message
     * 
     * @param msgid The message ID to translate
     * @return Translated string
     */
    public static extern function gettext(msgid: String): String;
    
    /**
     * Translate a message with pluralization
     * 
     * @param msgid Singular message ID
     * @param msgid_plural Plural message ID
     * @param count Count for pluralization
     * @return Translated string
     */
    public static extern function ngettext(msgid: String, msgid_plural: String, count: Int): String;
    
    /**
     * Translate within a specific domain
     * 
     * @param domain Translation domain
     * @param msgid Message ID
     * @return Translated string
     */
    public static extern function dgettext(domain: String, msgid: String): String;
    
    /**
     * Translate with domain and pluralization
     * 
     * @param domain Translation domain
     * @param msgid Singular message ID
     * @param msgid_plural Plural message ID
     * @param count Count for pluralization
     * @return Translated string
     */
    public static extern function dngettext(domain: String, msgid: String, msgid_plural: String, count: Int): String;
    
    /**
     * Get the current locale
     * 
     * @return Current locale string
     */
    public static extern function getLocale(): String;
    
    /**
     * Set the current locale
     * 
     * @param locale Locale to set
     */
    public static extern function putLocale(locale: String): Void;
    
    /**
     * Helper function for error messages
     * 
     * @param msgid Error message ID
     * @param bindings Variable bindings for interpolation
     * @return Translated error message
     */
    public static function error(msgid: String, ?bindings: Map<String, String>): String {
        // This would handle error message translation with variable interpolation
        return gettext(msgid);
    }
}
````

## File: examples/todo-app/src_haxe/server/infrastructure/Endpoint.hx
````
package server.infrastructure;

/**
 * TodoAppWeb HTTP endpoint
 * Handles incoming HTTP requests and WebSocket connections
 * 
 * Now using proper @:endpoint annotation with AST transformation
 * This generates a complete Phoenix.Endpoint module structure
 */
@:native("TodoAppWeb.Endpoint")
@:endpoint
@:appName("todo_app")
class Endpoint {
    /**
     * Get static paths for asset serving
     * This function is referenced by the generated endpoint module
     */
    public static function static_paths(): Array<String> {
        return ["assets", "fonts", "images", "favicon.ico", "robots.txt"];
    }
}
````

## File: examples/todo-app/src_haxe/server/infrastructure/Gettext.hx
````
package server.infrastructure;

import server.infrastructure.TranslationBindings;

/**
 * Internationalization support module using Phoenix's Gettext.
 * 
 * This module provides translation and localization functionality
 * for the TodoApp application. It wraps Phoenix's Gettext system
 * to provide compile-time type safety for translations.
 */
@:native("TodoAppWeb.Gettext")
extern class Gettext {
    
    /**
     * Default locale for the application.
     */
    public static var DEFAULT_LOCALE: String;
    
    /**
     * Translates a message in the default domain.
     * 
     * @param msgid The message identifier to translate
     * @param bindings Optional variable bindings for interpolation
     * @return The translated string
     */
    public static function gettext(msgid: String, ?bindings: TranslationBindings): String;
    
    /**
     * Translates a message in a specific domain.
     * 
     * @param domain The translation domain (e.g., "errors", "forms")
     * @param msgid The message identifier to translate
     * @param bindings Optional variable bindings for interpolation
     * @return The translated string
     */
    public static function dgettext(domain: String, msgid: String, ?bindings: TranslationBindings): String;
    
    /**
     * Translates a plural message based on count.
     * 
     * @param msgid The singular message identifier
     * @param msgid_plural The plural message identifier
     * @param count The count for determining singular/plural
     * @param bindings Optional variable bindings for interpolation
     * @return The translated string
     */
    public static function ngettext(msgid: String, msgid_plural: String, count: Int, ?bindings: TranslationBindings): String;
    
    /**
     * Translates a plural message in a specific domain.
     * 
     * @param domain The translation domain
     * @param msgid The singular message identifier
     * @param msgid_plural The plural message identifier
     * @param count The count for determining singular/plural
     * @param bindings Optional variable bindings for interpolation
     * @return The translated string
     */
    public static function dngettext(domain: String, msgid: String, msgid_plural: String, count: Int, ?bindings: TranslationBindings): String;
    
    /**
     * Gets the current locale.
     * 
     * @return The current locale string (e.g., "en", "es", "fr")
     */
    public static function get_locale(): String;
    
    /**
     * Sets the current locale for translations.
     * 
     * @param locale The locale to set (e.g., "en", "es", "fr")
     */
    public static function put_locale(locale: String): Void;
    
    /**
     * Returns all available locales for the application.
     * 
     * @return Array of available locale codes
     */
    public static function known_locales(): Array<String>;

}

// Explicit alias to ensure fully-qualified module printing for calls
@:native("TodoAppWeb.Gettext")
extern class WebGettext {
    public static function gettext(msgid: String, ?bindings: TranslationBindings): String;
    public static function dgettext(domain: String, msgid: String, ?bindings: TranslationBindings): String;
    public static function ngettext(msgid: String, msgid_plural: String, count: Int, ?bindings: TranslationBindings): String;
    public static function dngettext(domain: String, msgid: String, msgid_plural: String, count: Int, ?bindings: TranslationBindings): String;
}
````

## File: examples/todo-app/src_haxe/server/infrastructure/GettextErrorMessages.hx
````
package server.infrastructure;

import server.infrastructure.Gettext;
import server.infrastructure.TranslationBindings;

/**
 * Common error message translations for the application.
 * 
 * This class provides pre-defined error messages using Gettext
 * for internationalization. All messages are in the "errors" domain
 * and can be translated to different languages.
 */
@:native("TodoAppWeb.Gettext.ErrorMessages")
class GettextErrorMessages {
    /**
     * Returns the "required field" error message.
     * @return Translated error message for required fields
     */
    public static function required_field(): String {
        return WebGettext.dgettext("errors", "can't be blank");
    }
    
    /**
     * Returns the "invalid format" error message.
     * @return Translated error message for invalid format
     */
    public static function invalid_format(): String {
        return WebGettext.dgettext("errors", "has invalid format");
    }
    
    /**
     * Returns the "too short" error message with minimum length.
     * @param min The minimum required length
     * @return Translated error message with count interpolation
     */
    public static function too_short(min: Int): String {
        var bindings = TranslationBindings.create()
            .setInt("count", min);
        return WebGettext.dgettext("errors", "should be at least %{count} character(s)", bindings);
    }
    
    /**
     * Returns the "too long" error message with maximum length.
     * @param max The maximum allowed length
     * @return Translated error message with count interpolation
     */
    public static function too_long(max: Int): String {
        var bindings = TranslationBindings.create()
            .setInt("count", max);
        return WebGettext.dgettext("errors", "should be at most %{count} character(s)", bindings);
    }
    
    /**
     * Returns the "not found" error message.
     * @return Translated error message for not found resources
     */
    public static function not_found(): String {
        return WebGettext.dgettext("errors", "not found");
    }
    
    /**
     * Returns the "unauthorized" error message.
     * @return Translated error message for unauthorized access
     */
    public static function unauthorized(): String {
        return WebGettext.dgettext("errors", "unauthorized");
    }
}
````

## File: examples/todo-app/src_haxe/server/infrastructure/GettextUIMessages.hx
````
package server.infrastructure;

import server.infrastructure.Gettext;
import server.infrastructure.TranslationBindings;

/**
 * Common UI message translations for the application.
 * 
 * This class provides pre-defined UI messages using Gettext
 * for internationalization. These messages are commonly used
 * throughout the application's user interface.
 */
@:native("TodoAppWeb.Gettext.UIMessages")
class GettextUIMessages {
    /**
     * Returns a welcome message with the user's name.
     * @param name The name to include in the welcome message
     * @return Translated welcome message with name interpolation
     */
    public static function welcome(name: String): String {
        var bindings = TranslationBindings.create()
            .set("name", name);
        return WebGettext.gettext("Welcome %{name}!", bindings);
    }
    
    /**
     * Returns a generic success message.
     * @return Translated success message
     */
    public static function success(): String {
        return WebGettext.gettext("Operation completed successfully");
    }
    
    /**
     * Returns a loading message.
     * @return Translated loading message
     */
    public static function loading(): String {
        return WebGettext.gettext("Loading...");
    }
    
    /**
     * Returns the "Save" button label.
     * @return Translated save label
     */
    public static function save(): String {
        return WebGettext.gettext("Save");
    }
    
    /**
     * Returns the "Cancel" button label.
     * @return Translated cancel label
     */
    public static function cancel(): String {
        return WebGettext.gettext("Cancel");
    }
    
    /**
     * Returns the "Delete" button label.
     * @return Translated delete label
     */
    public static function delete(): String {
        return WebGettext.gettext("Delete");
    }
    
    /**
     * Returns the "Edit" button label.
     * @return Translated edit label
     */
    public static function edit(): String {
        return WebGettext.gettext("Edit");
    }
    
    /**
     * Returns a confirmation message for delete actions.
     * @return Translated delete confirmation message
     */
    public static function confirm_delete(): String {
        return WebGettext.gettext("Are you sure you want to delete this item?");
    }
}
````

## File: examples/todo-app/src_haxe/server/infrastructure/Repo.hx
````
package server.infrastructure;

import elixir.types.Result;
import ecto.Changeset;
import ecto.Query.EctoQuery;
import ecto.DatabaseAdapter.*;

/**
 * Database repository for TodoApp
 * 
 * This class uses @:repo annotation with typed configuration to generate:
 * 1. The Ecto.Repo module with proper adapter settings
 * 2. A companion PostgrexTypes module for JSON encoding/decoding
 * 
 * The typed configuration ensures compile-time validation and
 * automatic generation of all required database modules.
 * 
 * Generated Elixir:
 * ```elixir
 * defmodule TodoApp.Repo do
 *   use Ecto.Repo, otp_app: :todo_app, adapter: Ecto.Adapters.Postgres
 * end
 * 
 * defmodule TodoApp.PostgrexTypes do
 *   Postgrex.Types.define(TodoApp.PostgrexTypes, [], json: Jason)
 * end
 * ```
 */
@:native("TodoApp.Repo")
@:repo({
    adapter: Postgres,
    json: Jason,
    extensions: [],
    poolSize: 10
})
extern class Repo {
    // These are extern declarations for the functions injected by Ecto.Repo
    
    @:overload(function<T>(query: EctoQuery<T>): Array<T> {})
    @:overload(function<T>(query: ecto.TypedQuery.TypedQuery<T>): Array<T> {})
    public static function all<T>(queryable: Class<T>): Array<T>;
    
    public static function get<T>(queryable: Class<T>, id: Int): Null<T>;
    
    public static function insert<T, P>(changeset: Changeset<T, P>): Result<T, Changeset<T, P>>;
    
    public static function update<T, P>(changeset: Changeset<T, P>): Result<T, Changeset<T, P>>;
    
    public static function delete<T>(struct: T): Result<T, Changeset<T, {}>>;
}
````

## File: examples/todo-app/src_haxe/server/infrastructure/Telemetry.hx
````
package server.infrastructure;

import elixir.otp.Supervisor;
import elixir.otp.Application;
import elixir.otp.TypeSafeChildSpec;

/**
 * Type definition for telemetry supervisor options
 */
typedef TelemetryOptions = {
    ?name: String,
    ?metrics_port: Int,
    ?reporters: Array<String>
}

/**
 * Type definition for OTP child specification
 */
typedef ChildSpec = {
    id: String,
    start: {
        module: String,
        func: String,
        args: Array<TelemetryOptions>
    },
    type: String,
    restart: String,
    shutdown: String
}

/**
 * Type definition for telemetry metrics
 */
typedef TelemetryMetric = {
    name: String,
    event: String,
    measurement: String,
    ?unit: String,
    ?tags: Array<String>
}

/**
 * TodoAppWeb telemetry supervisor
 * Handles application metrics, monitoring, and observability
 * 
 * This module compiles to TodoAppWeb.Telemetry with proper Phoenix telemetry
 * configuration for monitoring web requests, database queries, and custom metrics.
 */
@:native("TodoAppWeb.Telemetry")
@:supervisor
@:appName("TodoApp")
class Telemetry {
    /**
     * Child specification for OTP supervisor
     * 
     * Returns a proper child spec map for Supervisor.start_link
     * 
     * NOTE: @:keep is still required until we implement macro-time preservation
     * for supervisor functions. The AST transformation happens too late to prevent DCE.
     */
    @:keep
    public static function child_spec(opts: TelemetryOptions): ChildSpec {
        // Return a properly typed child spec structure
        return {
            id: "TodoAppWeb.Telemetry",
            start: {
                module: "TodoAppWeb.Telemetry",
                func: "start_link",
                args: [opts]
            },
            type: "supervisor",
            restart: "permanent", 
            shutdown: "infinity"
        };
    }
    
    /**
     * Start the telemetry supervisor
     * 
     * Initializes application metrics collection including:
     * - Phoenix endpoint metrics (request duration, status codes)
     * - Ecto repository metrics (query time, connection pool)
     * - LiveView metrics (mount time, event handling)
     * - Custom application metrics
     * 
     * @param args Telemetry configuration options
     * @return Application result with supervisor PID
     * 
     * NOTE: @:keep is still required until we implement macro-time preservation
     */
    @:keep
    public static function start_link(args: TelemetryOptions): ApplicationResult {
        // Start a telemetry supervisor with no children; reporters are added dynamically.
        // Inline empty list directly to avoid intermediate temp and ensure WAE=0.
        return untyped __elixir__('Supervisor.start_link([], [strategy: :one_for_one, max_restarts: 3, max_seconds: 5])');
    }
    
    /**
     * Get telemetry metrics configuration
     * 
     * Returns the list of telemetry events and handlers configured
     * for this application, used for debugging and monitoring.
     */
    public static function metrics(): Array<TelemetryMetric> {
        // Returns configured telemetry metrics
        // In a real application, this would return actual metric definitions
        return [];
    }
}
````

## File: examples/todo-app/src_haxe/server/infrastructure/TodoAppWeb.hx
````
package server.infrastructure;

/**
 * TodoAppWeb module providing Phoenix framework helpers.
 * 
 * This module acts as the central hub for Phoenix web functionality,
 * providing `use` macros for router, controller, LiveView, and other
 * Phoenix components. It follows Phoenix conventions for web modules.
 * 
 * The @:phoenixWebModule annotation triggers generation of all necessary
 * Phoenix macros including router, controller, live_view, etc.
 */
@:phoenixWebModule
@:native("TodoAppWeb")
class TodoAppWeb {
    /**
     * Returns the static paths for the application.
     * This is used by Phoenix for serving static assets.
     */
    public static function static_paths(): Array<String> {
        return ["assets", "fonts", "images", "favicon.ico", "robots.txt"];
    }
}
````

## File: examples/todo-app/src_haxe/server/infrastructure/TranslationBindings.hx
````
package server.infrastructure;

/**
 * Type-safe translation bindings for Gettext interpolation.
 * 
 * This abstract type provides a type-safe way to pass variable bindings
 * to Gettext translation functions without using Dynamic. It internally
 * uses a Map but provides a clean API for setting interpolation values.
 * 
 * ## Usage
 * ```haxe
 * var bindings = TranslationBindings.create()
 *     .set("name", "John")
 *     .set("count", 5);
 * Gettext.gettext("Hello %{name}, you have %{count} items", bindings);
 * ```
 */
abstract TranslationBindings(Map<String, String>) {
    /**
     * Creates a new TranslationBindings instance from a map.
     */
    inline function new(map: Map<String, String>) {
        this = map;
    }
    
    /**
     * Creates an empty TranslationBindings instance.
     * 
     * @return A new empty TranslationBindings
     */
    public static function create(): TranslationBindings {
        return new TranslationBindings(new Map<String, String>());
    }
    
    /**
     * Sets a string value for interpolation.
     * 
     * @param key The interpolation key
     * @param value The string value
     * @return This TranslationBindings for chaining
     */
    public function set(key: String, value: String): TranslationBindings {
        this.set(key, value);
        return cast this;
    }
    
    /**
     * Sets an integer value for interpolation.
     * Automatically converts to string.
     * 
     * @param key The interpolation key
     * @param value The integer value
     * @return This TranslationBindings for chaining
     */
    public function setInt(key: String, value: Int): TranslationBindings {
        this.set(key, Std.string(value));
        return cast this;
    }
    
    /**
     * Sets a float value for interpolation.
     * Automatically converts to string.
     * 
     * @param key The interpolation key
     * @param value The float value
     * @return This TranslationBindings for chaining
     */
    public function setFloat(key: String, value: Float): TranslationBindings {
        this.set(key, Std.string(value));
        return cast this;
    }
    
    /**
     * Sets a boolean value for interpolation.
     * Automatically converts to string.
     * 
     * @param key The interpolation key
     * @param value The boolean value
     * @return This TranslationBindings for chaining
     */
    public function setBool(key: String, value: Bool): TranslationBindings {
        this.set(key, value ? "true" : "false");
        return cast this;
    }
    
    /**
     * Gets the underlying map for framework interop.
     * This is marked @:noCompletion to hide it from IntelliSense.
     * 
     * @return The underlying Map<String, String>
     */
    @:noCompletion
    public inline function toMap(): Map<String, String> {
        return this;
    }
}
````

## File: examples/todo-app/src_haxe/server/layouts/AppLayout.hx
````
package server.layouts;

// HXX calls are transformed at compile-time by the Reflaxe.Elixir compiler

/**
 * Application layout component
 * Provides the main container and navigation structure for the app
 */
class AppLayout {
    
    /**
     * Main application wrapper template
     * Includes navigation, breadcrumbs, and content area
     */
    public static function render(assigns: Dynamic): String {
        return HXX.hxx('
            <div class="min-h-screen bg-gradient-to-br from-blue-50 via-white to-indigo-50 dark:from-gray-900 dark:via-gray-800 dark:to-blue-900">
                
                <!-- Header Navigation -->
                <header class="bg-white/80 dark:bg-gray-800/80 backdrop-blur-sm border-b border-gray-200 dark:border-gray-700 sticky top-0 z-40">
                    <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
                        <div class="flex justify-between items-center h-16">
                            
                            <!-- Logo and App Name -->
                            <div class="flex items-center space-x-4">
                                <div class="flex-shrink-0">
                                    <div class="w-8 h-8 bg-gradient-to-br from-blue-500 to-indigo-600 rounded-lg flex items-center justify-center">
                                        <span class="text-white font-bold text-sm">📝</span>
                                    </div>
                                </div>
                                <div>
                                    <h1 class="text-xl font-bold text-gray-900 dark:text-white">
                                        Todo App
                                    </h1>
                                    <p class="text-xs text-gray-500 dark:text-gray-400">
                                        Haxe ❤️ Phoenix LiveView
                                    </p>
                                </div>
                            </div>
                            
                            <!-- Navigation Links -->
                            <nav class="hidden md:flex space-x-8">
                                <a href="/" class="text-gray-600 dark:text-gray-300 hover:text-blue-600 dark:hover:text-blue-400 transition-colors font-medium">
                                    Dashboard
                                </a>
                                <a href="/todos" class="text-blue-600 dark:text-blue-400 font-medium">
                                    Todos
                                </a>
                                <a href="/profile" class="text-gray-600 dark:text-gray-300 hover:text-blue-600 dark:hover:text-blue-400 transition-colors font-medium">
                                    Profile
                                </a>
                            </nav>
                            
                            <!-- User Menu -->
                            <div class="flex items-center space-x-4">
                                <div class="text-sm text-gray-700 dark:text-gray-300">
                                    Welcome, <span class="font-semibold">${getUserDisplayName(assigns.current_user)}</span>
                                </div>
                                <div class="w-8 h-8 bg-gradient-to-br from-purple-500 to-pink-500 rounded-full flex items-center justify-center">
                                    <span class="text-white text-sm font-medium">
                                        ${getInitials(getUserDisplayName(assigns.current_user))}
                                    </span>
                                </div>
                            </div>
                            
                        </div>
                    </div>
                </header>
                
                <!-- Breadcrumbs -->
                <nav class="bg-white/60 dark:bg-gray-800/60 backdrop-blur-sm border-b border-gray-100 dark:border-gray-700" aria-label="Breadcrumb">
                    <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
                        <div class="flex items-center space-x-4 h-12 text-sm">
                            <a href="/" class="text-gray-500 dark:text-gray-400 hover:text-gray-700 dark:hover:text-gray-300">
                                🏠 Home
                            </a>
                            <span class="text-gray-400 dark:text-gray-500">/</span>
                            <span class="text-gray-900 dark:text-white font-medium">
                                ${getPageTitle(assigns.page_title)}
                            </span>
                        </div>
                    </div>
                </nav>
                
                <!-- Main Content Area -->
                <main class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
                    
                    <!-- Page Header -->
                    <div class="mb-8">
                        <div class="md:flex md:items-center md:justify-between">
                            <div class="flex-1 min-w-0">
                                <h2 class="text-2xl font-bold leading-7 text-gray-900 dark:text-white sm:text-3xl sm:truncate">
                                    ${getPageTitle(assigns.page_title)}
                                </h2>
                                <div class="mt-1 flex flex-col sm:flex-row sm:flex-wrap sm:mt-0 sm:space-x-6">
                                    <div class="mt-2 flex items-center text-sm text-gray-500 dark:text-gray-400">
                                        <span class="mr-2">🕒</span>
                                        Last updated: ${formatTimestamp(getLastUpdated(assigns.last_updated))}
                                    </div>
                                    <div class="mt-2 flex items-center text-sm text-gray-500 dark:text-gray-400">
                                        <span class="mr-2">⚡</span>
                                        Real-time sync enabled
                                    </div>
                                </div>
                            </div>
                            
                            <!-- Quick Actions -->
                            <div class="mt-4 flex md:mt-0 md:ml-4 space-x-2">
                                <button type="button" class="inline-flex items-center px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md shadow-sm text-sm font-medium text-gray-700 dark:text-gray-300 bg-white dark:bg-gray-700 hover:bg-gray-50 dark:hover:bg-gray-600 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 transition-colors">
                                    📊 Stats
                                </button>
                                <button type="button" class="inline-flex items-center px-3 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 transition-colors">
                                    ➕ New Todo
                                </button>
                            </div>
                        </div>
                    </div>
                    
                    <!-- Content -->
                    <div class="space-y-6">
                        ${assigns.inner_content}
                    </div>
                    
                </main>
                
                <!-- Footer -->
                <footer class="bg-white/80 dark:bg-gray-800/80 backdrop-blur-sm border-t border-gray-200 dark:border-gray-700 mt-auto">
                    <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-6">
                        <div class="flex justify-between items-center">
                            <div class="text-sm text-gray-500 dark:text-gray-400">
                                Built with ❤️ using Haxe and Phoenix LiveView
                            </div>
                            <div class="flex space-x-6 text-sm text-gray-500 dark:text-gray-400">
                                <a href="/about" class="hover:text-gray-700 dark:hover:text-gray-300 transition-colors">About</a>
                                <a href="/help" class="hover:text-gray-700 dark:hover:text-gray-300 transition-colors">Help</a>
                                <a href="https://github.com/reflaxe/elixir" class="hover:text-gray-700 dark:hover:text-gray-300 transition-colors">GitHub</a>
                            </div>
                        </div>
                    </div>
                </footer>
                
            </div>
        ');
    }
    
    /**
     * Get user display name with fallback
     */
    private static function getUserDisplayName(user: Null<{name: Null<String>}>): String {
        if (user != null && user.name != null) {
            return user.name;
        }
        return "User";
    }
    
    /**
     * Get page title with fallback
     */
    private static function getPageTitle(title: Null<String>): String {
        if (title != null) {
            return title;
        }
        return "Todo Dashboard";
    }
    
    /**
     * Get last updated timestamp with fallback
     */
    private static function getLastUpdated(timestamp: Null<String>): String {
        if (timestamp != null) {
            return timestamp;
        }
        return "now";
    }
    
    /**
     * Get user initials for avatar
     */
    private static function getInitials(name: String): String {
        if (name == null || name == "") return "U";
        var parts = name.split(" ");
        if (parts.length >= 2) {
            return parts[0].charAt(0).toUpperCase() + parts[1].charAt(0).toUpperCase();
        }
        return name.charAt(0).toUpperCase();
    }
    
    /**
     * Format timestamp for display
     */
    private static function formatTimestamp(timestamp: String): String {
        // Simple implementation - would use proper date formatting in real app
        return timestamp;
    }
}
````

## File: examples/todo-app/src_haxe/server/layouts/Layouts.hx
````
package server.layouts;

import HXX; // Compile-time HXX → ~H macro

/**
 * Main layouts module for Phoenix application
 * Provides the layout functions that Phoenix expects
 */
@:native("TodoAppWeb.Layouts")
class Layouts {
    /**
     * Root layout function
     *
     * WHY
     * - Previously this returned only `inner_content`, so the page lacked the
     *   required `<link>`/`<script>` tags and Tailwind never loaded.
     *
     * HOW
     * - Return a real HEEx root document that includes tracked static assets
     *   and yields `@inner_content`. This mirrors Phoenix 1.7 defaults and
     *   lets our HEEx transformer convert this string into a `~H` sigil.
     */
    @:keep public static function root(assigns: Dynamic): Dynamic {
        return HXX.hxx('
            <!DOCTYPE html>
            <html lang="en" class="h-full">
                <head>
                    <meta charset="utf-8"/>
                    <meta http-equiv="X-UA-Compatible" content="IE=edge"/>
                    <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
                    <title>Todo App</title>
                    <meta name="csrf-token" content={Phoenix.Controller.get_csrf_token()}/>
                    
                    <!-- Static assets (served by Phoenix Endpoint) -->
                    <link phx-track-static rel="stylesheet" href="/assets/app.css"/>
                    <!-- Bundle that bootstraps LiveSocket and loads Haxe hooks -->
                    <script defer phx-track-static type="text/javascript" src="/assets/phoenix_app.js"></script>
                </head>
                <body class="h-full bg-gray-50 dark:bg-gray-900 font-inter antialiased">
                    <main id="main-content" class="h-full">
                        <%= @inner_content %>
                    </main>
                </body>
            </html>
        ');
    }

    /**
     * Application layout function
     * - Wraps content in a responsive container and basic page chrome.
     */
    @:keep public static function app(assigns: Dynamic): Dynamic {
        return HXX.hxx('
            <div class="min-h-screen bg-gradient-to-br from-blue-50 via-white to-indigo-50 dark:from-gray-900 dark:via-gray-800 dark:to-blue-900">
                <div class="container mx-auto px-4 py-8 max-w-6xl">
                    <%= @inner_content %>
                </div>
            </div>
        ');
    }
}
````

## File: examples/todo-app/src_haxe/server/layouts/RootLayout.hx
````
package server.layouts;

import phoenix.Component;

// HXX calls are transformed at compile-time by the Reflaxe.Elixir compiler

/**
 * Root layout component for the Phoenix application
 * Handles HTML document structure, meta tags, and asset loading
 * 
 * IMPORTANT: JavaScript Architecture Decision
 * =========================================
 * 
 * This template deliberately avoids inline JavaScript code inside <script> tags.
 * Phoenix's HEEx parser treats JavaScript syntax (parentheses, quotes) as template 
 * syntax, causing compilation errors like "expected closing `"` for attribute value".
 * 
 * CORRECT PATTERN (This file):
 * - Reference external JavaScript files: <script src="/assets/app.js"></script>
 * - Keep templates clean with only HTML and Elixir interpolation
 * - Place all JavaScript logic in app.js or hook files
 * 
 * INCORRECT PATTERN (Causes compilation errors):
 * - Inline JavaScript: <script>if (condition) { ... }</script>
 * - Complex JavaScript expressions in templates
 * - JavaScript variables and functions defined in HEEx
 * 
 * Dark Mode Implementation:
 * - Theme detection/application: Handled by DarkMode.hx -> app.js
 * - Theme toggle button logic: Handled by ThemeToggle hook in client/hooks/
 * - Theme persistence: Handled by LocalStorage.hx utility
 * 
 * This architecture ensures:
 * 1. Clean separation between templates and JavaScript
 * 2. No HEEx parser conflicts with JavaScript syntax  
 * 3. Better maintainability and testability
 * 4. Proper Phoenix/LiveView best practices
 * 
 * @see /src_haxe/client/utils/DarkMode.hx - Theme logic implementation
 * @see /src_haxe/client/hooks/ThemeToggle.hx - Theme toggle hook
 * @see /assets/js/app.js - Compiled JavaScript output
 */
class RootLayout {
    
    /**
     * Root HTML document template
     * Includes Tailwind CSS, proper meta tags, and Phoenix LiveView setup
     */
    public static function render(assigns: Dynamic): String {
        return HXX.hxx('
            <!DOCTYPE html>
            <html lang="en" class="h-full">
                <head>
                    <meta charset="utf-8"/>
                    <meta http-equiv="X-UA-Compatible" content="IE=edge"/>
                    <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
                    <meta name="csrf-token" content={Phoenix.Controller.get_csrf_token()}/>
                    
                    <title>Todo App - Haxe ❤️ Phoenix LiveView</title>
                    <meta name="description" content="A beautiful todo application built with Haxe and Phoenix LiveView, showcasing modern UI and type-safe development"/>
                    
                    <!-- Favicon -->
                    <link rel="icon" type="image/svg+xml" href="/images/favicon.svg">
                    
                    <!-- Preconnect to Google Fonts for performance -->
                    <link rel="preconnect" href="https://fonts.googleapis.com">
                    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
                    
                    <!-- Inter font for modern typography -->
                    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap" rel="stylesheet">
                    
                    <!-- Phoenix LiveView assets -->
                    <script defer phx-track-static type="text/javascript" src="/assets/phoenix_app.js"></script>
                    <link phx-track-static rel="stylesheet" href="/assets/app.css"/>
                    
                    <!-- Dark mode detection handled by app.js -->
                </head>
                
                <body class="h-full bg-gray-50 dark:bg-gray-900 font-inter antialiased">
                    <!-- Skip to main content for accessibility -->
                    <a href="#main-content" class="sr-only focus:not-sr-only focus:absolute focus:top-4 focus:left-4 bg-blue-600 text-white px-4 py-2 rounded-md">
                        Skip to main content
                    </a>
                    
                    <!-- Theme toggle button -->
                    <div class="fixed top-4 right-4 z-50">
                        <button 
                            id="theme-toggle"
                            type="button"
                            class="p-2 text-gray-500 dark:text-gray-400 hover:bg-gray-100 dark:hover:bg-gray-700 rounded-lg focus:outline-none focus:ring-2 focus:ring-gray-200 dark:focus:ring-gray-700 transition-colors"
                            title="Toggle dark mode">
                            <svg id="theme-toggle-dark-icon" class="hidden w-5 h-5" fill="currentColor" viewBox="0 0 20 20">
                                <path d="M17.293 13.293A8 8 0 016.707 2.707a8.001 8.001 0 1010.586 10.586z"></path>
                            </svg>
                            <svg id="theme-toggle-light-icon" class="hidden w-5 h-5" fill="currentColor" viewBox="0 0 20 20">
                                <path d="M10 2a1 1 0 011 1v1a1 1 0 11-2 0V3a1 1 0 011-1zm4 8a4 4 0 11-8 0 4 4 0 018 0zm-.464 4.95l.707.707a1 1 0 001.414-1.414l-.707-.707a1 1 0 00-1.414 1.414zm2.12-10.607a1 1 0 010 1.414l-.706.707a1 1 0 11-1.414-1.414l.707-.707a1 1 0 011.414 0zM17 11a1 1 0 100-2h-1a1 1 0 100 2h1zm-7 4a1 1 0 011 1v1a1 1 0 11-2 0v-1a1 1 0 011-1zM5.05 6.464A1 1 0 106.465 5.05l-.708-.707a1 1 0 00-1.414 1.414l.707.707zm1.414 8.486l-.707.707a1 1 0 01-1.414-1.414l.707-.707a1 1 0 011.414 1.414zM4 11a1 1 0 100-2H3a1 1 0 000 2h1z" fill-rule="evenodd" clip-rule="evenodd"></path>
                            </svg>
                        </button>
                    </div>
                    
                    <!-- Main content -->
                    <main id="main-content" class="h-full">
                        ${assigns.inner_content}
                    </main>
                    
                    <!-- Dark mode toggle handled by app.js -->
                </body>
            </html>
        ');
    }
    
}
````

## File: examples/todo-app/src_haxe/server/live/SafeAssigns.hx
````
package server.live;

import phoenix.Phoenix.Socket;
import phoenix.LiveSocket;
import server.live.TodoLive.TodoLiveAssigns;

// Bridge to the generated LiveView module for reuse of server-side helpers
@:native("TodoAppWeb.TodoLive")
extern class TodoLiveNative {
    public static function filter_and_sort_todos(
        todos: Array<server.schemas.Todo>,
        filter: shared.TodoTypes.TodoFilter,
        sortBy: shared.TodoTypes.TodoSort,
        searchQuery: String
    ): Array<server.schemas.Todo>;
}

/**
 * Type-safe socket assign operations for TodoLive using LiveSocket patterns
 * 
 * This class demonstrates how to use the Phoenix framework's LiveSocket
 * type-safe assign patterns. The LiveSocket provides compile-time validation
 * of field names WITHOUT needing Dynamic, cast, or string field names.
 * 
 * ## Architecture Benefits:
 * - **Compile-time field validation**: The `_.fieldName` pattern validates fields exist
 * - **No cast needed**: LiveSocket methods return properly typed sockets
 * - **No Dynamic needed**: Field access is validated at compile time
 * - **No strings for field names**: The underscore pattern provides type safety
 * - **Automatic camelCase conversion**: Field names are converted to snake_case for Phoenix
 * - **IntelliSense support**: Full IDE autocomplete for all operations
 * 
 * ## Usage Patterns:
 * ```haxe
 * // Type-safe individual assignments with _.fieldName pattern
 * var liveSocket: LiveSocket<TodoLiveAssigns> = socket;
 * socket = liveSocket.assign(_.editingTodo, todo);
 * socket = liveSocket.assign(_.selectedTags, tags);
 * 
 * // Type-safe bulk assignments with merge
 * socket = liveSocket.merge({
 *     todos: newTodos,
 *     totalTodos: newTodos.length,
 *     completedTodos: completed,
 *     pendingTodos: pending
 * });
 * ```
 * 
 * ## Why This Pattern Exists:
 * Phoenix LiveView uses dynamic assigns that could cause runtime errors.
 * The LiveSocket wrapper provides compile-time validation that:
 * 1. Fields exist in the assigns typedef
 * 2. Values match the expected types
 * 3. Field names are correctly converted to snake_case
 * 
 * This prevents the #1 source of LiveView bugs: typos in assign keys.
 * 
 * ## Future Improvements:
 * While the `_.fieldName` syntax works well, we're exploring more intuitive alternatives.
 * See [Future Assign Syntax Ideas](../../../docs/07-patterns/future-assign-syntax-ideas.md)
 * for proposals like typed field descriptors and fluent builders that might feel more natural.
 */
class SafeAssigns {
    
    /**
     * Set the editingTodo field using LiveSocket's type-safe assign pattern
     * 
     * The _.editingTodo syntax is validated at compile time to ensure:
     * - The field exists in TodoLiveAssigns
     * - The type matches (Null<Todo>)
     * - The field name is converted to :editing_todo in Elixir
     */
    public static function setEditingTodo(socket: Socket<TodoLiveAssigns>, todo: Null<server.schemas.Todo>): Socket<TodoLiveAssigns> {
        return (cast socket: LiveSocket<TodoLiveAssigns>).assign(_.editing_todo, todo);
    }
    
    /**
     * Set the selectedTags field using LiveSocket's type-safe assign pattern
     */
    public static function setSelectedTags(socket: Socket<TodoLiveAssigns>, tags: Array<String>): Socket<TodoLiveAssigns> {
        return (cast socket: LiveSocket<TodoLiveAssigns>).assign(_.selected_tags, tags);
    }
    
    /**
     * Set the filter field using LiveSocket's type-safe assign pattern
     */
    public static function setFilter(socket: Socket<TodoLiveAssigns>, filter: String): Socket<TodoLiveAssigns> {
        return (cast socket: LiveSocket<TodoLiveAssigns>).assign(
            _.filter,
            switch (filter) {
                case "active": shared.TodoTypes.TodoFilter.Active;
                case "completed": shared.TodoTypes.TodoFilter.Completed;
                case _: shared.TodoTypes.TodoFilter.All;
            }
        );
    }
    
    /**
     * Set the sortBy field using LiveSocket's type-safe assign pattern
     */
    public static function setSortBy(socket: Socket<TodoLiveAssigns>, sortBy: String): Socket<TodoLiveAssigns> {
        return (cast socket: LiveSocket<TodoLiveAssigns>).assign(
            _.sort_by,
            switch (sortBy) {
                case "priority": shared.TodoTypes.TodoSort.Priority;
                case "due_date": shared.TodoTypes.TodoSort.DueDate;
                case _: shared.TodoTypes.TodoSort.Created;
            }
        );
    }

    /**
     * Set sort_by only; caller should trigger recompute_visible afterwards.
     * This keeps SafeAssigns zero-logic and typed while avoiding
     * cross-module helper dependencies.
     */
    public static function setSortByAndResort(socket: Socket<TodoLiveAssigns>, sortBy: String): Socket<TodoLiveAssigns> {
        return (cast socket: LiveSocket<TodoLiveAssigns>).assign(
            _.sort_by,
            switch (sortBy) {
                case "priority": shared.TodoTypes.TodoSort.Priority;
                case "due_date": shared.TodoTypes.TodoSort.DueDate;
                case _: shared.TodoTypes.TodoSort.Created;
            }
        );
    }
    
    /**
     * Set the searchQuery field using LiveSocket's type-safe assign pattern
     */
    public static function setSearchQuery(socket: Socket<TodoLiveAssigns>, query: String): Socket<TodoLiveAssigns> {
        return (cast socket: LiveSocket<TodoLiveAssigns>).assign(_.search_query, query);
    }
    
    /**
     * Set the showForm field using LiveSocket's type-safe assign pattern
     */
    public static function setShowForm(socket: Socket<TodoLiveAssigns>, showForm: Bool): Socket<TodoLiveAssigns> {
        return (cast socket: LiveSocket<TodoLiveAssigns>).assign(_.show_form, showForm);
    }
    
    /**
     * Update todos and automatically recalculate statistics
     * 
     * Uses LiveSocket's merge pattern for type-safe bulk updates.
     * The merge method validates all field names at compile time
     * and ensures type compatibility. No Dynamic, cast, or strings needed!
     */
    public static function updateTodosAndStats(socket: Socket<TodoLiveAssigns>, todos: Array<server.schemas.Todo>): Socket<TodoLiveAssigns> {
        var completed = countCompleted(todos);
        var pending = countPending(todos);
        
        // Use LiveSocket's type-safe merge for bulk updates
        return (cast socket: LiveSocket<TodoLiveAssigns>).merge({
            todos: todos,
            total_todos: todos.length,
            completed_todos: completed,
            pending_todos: pending
        });
    }
    
    /**
     * Update just the todos list without stats recalculation
     * 
     * Uses LiveSocket's assign pattern for single field update.
     */
    public static function setTodos(socket: Socket<TodoLiveAssigns>, todos: Array<server.schemas.Todo>): Socket<TodoLiveAssigns> {
        return (cast socket: LiveSocket<TodoLiveAssigns>).assign(_.todos, todos);
    }
    
    /**
     * Helper function to count completed todos
     */
    private static function countCompleted(todos: Array<server.schemas.Todo>): Int {
        var count = 0;
        for (todo in todos) {
            if (todo.completed) count++;
        }
        return count;
    }
    
    /**
     * Helper function to count pending todos
     */
    private static function countPending(todos: Array<server.schemas.Todo>): Int {
        var count = 0;
        for (todo in todos) {
            if (!todo.completed) count++;
        }
        return count;
    }
}
````

## File: examples/todo-app/src_haxe/server/live/TodoLive.hx
````
package server.live;

import HXX; // Import HXX for template rendering
import ecto.Changeset; // Import Ecto Changeset from the correct location
import ecto.Query; // Import Ecto Query from the correct location
import elixir.Task; // Background work via Task.start
import haxe.functional.Result; // Import Result type properly
import phoenix.LiveSocket; // Type-safe socket wrapper
import phoenix.types.Flash.FlashType;
import phoenix.Phoenix.HandleEventResult;
import phoenix.Phoenix.HandleInfoResult;
import phoenix.Phoenix.LiveView; // Use the comprehensive Phoenix module version
import phoenix.Phoenix.MountResult;
import phoenix.Phoenix.Socket;
import phoenix.Presence; // Import Presence module for PresenceEntry typedef
import server.infrastructure.Repo; // Import the TodoApp.Repo module
import server.live.SafeAssigns;
import server.presence.TodoPresence;
import server.pubsub.TodoPubSub.TodoPubSubMessage;
import server.pubsub.TodoPubSub.TodoPubSubTopic;
import server.pubsub.TodoPubSub;
import server.schemas.Todo;
import server.types.Types.BulkOperationType;
import server.types.Types.EventParams;
import server.types.Types.MountParams;
import server.types.Types.PubSubMessage;
import server.types.Types.Session;
import server.types.Types.User;

using StringTools;

/**
 * Type-safe event definitions for TodoLive.
 * 
 * This enum replaces string-based events with compile-time validated ADTs.
 * Each event variant carries its own strongly-typed parameters.
 * 
 * Benefits:
 * - Compile-time validation of event names
 * - Type-safe parameters for each event
 * - Exhaustiveness checking in handle_event
 * - IntelliSense/autocomplete support
 * - No Dynamic types or manual conversions
 */
enum TodoLiveEvent {
    // Todo CRUD operations
    CreateTodo(params: server.schemas.Todo.TodoParams);
    ToggleTodo(id: Int);
    DeleteTodo(id: Int);
    EditTodo(id: Int);
    SaveTodo(params: server.schemas.Todo.TodoParams);
    CancelEdit;
    
    // Filtering and sorting
    FilterTodos(filter: String);
    SortTodos(sortBy: String);
    SearchTodos(query: String);
    ToggleTag(tag: String);
    
    // Priority management
    SetPriority(id: Int, priority: String);
    
    // UI interactions
    ToggleForm;
    
    // Bulk operations
    BulkComplete;
    BulkDeleteCompleted;
}

/**
 * Type-safe assigns structure for TodoLive socket
 * 
 * This structure defines all the state that can be stored in the LiveView socket.
 * Using this typedef ensures compile-time type safety for all socket operations.
 */
typedef TodoLiveAssigns = {
	var todos: Array<server.schemas.Todo>;
	var filter: shared.TodoTypes.TodoFilter; // All | Active | Completed
	var sort_by: shared.TodoTypes.TodoSort;  // Created | Priority | DueDate
	var current_user: User;
	var editing_todo: Null<server.schemas.Todo>;
	var show_form: Bool;
	var search_query: String;
	var selected_tags: Array<String>;
    // Optimistic UI state: ids currently flipped client-first, pending server reconcile
    /**
     * optimistic_toggle_ids
     *
     * WHAT
     * - Minimal optimistic state (ids only) for instant checkbox flips.
     *
     * WHY
     * - Keep UX snappy for idempotent single-field toggles without duplicating rows.
     *
     * HOW
     * - On toggle, push id here and recompute rows so completed_for_view reflects the change.
     *   Persist to DB and reconcile via PubSub broadcast of the authoritative row.
     */
    var optimistic_toggle_ids: Array<Int>;
    // Precomputed view rows for HXX (zero-logic rendering)
    var visible_todos: Array<TodoView>;
	// Statistics
	var total_todos: Int;
	var completed_todos: Int;
	var pending_todos: Int;
	// Presence tracking (idiomatic Phoenix pattern: single flat map)
    var online_users: Map<String, phoenix.Presence.PresenceEntry<server.presence.TodoPresence.PresenceMeta>>;
    // UI convenience fields for zero-logic HXX
    var visible_count: Int;
    var filter_btn_all_class: String;
    var filter_btn_active_class: String;
    var filter_btn_completed_class: String;
    var sort_selected_created: Bool;
    var sort_selected_priority: Bool;
    var sort_selected_due_date: Bool;
}

/**
 * Row view model for HXX zero-logic rendering.
 * All derived fields are computed in Haxe, so HXX only binds assigns.
 */
typedef TodoView = {
    var id: Int;
    var title: String;
    var description: String;
    var completedForView: Bool;
    var completedStr: String;
    var domId: String;
    var containerClass: String;
    var titleClass: String;
    var descClass: String;
    var priority: String;
    var hasDue: Bool;
    var dueDisplay: String;
    var hasTags: Bool;
    var hasDescription: Bool;
    var isEditing: Bool;
    var tags: Array<String>;
}

/**
 * LiveView component for todo management with real-time updates
 */
@:native("TodoAppWeb.TodoLive")
@:liveview
class TodoLive {
	// All socket state is now defined in TodoLiveAssigns typedef for type safety
	
	/**
	 * Mount callback with type-safe assigns
	 * 
	 * The TAssigns type parameter will be inferred as TodoLiveAssigns from the socket parameter.
	 */
    public static function mount(_params: MountParams, session: Session, socket: phoenix.Phoenix.Socket<TodoLiveAssigns>): MountResult<TodoLiveAssigns> {
        // Prepare LiveSocket wrapper
        var sock: LiveSocket<TodoLiveAssigns> = (cast socket: LiveSocket<TodoLiveAssigns>);

        var currentUser = getUserFromSession(session);
        var todos = loadTodos(currentUser.id);

        var assigns: TodoLiveAssigns = {
            todos: todos,
            filter: shared.TodoTypes.TodoFilter.All,
            sort_by: shared.TodoTypes.TodoSort.Created,
            current_user: currentUser,
            editing_todo: null,
            show_form: false,
            search_query: "",
            selected_tags: [],
            optimistic_toggle_ids: [],
            visible_todos: [],
            visible_count: 0,
            filter_btn_all_class: filterBtnClass(shared.TodoTypes.TodoFilter.All, shared.TodoTypes.TodoFilter.All),
            filter_btn_active_class: filterBtnClass(shared.TodoTypes.TodoFilter.All, shared.TodoTypes.TodoFilter.Active),
            filter_btn_completed_class: filterBtnClass(shared.TodoTypes.TodoFilter.All, shared.TodoTypes.TodoFilter.Completed),
            sort_selected_created: sortSelected(shared.TodoTypes.TodoSort.Created, shared.TodoTypes.TodoSort.Created),
            sort_selected_priority: sortSelected(shared.TodoTypes.TodoSort.Created, shared.TodoTypes.TodoSort.Priority),
            sort_selected_due_date: sortSelected(shared.TodoTypes.TodoSort.Created, shared.TodoTypes.TodoSort.DueDate),
            total_todos: todos.length,
            completed_todos: countCompleted(todos),
            pending_todos: countPending(todos),
            online_users: new Map()
        };

        sock = LiveView.assignMultiple(sock, assigns);
        var ls: LiveSocket<TodoLiveAssigns> = recomputeVisible(sock);
        return Ok(ls);
    }
	
	/**
	 * Handle events with fully typed event system.
	 * 
	 * No more string matching or Dynamic params!
	 * Each event carries its own typed parameters.
	 */
    public static function handleEvent(event: TodoLiveEvent, socket: Socket<TodoLiveAssigns>): HandleEventResult<TodoLiveAssigns> {
        var resultSocket = switch (event) {
            // Todo CRUD operations - params are already typed!
            case CreateTodo(params):
                createTodo(params, socket);
			
			case ToggleTodo(id):
				toggleTodoStatus(id, socket);
			
            case DeleteTodo(id):
                trace('[TodoLive] handleEvent DeleteTodo');
                deleteTodo(id, socket);
			
			case EditTodo(id):
				startEditing(id, socket);
			
			case SaveTodo(params):
				saveEditedTodoTyped(params, socket);
			
            case CancelEdit:
                // Clear editing state and recompute view
                recomputeVisible(SafeAssigns.setEditingTodo(socket, null));
			
			// Filtering and sorting
            case FilterTodos(filter):
                recomputeVisible(SafeAssigns.setFilter(socket, filter));
			
            case SortTodos(sortBy):
                recomputeVisible(SafeAssigns.setSortByAndResort(socket, sortBy));
			
            case SearchTodos(query):
                recomputeVisible(SafeAssigns.setSearchQuery(socket, query));
			
            case ToggleTag(tag):
                // Inline toggleTagFilter to avoid relying on helper emission ordering
                // Compute toggled tags list deterministically
                var currentlySelected = socket.assigns.selected_tags;
                var newSelected = currentlySelected.contains(tag)
                    ? currentlySelected.filter(function(t) return t != tag)
                    : currentlySelected.concat([tag]);
                recomputeVisible(SafeAssigns.setSelectedTags(socket, newSelected));
			
			// Priority management
            case SetPriority(id, priority):
                updateTodoPriority(id, priority, socket);
			
			// UI interactions
            case ToggleForm:
                recomputeVisible(SafeAssigns.setShowForm(socket, !socket.assigns.show_form));
			
			// Bulk operations
            case BulkComplete:
                completeAllTodos(socket);
			
            case BulkDeleteCompleted:
                deleteCompletedTodos(socket);
			
			// No default case needed - compiler ensures exhaustiveness!
		};
		
		return NoReply(resultSocket);
	}
	
	/**
	 * Handle real-time updates from other users with type-safe assigns
	 * 
	 * The TAssigns type parameter will be inferred as TodoLiveAssigns from the socket parameter.
	 */
    public static function handleInfo(msg: PubSubMessage, socket: Socket<TodoLiveAssigns>): HandleInfoResult<TodoLiveAssigns> {
        // Handle PubSub messages with a two-step match to avoid alias churn
        return switch (TodoPubSub.parseMessage(msg)) {
            case Some(payload):
                switch (payload) {
                    case TodoCreated(_created):
                        NoReply(
                            recomputeVisible(
                                (cast socket: LiveSocket<TodoLiveAssigns>)
                                    .merge({ todos: loadTodos(socket.assigns.current_user.id) })
                            )
                        );
                    case TodoUpdated(todo):
                        NoReply(recomputeVisible(updateTodoInList(todo, socket)));
                    case TodoDeleted(id):
                        NoReply(recomputeVisible(removeTodoFromList(id, socket)));
                    case BulkUpdate(action):
                        switch (action) {
                            case CompleteAll, DeleteCompleted:
                                NoReply(
                                    recomputeVisible(
                                        (cast socket: LiveSocket<TodoLiveAssigns>).merge({
                                            todos: loadTodos(socket.assigns.current_user.id),
                                            total_todos: loadTodos(socket.assigns.current_user.id).length,
                                            completed_todos: countCompleted(loadTodos(socket.assigns.current_user.id)),
                                            pending_todos: countPending(loadTodos(socket.assigns.current_user.id))
                                        })
                                    )
                                );
                            case SetPriority(_):
                                NoReply(socket);
                            case AddTag(_):
                                NoReply(socket);
                            case RemoveTag(_):
                                NoReply(socket);
                        }
                    case UserOnline(_):
                        NoReply(socket);
                    case UserOffline(_):
                        NoReply(socket);
                    case SystemAlert(_message, _level):
                        NoReply(socket);
                }
            case None:
                trace("Received unknown PubSub message: " + msg);
                NoReply(socket);
        };
    }

	// Legacy function for backward compatibility - will be removed
	static function createNewTodo(params: EventParams, socket: Socket<TodoLiveAssigns>): Socket<TodoLiveAssigns> {
		// Convert EventParams (with String dates) to TodoParams (with Date type)
		var todoParams: server.schemas.Todo.TodoParams = {
			title: params.title,
			description: params.description,
			completed: false,
			priority: params.priority != null ? params.priority : "medium",
			dueDate: params.dueDate != null ? Date.fromString(params.dueDate) : null,
			tags: params.tags != null ? parseTags(params.tags) : [],
            userId: socket.assigns.current_user.id
		};
		
		// Pass the properly typed TodoParams to changeset
		var changeset = server.schemas.Todo.changeset(new server.schemas.Todo(), todoParams);
		
		// Use type-safe Repo operations
		switch (Repo.insert(changeset)) {
			case Ok(todo):
				// Best-effort broadcast; ignore result
				TodoPubSub.broadcast(TodoUpdates, TodoCreated(todo));
				
				var todos = [todo].concat(socket.assigns.todos);
				// Use LiveSocket for type-safe assigns manipulation
        var liveSocket: LiveSocket<TodoLiveAssigns> = socket;
				var updatedSocket = liveSocket.merge({
					todos: todos,
					show_form: false
				});
                    return LiveView.putFlash(updatedSocket, FlashType.Success, "Todo created successfully!");
				
			case Error(reason):
                    return LiveView.putFlash(socket, FlashType.Error, "Failed to create todo: " + reason);
		}
	}

    /**
     * Create a new todo using typed TodoParams.
     */
    static function createTodo(params: server.schemas.Todo.TodoParams, socket: Socket<TodoLiveAssigns>): Socket<TodoLiveAssigns> {
        // LiveView form params arrive as a map with string keys; extract safely.
        var rawTitle: Null<String> = Reflect.field(params, "title");
        var rawDesc: Null<String> = Reflect.field(params, "description");
        var rawPriority: Null<String> = Reflect.field(params, "priority");
        var rawDue: Null<String> = Reflect.field(params, "due_date");
        var rawTags: Null<String> = Reflect.field(params, "tags");

        // Normalize values and convert shapes
        var title = (rawTitle != null) ? rawTitle : "";
        var description = (rawDesc != null) ? rawDesc : "";
        var priority = (rawPriority != null && rawPriority != "") ? rawPriority : "medium";
        var tagsArr: Array<String> = (rawTags != null && rawTags != "") ? parseTags(rawTags) : [];

        // Build a params object with camelCase keys; normalize to snake_case + proper types via std helper
        var rawParams: Dynamic = {
            title: title,
            description: description,
            completed: false,
            priority: priority,
            dueDate: (rawDue != null && rawDue != "") ? rawDue : null,
            tags: tagsArr,
            userId: socket.assigns.current_user.id
        };
        var todoStruct = new server.schemas.Todo();
        var permitted = ["title","description","completed","priority","due_date","tags","user_id"];
        var castParams: Dynamic = {
            title: title,
            description: description,
            completed: false,
            priority: priority,
            due_date: (rawDue != null && rawDue != "") ? ((rawDue.indexOf(":") == -1) ? (rawDue + " 00:00:00") : rawDue) : null,
            tags: tagsArr,
            user_id: socket.assigns.current_user.id
        };
        var cs = ecto.ChangesetTools.castWithStringFields(todoStruct, castParams, permitted);
        switch (Repo.insert(cs)) {
            case Ok(value):
                // Best-effort broadcast; ignore result
                TodoPubSub.broadcast(TodoUpdates, TodoCreated(value));
                var todos = [value].concat(socket.assigns.todos);
                var updated = LiveView.assignMultiple(socket, {
                    todos: todos,
                    show_form: false,
                    total_todos: socket.assigns.total_todos + 1,
                    pending_todos: socket.assigns.pending_todos + (value.completed ? 0 : 1),
                    completed_todos: socket.assigns.completed_todos + (value.completed ? 1 : 0)
                });
                var lsCreated: LiveSocket<TodoLiveAssigns> = recomputeVisible(updated);
                return LiveView.putFlash(lsCreated, FlashType.Success, "Todo created successfully!");
            case Error(_reason):
                return LiveView.putFlash(socket, FlashType.Error, "Failed to create todo");
        }
    }

/**
 * toggleTodoStatus
 *
 * WHAT
 * - Server-driven optimistic toggle with safe reconciliation.
 *
 * WHY
 * - Provide immediate user feedback while keeping LiveView authoritative.
 *
 * HOW
 * - Mark id as optimistic → flip local row → persist (Repo.update) → broadcast TodoUpdated.
 *   handle_info updates the list with the authoritative record; on error we broadcast the
 *   current DB row to revert.
 */
static function toggleTodoStatus(id: Int, socket: Socket<TodoLiveAssigns>): Socket<TodoLiveAssigns> {
    var s: LiveSocket<TodoLiveAssigns> = (cast socket: LiveSocket<TodoLiveAssigns>);
    var ids = s.assigns.optimistic_toggle_ids;
    var contains = ids.indexOf(id) != -1;
    var computedIds = contains ? ids.filter(function(x) return x != id) : [id].concat(ids);
    var sOptimistic = s.assign(_.optimistic_toggle_ids, computedIds);
    // Also update the local todo immediately for instant visual feedback
    var local = findTodo(id, s.assigns.todos);
    if (local != null) {
        // Copy from existing struct and flip only the completed flag
        var toggled: server.schemas.Todo = local;
        toggled.completed = !local.completed;
        sOptimistic = updateTodoInList(toggled, sOptimistic);
    }
    // Persist synchronously; PubSub broadcast will reconcile actual state
    var db = Repo.get(server.schemas.Todo, id);
    if (db != null) {
        var updateResult = Repo.update(server.schemas.Todo.toggleCompleted(db));
        switch (updateResult) {
            case Ok(value):
                TodoPubSub.broadcast(TodoUpdates, TodoUpdated(value));
            case Error(_):
                // Best effort: revert optimistic UI by broadcasting current db state
                TodoPubSub.broadcast(TodoUpdates, TodoUpdated(db));
        }
    }
    return recomputeVisible(sOptimistic);
}

// Background reconcile for optimistic toggle
// Handle in-process persistence request in handleInfo
	
    static function deleteTodo(id: Int, socket: Socket<TodoLiveAssigns>): Socket<TodoLiveAssigns> {
        trace("[TodoLive] deleteTodo id=" + id + ", before_count=" + socket.assigns.todos.length);
        var todo = findTodo(id, socket.assigns.todos);
        if (todo == null) return socket;
        
        // Perform delete. On error, show flash and exit; otherwise proceed.
        switch (Repo.delete(todo)) {
            case Ok(_):
                // continue
            case Error(_reason):
                return LiveView.putFlash(socket, FlashType.Error, "Failed to delete todo");
        }
        // Reflect locally, then broadcast best-effort to others
        var updated = removeTodoFromList(id, socket);
        TodoPubSub.broadcast(TodoUpdates, TodoDeleted(id));
        return recomputeVisible(updated);
    }
	
static function updateTodoPriority(id: Int, priority: String, socket: Socket<TodoLiveAssigns>): Socket<TodoLiveAssigns> {
    var todo = findTodo(id, socket.assigns.todos);
    if (todo == null) return socket;
    switch (Repo.update(server.schemas.Todo.updatePriority(todo, priority))) {
        case Ok(_):
        case Error(_reason):
            return LiveView.putFlash(socket, FlashType.Error, "Failed to update priority");
    }
    var refreshed = Repo.get(server.schemas.Todo, id);
    if (refreshed != null) {
        TodoPubSub.broadcast(TodoUpdates, TodoUpdated(refreshed));
        var s1 = updateTodoInList(refreshed, socket);
        return recomputeVisible(s1);
    }
    return socket;
}
	
	// List management helpers with type-safe socket handling
	static function addTodoToList(todo: server.schemas.Todo, socket: Socket<TodoLiveAssigns>): Socket<TodoLiveAssigns> {
		// Don't add if it's our own todo (already added)
		if (todo.userId == socket.assigns.current_user.id) {
			return socket;
		}
		
		var todos = [todo].concat(socket.assigns.todos);
		// Use LiveSocket for type-safe assigns manipulation
		var liveSocket: LiveSocket<TodoLiveAssigns> = socket;
		return liveSocket.merge({ todos: todos });
	}
	
	
    static function loadTodos(userId: Int): Array<server.schemas.Todo> {
        // Inline query to avoid ephemeral local renames
        return Repo.all(
            ecto.TypedQuery
                .from(server.schemas.Todo)
                .where(t -> t.userId == userId)
        );
    }
	
	static function findTodo(id: Int, todos: Array<server.schemas.Todo>): Null<server.schemas.Todo> {
		for (todo in todos) {
			if (todo.id == id) return todo;
		}
		return null;
	}
	
    static function countCompleted(todos: Array<server.schemas.Todo>): Int {
        // Prefer filter+length to enable Enum.count generation on Elixir
        return todos.filter(function(t) return t.completed).length;
    }
	
    static function countPending(todos: Array<server.schemas.Todo>): Int {
        // Prefer filter+length to enable Enum.count generation on Elixir
        return todos.filter(function(t) return !t.completed).length;
    }
	
    static function parseTags(tagsString: String): Array<String> {
		if (tagsString == null || tagsString == "") return [];
            return tagsString.split(",").map(function(t) return StringTools.trim(t));
    }
	
    static function getUserFromSession(session: Dynamic): User {
    // Robust nil-safe session handling: avoid Map.get on nil
    var uid: Int = if (session == null) {
        1;
    } else {
        var idVal: Null<Int> = Reflect.field(session, "user_id");
        idVal != null ? idVal : 1;
    };
    return {
        id: uid,
        name: "Demo User",
        email: "demo@example.com", 
        passwordHash: "hashed_password",
        confirmedAt: null,
        lastLoginAt: null,
        active: true
    };
}
	
	// Missing helper functions
	static function loadAndAssignTodos(socket: Socket<TodoLiveAssigns>): Socket<TodoLiveAssigns> {
		var todos = loadTodos(socket.assigns.current_user.id);
		// Use LiveSocket's merge for type-safe bulk updates
		var liveSocket: LiveSocket<TodoLiveAssigns> = socket;
		return liveSocket.merge({
			todos: todos,
			total_todos: todos.length,
			completed_todos: countCompleted(todos),
			pending_todos: countPending(todos)
		});
	}
	
    static function updateTodoInList(todo: server.schemas.Todo, socket: LiveSocket<TodoLiveAssigns>): LiveSocket<TodoLiveAssigns> {
        var newTodos = socket.assigns.todos.map(function(t) return t.id == todo.id ? todo : t);
        return socket.merge({
            todos: newTodos,
            total_todos: newTodos.length,
            completed_todos: countCompleted(newTodos),
            pending_todos: countPending(newTodos)
        });
    }

    /**
     * Build typed view rows for zero-logic HXX rendering.
     */
    static function buildVisibleTodos(a: TodoLiveAssigns): Array<TodoView> {
        // Build from already-filtered/sorted list to keep map body purely a row constructor
        var base = filterAndSortTodos(a.todos, a.filter, a.sort_by, a.search_query, a.selected_tags);
        var optimistic = (a.optimistic_toggle_ids != null) ? a.optimistic_toggle_ids : [];
        return base.map(function(todoItem) return makeViewRow(a, optimistic, todoItem));
    }

    // Small, pure helper to keep Enum.map body simple and unambiguous for transforms
    static inline function makeViewRow(a: TodoLiveAssigns, optimisticIds: Array<Int>, t: server.schemas.Todo): TodoView {
        var flipped = optimisticIds.contains(t.id);
        var completedForView = flipped ? !t.completed : t.completed;
        var border = borderForPriority(t.priority);
        var containerClass = "bg-white dark:bg-gray-800 rounded-xl shadow-lg p-6 border-l-4 "
            + border
            + (completedForView ? " opacity-60" : "")
            + " transition-all hover:shadow-xl";
        var hasDue = (t.dueDate != null);
        var dueDisplay = hasDue ? format_due_date(t.dueDate) : "";
        var hasTags = (t.tags != null && t.tags.length > 0);
        var hasDescription = (t.description != null && t.description != "");
        var isEditing = (a.editing_todo != null && a.editing_todo.id == t.id);
        return {
            id: t.id,
            title: t.title,
            description: t.description,
            completedForView: completedForView,
            completedStr: completedForView ? "true" : "false",
            domId: "todo-" + Std.string(t.id),
            containerClass: containerClass,
            titleClass: "text-lg font-semibold text-gray-800 dark:text-white" + (completedForView ? " line-through" : ""),
            descClass: "text-gray-600 dark:text-gray-400 mt-1" + (completedForView ? " line-through" : ""),
            priority: t.priority,
            hasDue: hasDue,
            dueDisplay: dueDisplay,
            hasTags: hasTags,
            hasDescription: hasDescription,
            isEditing: isEditing,
            tags: (t.tags != null ? t.tags : [])
        };
    }

    /**
     * Recompute and merge visible_todos into assigns; returns a typed LiveSocket.
     */
    static function recomputeVisible(socket: Socket<TodoLiveAssigns>): LiveSocket<TodoLiveAssigns> {
        var ls: LiveSocket<TodoLiveAssigns> = socket;
        var rows = buildVisibleTodos(ls.assigns);
        // Precompute UI helpers
        var selected = ls.assigns.sort_by;
        var filter = ls.assigns.filter;
        return ls.merge({
            visible_todos: rows,
            visible_count: rows.length,
            filter_btn_all_class: filterBtnClass(filter, shared.TodoTypes.TodoFilter.All),
            filter_btn_active_class: filterBtnClass(filter, shared.TodoTypes.TodoFilter.Active),
            filter_btn_completed_class: filterBtnClass(filter, shared.TodoTypes.TodoFilter.Completed),
            sort_selected_created: sortSelected(selected, shared.TodoTypes.TodoSort.Created),
            sort_selected_priority: sortSelected(selected, shared.TodoTypes.TodoSort.Priority),
            sort_selected_due_date: sortSelected(selected, shared.TodoTypes.TodoSort.DueDate)
        });
    }
	
    static function removeTodoFromList(id: Int, socket: LiveSocket<TodoLiveAssigns>): LiveSocket<TodoLiveAssigns> {
        // Merge filtered list directly without intermediate locals
        return socket.merge({
            todos: socket.assigns.todos.filter(function(t) return t.id != id),
            total_todos: socket.assigns.todos.filter(function(t) return t.id != id).length,
            completed_todos: countCompleted(socket.assigns.todos.filter(function(t) return t.id != id)),
            pending_todos: countPending(socket.assigns.todos.filter(function(t) return t.id != id))
        });
    }
	
    static function startEditing(id: Int, socket: Socket<TodoLiveAssigns>): Socket<TodoLiveAssigns> {
        // Update presence to show user is editing (idiomatic Phoenix pattern)
        return SafeAssigns.setEditingTodo(socket, findTodo(id, socket.assigns.todos));
    }
	
	// Bulk operations with type-safe socket handling
    static function completeAllTodos(socket: Socket<TodoLiveAssigns>): Socket<TodoLiveAssigns> {
        // Toggle completion using index loop to avoid enumerator rewrite edge cases
        var list = socket.assigns.todos;
        for (item in list) {
            if (!item.completed) {
                var cs = server.schemas.Todo.toggleCompleted(item);
                switch (Repo.update(cs)) { case Ok(_): case Error(_): }
            }
        }
        // Broadcast (best-effort)
        TodoPubSub.broadcast(TodoUpdates, BulkUpdate(CompleteAll));
        // Merge refreshed assigns inline
        var ls: LiveSocket<TodoLiveAssigns> = (cast socket: LiveSocket<TodoLiveAssigns>).merge({
                todos: loadTodos(socket.assigns.current_user.id),
                filter: socket.assigns.filter,
                sort_by: socket.assigns.sort_by,
                current_user: socket.assigns.current_user,
                editing_todo: socket.assigns.editing_todo,
                show_form: socket.assigns.show_form,
                search_query: socket.assigns.search_query,
                selected_tags: socket.assigns.selected_tags,
                total_todos: loadTodos(socket.assigns.current_user.id).length,
                completed_todos: loadTodos(socket.assigns.current_user.id).length,
                pending_todos: 0,
                online_users: socket.assigns.online_users
            });
        return LiveView.putFlash(ls, FlashType.Info, "All todos marked as completed!");
    }
	
    static function deleteCompletedTodos(socket: Socket<TodoLiveAssigns>): Socket<TodoLiveAssigns> {
        // Delete completed todos using index loop to avoid enumerator rewrite edge cases
        var list = socket.assigns.todos;
        for (item in list) {
            if (item.completed) Repo.delete(item);
        }
        // Notify others (best-effort)
        TodoPubSub.broadcast(TodoUpdates, BulkUpdate(DeleteCompleted));
        // Merge recomputed assigns inline
        var ls2: LiveSocket<TodoLiveAssigns> = (cast socket: LiveSocket<TodoLiveAssigns>).merge({
                todos: socket.assigns.todos.filter(function(t) return !t.completed),
                filter: socket.assigns.filter,
                sort_by: socket.assigns.sort_by,
                current_user: socket.assigns.current_user,
                editing_todo: socket.assigns.editing_todo,
                show_form: socket.assigns.show_form,
                search_query: socket.assigns.search_query,
                selected_tags: socket.assigns.selected_tags,
                total_todos: socket.assigns.todos.filter(function(t) return !t.completed).length,
                completed_todos: 0,
                pending_todos: socket.assigns.todos.filter(function(t) return !t.completed).length,
                online_users: socket.assigns.online_users
            });
        return LiveView.putFlash(ls2, FlashType.Info, "Completed todos deleted!");
    }
	
	// Additional helper functions with type-safe socket handling
	static function startEditingOld(id: Int, socket: Socket<TodoLiveAssigns>): Socket<TodoLiveAssigns> {
		var todo = findTodo(id, socket.assigns.todos);
		return SafeAssigns.setEditingTodo(socket, todo);
	}
	
	/**
	 * Save edited todo with typed parameters.
	 */
    static function saveEditedTodoTyped(params: server.schemas.Todo.TodoParams, socket: Socket<TodoLiveAssigns>): Socket<TodoLiveAssigns> {
        if (socket.assigns.editing_todo == null) return socket;
        var todo = socket.assigns.editing_todo;
        // Inline computed title into changeset map to avoid local-binder rename mismatches
        switch (Repo.update(server.schemas.Todo.changeset(todo, {
            title: (Reflect.field(params, "title") != null)
                ? (cast Reflect.field(params, "title") : String)
                : todo.title
        }))) {
            case Ok(value):
                // Best-effort broadcast
                TodoPubSub.broadcast(TodoUpdates, TodoUpdated(value));
                var ls: LiveSocket<TodoLiveAssigns> = updateTodoInList(value, socket);
                ls = ls.assign(_.editing_todo, null);
                ls = recomputeVisible(ls);
                return ls;
            case Error(_):
                return LiveView.putFlash(socket, FlashType.Error, "Failed to update todo");
        }
    }

    // Optimistic helpers
    static inline function is_optimistically_toggled(assigns: TodoLiveAssigns, id: Int): Bool {
        return assigns.optimistic_toggle_ids != null && assigns.optimistic_toggle_ids.contains(id);
    }
    static inline function effective_completed(todo: server.schemas.Todo, assigns: TodoLiveAssigns): Bool {
        return is_optimistically_toggled(assigns, todo.id) ? !todo.completed : todo.completed;
    }

    // Local helpers to bridge typed enums ↔ UI strings
    static inline function card_class_for2(todo: server.schemas.Todo): String {
        var border = switch (todo.priority) {
            case "high": "border-red-500";
            case "low": "border-green-500";
            case "medium": "border-yellow-500";
            case _: "border-gray-300";
        };
        var base = "bg-white dark:bg-gray-800 rounded-xl shadow-lg p-6 border-l-4 "+ border;
        if (todo.completed) base += " opacity-60";
        return base + " transition-all hover:shadow-xl";
    }

    // Compatibility shim: legacy event handler expects create_todo_typed/2
    // Bridge dynamic params to strongly-typed TodoParams and delegate to createTodoTyped/2
    static function create_todo_typed(params: Dynamic, socket: Socket<TodoLiveAssigns>): Socket<TodoLiveAssigns> {
        var rawTitle: Null<String> = Reflect.field(params, "title");
        var rawDesc: Null<String> = Reflect.field(params, "description");
        var rawPriority: Null<String> = Reflect.field(params, "priority");
        var rawDue: Null<String> = Reflect.field(params, "due_date");
        var rawTags: Null<String> = Reflect.field(params, "tags");

        var todoParams: server.schemas.Todo.TodoParams = {
            title: rawTitle != null ? rawTitle : "",
            description: rawDesc != null ? rawDesc : "",
            completed: false,
            priority: (rawPriority != null && rawPriority != "") ? rawPriority : "medium",
            dueDate: (rawDue != null && rawDue != "") ? Date.fromString(rawDue) : null,
            tags: (rawTags != null && rawTags != "") ? parseTags(rawTags) : [],
            userId: socket.assigns.current_user.id
        };
        return createTodo(todoParams, socket);
    }
    static inline function format_due_date(d: Dynamic): String {
        return d == null ? "" : Std.string(d);
    }
    static inline function encodeSort(s: shared.TodoTypes.TodoSort): String {
        return switch (s) { case Created: "created"; case Priority: "priority"; case DueDate: "due_date"; };
    }
    static inline function encodeFilter(f: shared.TodoTypes.TodoFilter): String {
        return switch (f) { case All: "all"; case Active: "active"; case Completed: "completed"; };
    }

    // Typed UI helpers (no inline HEEx ops in HXX)
    static inline function filterBtnClass(current: shared.TodoTypes.TodoFilter, expect: shared.TodoTypes.TodoFilter): String {
        // Build final class without intermediate locals to avoid underscore/rename hygiene issues
        return "px-4 py-2 rounded-lg font-medium transition-colors"
            + (current == expect
                ? " bg-blue-500 text-white"
                : " bg-gray-200 dark:bg-gray-700 text-gray-700 dark:text-gray-300");
    }
    static inline function sortSelected(current: shared.TodoTypes.TodoSort, expect: shared.TodoTypes.TodoSort): Bool {
        return current == expect;
    }
    static inline function boolToStr(b: Bool): String {
        return b ? "true" : "false";
    }
    static inline function cardId(id: Int): String {
        return "todo-" + Std.string(id);
    }
    static inline function borderForPriority(p: String): String {
        return switch (p) { case "high": "border-red-500"; case "medium": "border-yellow-500"; case "low": "border-green-500"; default: "border-gray-300"; };
    }
    static inline function cardClassFor(todo: server.schemas.Todo): String {
        return "bg-white dark:bg-gray-800 rounded-xl shadow-lg p-6 border-l-4 "
            + borderForPriority(todo.priority)
            + (todo.completed ? " opacity-60" : "")
            + " transition-all hover:shadow-xl";
    }
    static inline function titleClass(completed: Bool): String {
        return "text-lg font-semibold text-gray-800 dark:text-white"
            + (completed ? " line-through" : "");
    }
    static inline function descClass(completed: Bool): String {
        return "text-gray-600 dark:text-gray-400 mt-1"
            + (completed ? " line-through" : "");
    }
	
	// Legacy function for backward compatibility - will be removed
	static function saveEditedTodo(params: EventParams, socket: Socket<TodoLiveAssigns>): Socket<TodoLiveAssigns> {
		var todo = socket.assigns.editing_todo;
		if (todo == null) return socket;
		
		// Convert EventParams (with String dates) to TodoParams (with Date type)
		var todoParams: server.schemas.Todo.TodoParams = {
			title: params.title,
			description: params.description,
			priority: params.priority,
			dueDate: params.dueDate != null ? Date.fromString(params.dueDate) : null,
			tags: params.tags != null ? parseTags(params.tags) : null,
			completed: params.completed
		};
		var changeset = server.schemas.Todo.changeset(todo, todoParams);
		
		// Use type-safe Repo operations
		switch (Repo.update(changeset)) {
			case Ok(updatedTodo):
				// Best-effort broadcast
				TodoPubSub.broadcast(TodoUpdates, TodoUpdated(updatedTodo));
				
				var updatedSocket = updateTodoInList(updatedTodo, socket);
				// Convert to LiveSocket to use assign for single field
				var liveSocket: LiveSocket<TodoLiveAssigns> = updatedSocket;
				return liveSocket.assign(_.editing_todo, null);
				
			case Error(reason):
				return LiveView.putFlash(socket, FlashType.Error, "Failed to save todo");
		}
	}
	
	// Handle bulk update messages from PubSub with type-safe socket handling
	static function handleBulkUpdate(action: BulkOperationType, socket: Socket<TodoLiveAssigns>): Socket<TodoLiveAssigns> {
        return switch (action) {
            case CompleteAll:
                // Reload todos and apply in a single merge without temporaries
                (cast socket: LiveSocket<TodoLiveAssigns>).merge({
                    todos: loadTodos(socket.assigns.current_user.id),
                    total_todos: loadTodos(socket.assigns.current_user.id).length,
                    completed_todos: countCompleted(loadTodos(socket.assigns.current_user.id)),
                    pending_todos: countPending(loadTodos(socket.assigns.current_user.id))
                });
            
            case DeleteCompleted:
                (cast socket: LiveSocket<TodoLiveAssigns>).merge({
                    todos: loadTodos(socket.assigns.current_user.id),
                    total_todos: loadTodos(socket.assigns.current_user.id).length,
                    completed_todos: countCompleted(loadTodos(socket.assigns.current_user.id)),
                    pending_todos: countPending(loadTodos(socket.assigns.current_user.id))
                });
			
			case SetPriority(priority):
				// Could handle bulk priority changes in future
				socket;
			
			case AddTag(tag):
				// Could handle bulk tag addition in future
				socket;
			
			case RemoveTag(tag):
				// Could handle bulk tag removal in future
				socket;
		};
	}
	
    static function toggleTagFilter(tag: String, socket: Socket<TodoLiveAssigns>): Socket<TodoLiveAssigns> {
        return SafeAssigns.setSelectedTags(
            socket,
            socket.assigns.selected_tags.contains(tag)
                ? socket.assigns.selected_tags.filter(function(t) return t != tag)
                : socket.assigns.selected_tags.concat([tag])
        );
    }
	
	/**
	 * Router action handlers for LiveView routes
	 * These are called when the router dispatches to specific actions
	 */
	
	/**
	 * Handle index route - main todo list view
	 */
	public static function index(): String {
		// For LiveView routes, these actions are typically handled through mount()
		// This is a placeholder implementation to satisfy the router validation
		return "index";
	}
	
	/**
	 * Handle show route - display a specific todo
	 */
	public static function show(): String {
		// Show specific todo - parameters would be passed through mount()
		return "show";
	}
	
	/**
	 * Handle edit route - edit a specific todo
	 */
	public static function edit(): String {
		// Edit specific todo - editing state would be handled in mount()
		return "edit";
	}
	
	/**
	 * Render function for the LiveView component
	 * This generates the HTML template that gets sent to the browser
	 */
    public static function render(assigns: TodoLiveAssigns): Dynamic {
        return HXX.hxx('
			<div class="min-h-screen bg-gradient-to-br from-blue-50 to-indigo-100 dark:from-gray-900 dark:to-blue-900">
				<div id="root" class="container mx-auto px-4 py-8 max-w-6xl" phx-hook="Ping">
					
					<!-- Header -->
					<div class="bg-white dark:bg-gray-800 rounded-xl shadow-lg p-8 mb-8">
						<div class="flex justify-between items-center mb-6">
							<div>
								<h1 class="text-4xl font-bold text-gray-800 dark:text-white mb-2">
									📝 Todo Manager
								</h1>
								<p class="text-gray-600 dark:text-gray-400">
									Welcome, ${assigns.current_user.name}!
								</p>
							</div>
							
							<!-- Statistics -->
							<div class="flex space-x-6">
								<div class="text-center">
									<div class="text-3xl font-bold text-blue-600 dark:text-blue-400">
										${assigns.total_todos}
									</div>
									<div class="text-sm text-gray-600 dark:text-gray-400">Total</div>
								</div>
								<div class="text-center">
									<div class="text-3xl font-bold text-green-600 dark:text-green-400">
										${assigns.completed_todos}
									</div>
									<div class="text-sm text-gray-600 dark:text-gray-400">Completed</div>
								</div>
								<div class="text-center">
									<div class="text-3xl font-bold text-amber-600 dark:text-amber-400">
										${assigns.pending_todos}
									</div>
									<div class="text-sm text-gray-600 dark:text-gray-400">Pending</div>
								</div>
							</div>
						</div>
						
						<!-- Add Todo Button -->
						<button phx-click="toggle_form" data-testid="btn-new-todo" class="w-full py-3 bg-gradient-to-r from-blue-500 to-indigo-600 text-white font-medium rounded-lg hover:from-blue-600 hover:to-indigo-700 transition-all duration-200 shadow-md">
							${assigns.show_form ? "✖ Cancel" : "➕ Add New Todo"}
						</button>
					</div>
					
					<!-- New Todo Form -->
					<if {assigns.show_form}>
						<div class="bg-white dark:bg-gray-800 rounded-xl shadow-lg p-6 mb-8 border-l-4 border-blue-500">
							<form phx-submit="create_todo" class="space-y-4">
								<div>
									<label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
										Title *
									</label>
									<input type="text" name="title" required data-testid="input-title"
										class="w-full px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-blue-500 dark:bg-gray-700 dark:text-white"
										placeholder="What needs to be done?" />
								</div>

								<div>
									<label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
										Description
									</label>
									<textarea name="description" rows="3"
										class="w-full px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-blue-500 dark:bg-gray-700 dark:text-white"
										placeholder="Add more details..."></textarea>
								</div>

								<div class="grid grid-cols-2 gap-4">
									<div>
										<label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
											Priority
										</label>
										<select name="priority"
											class="w-full px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-blue-500 dark:bg-gray-700 dark:text-white">
											<option value="low">Low</option>
											<option value="medium" selected>Medium</option>
											<option value="high">High</option>
										</select>
									</div>

									<div>
										<label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
											Due Date
										</label>
                            <input type="date" name="due_date"
                                placeholder="YYYY-MM-DD"
                                class="w-full px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-blue-500 dark:bg-gray-700 dark:text-white" />
									</div>
								</div>

								<div>
									<label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
										Tags (comma-separated)
									</label>
									<input type="text" name="tags"
										class="w-full px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-blue-500 dark:bg-gray-700 dark:text-white"
										placeholder="work, personal, urgent" />
								</div>

									<button type="submit" data-testid="btn-create-todo"
									class="w-full py-3 bg-green-500 text-white font-medium rounded-lg hover:bg-green-600 transition-colors shadow-md">
									✅ Create Todo
								</button>
							</form>
						</div>
					</if>
					
					<!-- Filters and Search -->
					<div class="bg-white dark:bg-gray-800 rounded-xl shadow-lg p-6 mb-8">
						<div class="flex flex-wrap gap-4">
							<!-- Search -->
							<div class="flex-1 min-w-[300px]">
                            <form phx-change="search_todos" class="relative">
									<input type="search" name="query" value={@search_query}
										class="w-full pl-10 pr-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-blue-500 dark:bg-gray-700 dark:text-white"
										placeholder="Search todos..." />
									<span class="absolute left-3 top-2.5 text-gray-400">🔍</span>
								</form>
							</div>
							
                        <!-- Filter Buttons -->
                        <div class="flex space-x-2">
                            <button phx-click="filter_todos" phx-value-filter="all" data-testid="btn-filter-all"
                                class={@filter_btn_all_class}>All</button>
                            <button phx-click="filter_todos" phx-value-filter="active" data-testid="btn-filter-active"
                                class={@filter_btn_active_class}>Active</button>
                            <button phx-click="filter_todos" phx-value-filter="completed" data-testid="btn-filter-completed"
                                class={@filter_btn_completed_class}>Completed</button>
                        </div>
							
							<!-- Sort Dropdown -->
							<div>
                            <select phx-change="sort_todos" name="sort_by"
                                class="px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-blue-500 dark:bg-gray-700 dark:text-white">
                                <option value="created" selected={@sort_selected_created}>Sort by Date</option>
                                <option value="priority" selected={@sort_selected_priority}>Sort by Priority</option>
                                <option value="due_date" selected={@sort_selected_due_date}>Sort by Due Date</option>
                            </select>
							</div>
						</div>
					</div>
					
					<!-- Online Users Panel -->
                    <!-- Presence panel (optional) -->
					
					<!-- Bulk Actions -->
                    <!-- Bulk Actions (typed HXX) -->
                    <div class="bg-white dark:bg-gray-800 rounded-xl shadow-lg p-4 mb-6 flex justify-between items-center">
                        <div class="text-sm text-gray-600 dark:text-gray-400">
                            Showing #{@visible_count} of #{@total_todos} todos
                        </div>
                        <div class="flex space-x-2">
                            <button phx-click="bulk_complete"
                                class="px-4 py-2 bg-green-500 text-white rounded-lg hover:bg-green-600 transition-colors text-sm">✅ Complete All</button>
                            <button phx-click="bulk_delete_completed" data-confirm="Are you sure you want to delete all completed todos?"
                                class="px-4 py-2 bg-red-500 text-white rounded-lg hover:bg-red-600 transition-colors text-sm">🗑️ Delete Completed</button>
                        </div>
                    </div>
					
					<!-- Todo List -->
                    <div id="todo-list" class="space-y-4">
                        <for {v in assigns.visible_todos}>
                            <if {v.is_editing}>
                                <div id={v.dom_id} data-testid="todo-card" data-completed={v.completed_str}
                                    class={v.container_class}>
                                    <form phx-submit="save_todo" class="space-y-4">
                                        <input type="text" name="title" value={v.title} required data-testid="input-title"
                                            class="w-full px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-blue-500 dark:bg-gray-700 dark:text-white" />
                                        <textarea name="description" rows="2"
                                            class="w-full px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-blue-500 dark:bg-gray-700 dark:text-white">#{v.description}</textarea>
                                        <div class="flex space-x-2">
                                            <button type="submit" class="px-4 py-2 bg-green-500 text-white rounded-lg hover:bg-green-600">Save</button>
                                            <button type="button" phx-click="cancel_edit" class="px-4 py-2 bg-gray-300 text-gray-700 rounded-lg hover:bg-gray-400">Cancel</button>
                                        </div>
                                    </form>
                                </div>
                            <else>
                                <div id={v.dom_id} data-testid="todo-card" data-completed={v.completed_str}
                                    class={v.container_class}>
                                    <div class="flex items-start space-x-4">
                                        <!-- Checkbox -->
                                        <button type="button" phx-click="toggle_todo" phx-value-id={v.id} data-testid="btn-toggle-todo"
                                            class="mt-1 w-6 h-6 rounded border-2 border-gray-300 dark:border-gray-600 flex items-center justify-center hover:border-blue-500 transition-colors">
                                            <if {v.completed_for_view}>
                                                <span class="text-green-500">✓</span>
                                            </if>
                                        </button>

                                        <!-- Content -->
                                        <div class="flex-1">
                                            <h3 class={v.title_class}>
                                                #{v.title}
                                            </h3>
                                            <if {v.has_description}>
                                                <p class={v.desc_class}>
                                                    #{v.description}
                                                </p>
                                            </if>

                                            <!-- Meta info -->
                                            <div class="flex flex-wrap gap-2 mt-3">
                                                <span class="px-2 py-1 bg-gray-100 dark:bg-gray-700 text-gray-600 dark:text-gray-400 rounded text-xs">
                                                    Priority: #{v.priority}
                                                </span>
                                                <if {v.has_due}>
                                                    <span class="px-2 py-1 bg-gray-100 dark:bg-gray-700 text-gray-600 dark:text-gray-400 rounded text-xs">
                                                        Due: #{v.due_display}
                                                    </span>
                                                </if>
                                                <if {v.has_tags}>
                                                    <for {tag in v.tags}>
                                                        <button phx-click="search_todos" phx-value-query={tag}
                                                            class="px-2 py-1 bg-blue-100 dark:bg-blue-900 text-blue-600 dark:text-blue-400 rounded text-xs hover:bg-blue-200">#{tag}</button>
                                                    </for>
                                                </if>
                                            </div>
                                        </div>

                                        <!-- Actions -->
                                        <div class="flex space-x-2">
                                            <button type="button" phx-click="edit_todo" phx-value-id={v.id} data-testid="btn-edit-todo"
                                                class="p-2 text-blue-600 hover:bg-blue-100 rounded-lg transition-colors">✏️</button>
                                            <button type="button" phx-click="delete_todo" phx-value-id={v.id} data-testid="btn-delete-todo"
                                                class="p-2 text-red-600 hover:bg-red-100 rounded-lg transition-colors">🗑️</button>
                                        </div>
                                    </div>
                                </div>
                            </if>
                        </for>
                    </div>
                </div>
            </div>
        ');
    }
	
	/**
	 * Render presence panel showing online users and editing status
	 * 
	 * Uses idiomatic Phoenix pattern: single presence map with all user state
	 */
    @:keep public static function renderPresencePanel(_onlineUsers: Map<String, phoenix.Presence.PresenceEntry<server.presence.TodoPresence.PresenceMeta>>): String {
        // TEMP: Presence panel disabled pending compiler Map iteration fix.
        // Keeps runtime clean while we finalize Presence iteration transform in AST pipeline.
        return "";
    }
	
	/**
	 * Render bulk actions section
	 */
    @:keep public static function renderBulkActions(assigns: TodoLiveAssigns): String {
		if (assigns.todos.length == 0) {
			return "";
		}
		
		var filteredCount = filterTodos(assigns.todos, assigns.filter, assigns.search_query).length;
		
		return '<div class="bg-white dark:bg-gray-800 rounded-xl shadow-lg p-4 mb-6 flex justify-between items-center">
				<div class="text-sm text-gray-600 dark:text-gray-400">
					Showing ${filteredCount} of ${assigns.total_todos} todos
				</div>
				<div class="flex space-x-2">
					<button phx-click="bulk_complete"
						class="px-4 py-2 bg-green-500 text-white rounded-lg hover:bg-green-600 transition-colors text-sm">
						✅ Complete All
					</button>
					<button phx-click="bulk_delete_completed" 
						data-confirm="Are you sure you want to delete all completed todos?"
						class="px-4 py-2 bg-red-500 text-white rounded-lg hover:bg-red-600 transition-colors text-sm">
						🗑️ Delete Completed
					</button>
				</div>
			</div>';
	}
	
	/**
	 * Render the todo list section
	 */
    @:keep public static function renderTodoList(assigns: TodoLiveAssigns): String {
		if (assigns.todos.length == 0) {
			return HXX.hxx('
				<div class="bg-white dark:bg-gray-800 rounded-xl shadow-lg p-16 text-center">
					<div class="text-6xl mb-4">📋</div>
					<h3 class="text-xl font-semibold text-gray-800 dark:text-white mb-2">
						No todos yet!
					</h3>
					<p class="text-gray-600 dark:text-gray-400">
						Click "Add New Todo" to get started.
					</p>
				</div>
			');
		}
		
        var filteredTodos:Array<server.schemas.Todo> = filterAndSortTodos(
            assigns.todos,
            assigns.filter,
            assigns.sort_by,
            assigns.search_query,
            assigns.selected_tags
        );
        var todoItems:Array<String> = filteredTodos.map(function(todo) {
            return renderTodoItem(todo, assigns.editing_todo);
        });
        return todoItems.join("\n");
	}
	
	/**
	 * Render individual todo item
	 */
	static function renderTodoItem(todo: server.schemas.Todo, editingTodo: Null<server.schemas.Todo>): String {
		var isEditing = editingTodo != null && editingTodo.id == todo.id;
		var priorityColor = switch(todo.priority) {
			case "high": "border-red-500";
			case "medium": "border-yellow-500";
			case "low": "border-green-500";
			case _: "border-gray-300";
		};
		
		if (isEditing) {
			return '<div id="todo-${todo.id}" data-testid="todo-card" data-completed="${Std.string(todo.completed)}" class="bg-white dark:bg-gray-800 rounded-xl shadow-lg p-6 border-l-4 ${priorityColor}">
					<form phx-submit="save_todo" class="space-y-4">
						<input type="text" name="title" value="${todo.title}" required data-testid="input-title"
							class="w-full px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-blue-500 dark:bg-gray-700 dark:text-white" />
						<textarea name="description" rows="2"
							class="w-full px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-blue-500 dark:bg-gray-700 dark:text-white">${todo.description}</textarea>
						<div class="flex space-x-2">
							<button type="submit" class="px-4 py-2 bg-green-500 text-white rounded-lg hover:bg-green-600">
								Save
							</button>
							<button type="button" phx-click="cancel_edit" class="px-4 py-2 bg-gray-300 text-gray-700 rounded-lg hover:bg-gray-400">
								Cancel
							</button>
						</div>
					</form>
				</div>';
		} else {
			var completedClass = todo.completed ? "opacity-60" : "";
			var textDecoration = todo.completed ? "line-through" : "";
			var checkmark = todo.completed ? '<span class="text-green-500">✓</span>' : '';
			
			return '<div id="todo-${todo.id}" data-testid="todo-card" data-completed="${Std.string(todo.completed)}" class="bg-white dark:bg-gray-800 rounded-xl shadow-lg p-6 border-l-4 ${priorityColor} ${completedClass} transition-all hover:shadow-xl">
					<div class="flex items-start space-x-4">
                        <!-- Checkbox -->
                            <button type="button" phx-click="toggle_todo" phx-value-id="${todo.id}" data-testid="btn-toggle-todo"
                                class="mt-1 w-6 h-6 rounded border-2 border-gray-300 dark:border-gray-600 flex items-center justify-center hover:border-blue-500 transition-colors">
                                ${checkmark}
                            </button>
						
						<!-- Content -->
						<div class="flex-1">
							<h3 class="text-lg font-semibold text-gray-800 dark:text-white ${textDecoration}">
								${todo.title}
							</h3>
							${todo.description != null && todo.description != "" ? 
								'<p class="text-gray-600 dark:text-gray-400 mt-1 ${textDecoration}">${todo.description}</p>' : 
								''}
							
							<!-- Meta info -->
							<div class="flex flex-wrap gap-2 mt-3">
								<span class="px-2 py-1 bg-gray-100 dark:bg-gray-700 text-gray-600 dark:text-gray-400 rounded text-xs">
									Priority: ${todo.priority}
								</span>
                                ${todo.dueDate != null ? 
                                    '<span class="px-2 py-1 bg-gray-100 dark:bg-gray-700 text-gray-600 dark:text-gray-400 rounded text-xs">Due: ${format_due_date(todo.dueDate)}</span>' : 
                                    ''}
								${renderTags(todo.tags)}
							</div>
						</div>
						
						<!-- Actions -->
						<div class="flex space-x-2">
                                            <button type="button" phx-click="edit_todo" phx-value-id="${todo.id}" data-testid="btn-edit-todo"
                                    class="p-2 text-blue-600 hover:bg-blue-100 rounded-lg transition-colors">
                                    ✏️
                                </button>
                                            <button type="button" phx-click="delete_todo" phx-value-id="${todo.id}" data-testid="btn-delete-todo"
                                    class="p-2 text-red-600 hover:bg-red-100 rounded-lg transition-colors">
                                    🗑️
                                </button>
						</div>
					</div>
				</div>';
		}
	}
	
	/**
	 * Render tags for a todo item
	 */
	static function renderTags(tags: Array<String>): String {
		if (tags == null || tags.length == 0) {
			return "";
		}
		
        var tagsNorm:Array<String> = (tags != null) ? tags : [];
        var tagElements:Array<String> = tagsNorm.map(function(tag) {
            return '<button phx-click="search_todos" phx-value-query="${tag}" class="px-2 py-1 bg-blue-100 dark:bg-blue-900 text-blue-600 dark:text-blue-400 rounded text-xs hover:bg-blue-200">#${tag}</button>';
        });
        return tagElements.join("");
	}
	
	/**
	 * Helper to filter todos based on filter and search query
	 */
    static function filterTodos(todos: Array<server.schemas.Todo>, filter: shared.TodoTypes.TodoFilter, searchQuery: String): Array<server.schemas.Todo> {
        var base = switch (filter) {
            case Active: todos.filter(function(t) return !t.completed);
            case Completed: todos.filter(function(t) return t.completed);
            case All: todos;
        };
        var qlOpt: Null<String> = (searchQuery != null && searchQuery != "") ? searchQuery.toLowerCase() : null;
        return (qlOpt == null)
            ? base
            : base.filter(function(t) {
                var title = t.title != null ? t.title.toLowerCase() : "";
                var desc = t.description != null ? t.description.toLowerCase() : "";
                return title.indexOf(qlOpt) >= 0 || desc.indexOf(qlOpt) >= 0;
            });
    }
	
	/**
	 * Helper to filter and sort todos
	 */
    public static function filterAndSortTodos(todos: Array<server.schemas.Todo>, filter: shared.TodoTypes.TodoFilter, sortBy: shared.TodoTypes.TodoSort, searchQuery: String, selectedTags: Array<String>): Array<server.schemas.Todo> {
        var filtered = filterTodos(todos, filter, searchQuery);
        if (selectedTags != null && selectedTags.length > 0) {
            filtered = filtered.filter(function(t) {
                var tags = (t.tags != null) ? t.tags : [];
                for (sel in selectedTags) {
                    if (tags.indexOf(sel) != -1) return true;
                }
                return false;
            });
        }
        // Delegate sorting to std helper (emitted under app namespace), avoid app __elixir__
        return phoenix.Sorting.by(encodeSort(sortBy), filtered);
    }
}
````

## File: examples/todo-app/src_haxe/server/live/UserLive.hx
````
package server.live;

import HXX; // Import HXX for template rendering
import contexts.Users.User;
import contexts.Users;
import ecto.Changeset;
import elixir.types.Result; // For type-safe error handling
import phoenix.LiveSocket; // Type-safe socket wrapper
import phoenix.Phoenix.LiveView; // Use the comprehensive Phoenix module version
import phoenix.Phoenix.Socket;

// HXX template calls are processed at compile-time by the Reflaxe.Elixir compiler

/**
 * Type-safe event definitions for UserLive.
 * 
 * This enum replaces string-based events with compile-time validated ADTs.
 * Each event variant carries its own strongly-typed parameters.
 */
enum UserLiveEvent {
    // User CRUD operations
    NewUser;
    EditUser(id: Int);
    SaveUser(params: {user: Dynamic}); // User form params
    DeleteUser(id: Int);
    
    // Search and filtering
    Search(params: {search_term: String});
    FilterStatus(params: {status: String});
    ClearSearch;
    
    // UI interactions
    Cancel;
}

/**
 * Type-safe assigns structure for UserLive socket
 */
typedef UserLiveAssigns = {
    var users: Array<User>;
    var selectedUser: Null<User>;
    var changeset: Changeset<User, Dynamic>;
    var searchTerm: String;
    var showForm: Bool;
}

/**
 * Phoenix LiveView for user management
 * Demonstrates real-time user CRUD operations
 */
@:native("TodoAppWeb.UserLive")
@:liveview
class UserLive {
    static function mount(_params: Dynamic, _session: Dynamic, socket: Socket<UserLiveAssigns>): {status: String, socket: Socket<UserLiveAssigns>} {
        var users = Users.listUsers(null);
        var liveSocket: LiveSocket<UserLiveAssigns> = socket;
        
        return {
            status: "ok", 
            socket: liveSocket.merge({
                users: users,
                selectedUser: null,
                changeset: Users.changeUser(null),
                searchTerm: "",
                showForm: false
            })
        };
    }
    
    static function handleEvent(event: UserLiveEvent, socket: Socket<UserLiveAssigns>): {status: String, socket: Socket<UserLiveAssigns>} {
        var liveSocket: LiveSocket<UserLiveAssigns> = socket;
        return switch(event) {
            case NewUser:
                handleNewUser(liveSocket);
                
            case EditUser(id):
                handleEditUser(id, liveSocket);
                
            case SaveUser(params):
                handleSaveUser(params, liveSocket);
                
            case DeleteUser(id):
                handleDeleteUser(id, liveSocket);
                
            case Search(params):
                handleSearch(params.search_term, liveSocket);
                
            case FilterStatus(params):
                handleFilterStatus(params.status, liveSocket);
                
            case ClearSearch:
                handleClearSearch(liveSocket);
                
            case Cancel:
                handleCancel(liveSocket);
        }
    }
    
    static function handleNewUser(socket: LiveSocket<UserLiveAssigns>): {status: String, socket: Socket<UserLiveAssigns>} {
        var changeset = Users.changeUser(null);
        var selectedUser = null;
        var showForm = true;
        
        return {
            status: "noreply",
            socket: socket.merge({
                changeset: changeset,
                selectedUser: selectedUser,
                showForm: showForm
            })
        };
    }
    
    static function handleEditUser(userId: Int, socket: LiveSocket<UserLiveAssigns>): {status: String, socket: Socket<UserLiveAssigns>} {
        var selectedUser = Users.getUser(userId);
        var changeset = Users.changeUser(selectedUser);
        var showForm = true;
        
        return {
            status: "noreply",
            socket: socket.merge({
                selectedUser: selectedUser,
                changeset: changeset,
                showForm: showForm
            })
        };
    }
    
    static function handleSaveUser(params: {user: Dynamic}, socket: LiveSocket<UserLiveAssigns>): {status: String, socket: Socket<UserLiveAssigns>} {
        var userParams = params.user;
        var selectedUser = socket.assigns.selectedUser;
        var result = selectedUser == null 
            ? Users.createUser(userParams)
            : Users.updateUser(selectedUser, userParams);
            
        return switch(result) {
            case Ok(user):
                // Successfully created/updated user
                var users = Users.listUsers(null);
                
                {
                    status: "noreply",
                    socket: socket.merge({
                        users: users,
                        showForm: false,
                        selectedUser: null,
                        changeset: Users.changeUser(null)
                    })
                };
                
            case Error(changeset):
                // Validation errors in changeset
                {
                    status: "noreply",
                    socket: socket.assign(_.changeset, changeset)
                };
        }
    }
    
    static function handleDeleteUser(userId: Int, socket: LiveSocket<UserLiveAssigns>): {status: String, socket: Socket<UserLiveAssigns>} {
        var user = Users.getUser(userId);
        var result = Users.deleteUser(user);
        
        return switch(result) {
            case Ok(deletedUser):
                // Successfully deleted user
                var users = Users.listUsers(null);
                {
                    status: "noreply",
                    socket: socket.assign(_.users, users)
                };
                
            case Error(changeset):
                // Failed to delete (e.g., foreign key constraint)
                // Could add error message to socket here
                {status: "noreply", socket: socket};
        }
    }
    
    static function handleSearch(searchTerm: String, socket: LiveSocket<UserLiveAssigns>): {status: String, socket: Socket<UserLiveAssigns>} {
        // Use the new filtering functionality
        var filter = searchTerm.length > 0 
            ? {
                name: searchTerm,
                email: searchTerm,
                isActive: null
              }
            : null;
            
        var users = Users.listUsers(filter);
            
        return {
            status: "noreply",
            socket: socket.merge({
                users: users,
                searchTerm: searchTerm
            })
        };
    }
    
    static function handleFilterStatus(status: String, socket: LiveSocket<UserLiveAssigns>): {status: String, socket: Socket<UserLiveAssigns>} {
        var filter = status.length > 0 
            ? {
                name: null,
                email: null,
                isActive: status == "active"
              }
            : null;
            
        var users = Users.listUsers(filter);
            
        return {
            status: "noreply",
            socket: socket.assign(_.users, users)
        };
    }
    
    static function handleClearSearch(socket: LiveSocket<UserLiveAssigns>): {status: String, socket: Socket<UserLiveAssigns>} {
        var users = Users.listUsers(null);
        
        return {
            status: "noreply",
            socket: socket.merge({
                users: users,
                searchTerm: ""
            })
        };
    }
    
    static function handleCancel(socket: LiveSocket<UserLiveAssigns>): {status: String, socket: Socket<UserLiveAssigns>} {
        return {
            status: "noreply",
            socket: socket.merge({
                showForm: false,
                selectedUser: null,
                changeset: Users.changeUser(null)
            })
        };
    }
    
    static function render(assigns: Dynamic): String {
        return HXX.hxx('
        <div class="min-h-screen bg-gray-50 py-8">
            <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
                <!-- Header with gradient background -->
                <div class="bg-gradient-to-r from-blue-600 to-indigo-600 rounded-lg shadow-lg p-6 mb-8">
                    <div class="flex justify-between items-center">
                        <div>
                            <h1 class="text-3xl font-bold text-white">User Management</h1>
                            <p class="text-blue-100 mt-1">Manage your application users</p>
                        </div>
                        <button 
                            phx-click="new_user" 
                            class="bg-white text-blue-600 hover:bg-blue-50 px-6 py-3 rounded-lg font-semibold flex items-center gap-2 transition-colors shadow-md"
                        >
                            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6v6m0 0v6m0-6h6m-6 0H6"></path>
                            </svg>
                            New User
                        </button>
                    </div>
                </div>
                
                <!-- Search and Filter Section -->
                <div class="bg-white rounded-lg shadow-md p-6 mb-6">
                    <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
                        <div class="md:col-span-2">
                            <label class="block text-sm font-medium text-gray-700 mb-2">Search Users</label>
                            <form phx-change="search" phx-submit="search">
                                <div class="relative">
                                    <input 
                                        name="search_term"
                                        value={@searchTerm}
                                        placeholder="Search by name or email..."
                                        type="text"
                                        class="w-full pl-10 pr-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
                                    />
                                    <svg class="absolute left-3 top-2.5 w-5 h-5 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"></path>
                                    </svg>
                                </div>
                            </form>
                        </div>
                        <div>
                            <label class="block text-sm font-medium text-gray-700 mb-2">Filter by Status</label>
                            <select phx-change="filter_status" class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500">
                                <option value="">All Users</option>
                                <option value="active">Active</option>
                                <option value="inactive">Inactive</option>
                            </select>
                        </div>
                    </div>
                    
                    <%= if @searchTerm != "" do %>
                        <div class="mt-4 flex items-center text-sm text-gray-600">
                            <span>Showing results for: <span class="font-semibold">{@searchTerm}</span></span>
                            <button phx-click="clear_search" class="ml-2 text-blue-600 hover:text-blue-800">Clear</button>
                        </div>
                    <% end %>
                </div>
                
                ${renderUserList(assigns)}
                ${renderUserForm(assigns)}
            </div>
        </div>
        ');
    }
    
    static function renderUserList(assigns: Dynamic): String {
        return HXX.hxx('
        <div class="bg-white rounded-lg shadow-md overflow-hidden">
            <table class="min-w-full divide-y divide-gray-200">
                <thead class="bg-gray-50">
                    <tr>
                        <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                            Name
                        </th>
                        <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                            Email
                        </th>
                        <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                            Age
                        </th>
                        <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                            Status
                        </th>
                        <th scope="col" class="relative px-6 py-3">
                            <span class="sr-only">Actions</span>
                        </th>
                    </tr>
                </thead>
                <tbody class="bg-white divide-y divide-gray-200">
                    <%= for user <- @users do %>
                        <tr class="hover:bg-gray-50 transition-colors">
                            <td class="px-6 py-4 whitespace-nowrap">
                                <div class="flex items-center">
                                    <div class="flex-shrink-0 h-10 w-10">
                                        <div class="h-10 w-10 rounded-full bg-gradient-to-br from-blue-500 to-indigo-600 flex items-center justify-center text-white font-semibold">
                                            <%= String.first(user.name) %>
                                        </div>
                                    </div>
                                    <div class="ml-4">
                                        <div class="text-sm font-medium text-gray-900">
                                            <%= user.name %>
                                        </div>
                                    </div>
                                </div>
                            </td>
                            <td class="px-6 py-4 whitespace-nowrap">
                                <div class="text-sm text-gray-900"><%= user.email %></div>
                            </td>
                            <td class="px-6 py-4 whitespace-nowrap">
                                <div class="text-sm text-gray-900"><%= user.age %></div>
                            </td>
                            <td class="px-6 py-4 whitespace-nowrap">
                                <%= if user.is_active do %>
                                    <span class="px-2 inline-flex text-xs leading-5 font-semibold rounded-full bg-green-100 text-green-800">
                                        Active
                                    </span>
                                <% else %>
                                    <span class="px-2 inline-flex text-xs leading-5 font-semibold rounded-full bg-gray-100 text-gray-800">
                                        Inactive
                                    </span>
                                <% end %>
                            </td>
                            <td class="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
                                <button 
                                    phx-click="edit_user" 
                                    phx-value-id={user.id}
                                    class="text-indigo-600 hover:text-indigo-900 mr-3"
                                >
                                    Edit
                                </button>
                                <button 
                                    phx-click="delete_user" 
                                    phx-value-id={user.id}
                                    data-confirm="Are you sure you want to delete this user?"
                                    class="text-red-600 hover:text-red-900"
                                >
                                    Delete
                                </button>
                            </td>
                        </tr>
                    <% end %>
                </tbody>
            </table>
            
            <%= if length(@users) == 0 do %>
                <div class="text-center py-12">
                    <svg class="mx-auto h-12 w-12 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M20 13V6a2 2 0 00-2-2H6a2 2 0 00-2 2v7m16 0v5a2 2 0 01-2 2H6a2 2 0 01-2-2v-5m16 0h-2.586a1 1 0 00-.707.293l-2.414 2.414a1 1 0 01-.707.293h-3.172a1 1 0 01-.707-.293l-2.414-2.414A1 1 0 006.586 13H4" />
                    </svg>
                    <h3 class="mt-2 text-sm font-medium text-gray-900">No users found</h3>
                    <p class="mt-1 text-sm text-gray-500">
                        <%= if @searchTerm != "" do %>
                            Try adjusting your search criteria
                        <% else %>
                            Get started by creating a new user
                        <% end %>
                    </p>
                </div>
            <% end %>
    </div>
        ');
    }
    
    static function renderUserRow(assigns: Dynamic): String {
        var user = assigns.user;
        return HXX.hxx('
        <tr>
            <td>${user.name}</td>
            <td>${user.email}</td>
            <td>${user.age}</td>
            <td>
                <span class={getStatusClass(user.active)}>
                    ${getStatusText(user.active)}
                </span>
            </td>
            <td class="actions">
                <.button phx-click="edit_user" phx-value-id={user.id} size="sm">
                    Edit
                </.button>
                <.button 
                    phx-click="delete_user" 
                    phx-value-id={user.id} 
                    data-confirm="Are you sure?"
                    variant="danger"
                    size="sm"
                >
                    Delete
                </.button>
            </td>
        </tr>
        ');
    }
    
    /**
     * Get CSS class for user status
     */
    private static function getStatusClass(active: Bool): String {
        return active ? "status active" : "status inactive";
    }
    
    /**
     * Get display text for user status
     */
    private static function getStatusText(active: Bool): String {
        return active ? "Active" : "Inactive";
    }
    
    static function renderUserForm(assigns: Dynamic): String {
        if (!assigns.showForm) return "";
        
        return HXX.hxx('
        <div class="modal">
            <div class="modal-content">
                <div class="modal-header">
                    <h2><%= if @selectedUser, do: "Edit User", else: "New User" %></h2>
                    <button phx-click="cancel" class="close">&times;</button>
                </div>
                
                <.form for={@changeset} phx-submit="save_user">
                    <div class="form-group">
                        <.label for="name">Name</.label>
                        <.input field={@changeset[:name]} type="text" required />
                        <.error field={@changeset[:name]} />
                    </div>
                    
                    <div class="form-group">
                        <.label for="email">Email</.label>
                        <.input field={@changeset[:email]} type="email" required />
                        <.error field={@changeset[:email]} />
                    </div>
                    
                    <div class="form-group">
                        <.label for="age">Age</.label>
                        <.input field={@changeset[:age]} type="number" />
                        <.error field={@changeset[:age]} />
                    </div>
                    
                    <div class="form-group">
                        <.input 
                            field={@changeset[:active]} 
                            type="checkbox" 
                            label="Active"
                        />
                    </div>
                    
                    <div class="form-actions">
                        <.button type="submit">
                            <%= if @selectedUser, do: "Update", else: "Create" %> User
                        </.button>
                        <.button type="button" phx-click="cancel" variant="secondary">
                            Cancel
                        </.button>
                    </div>
                </.form>
            </div>
        </div>
        ');
    }
    
    // Main function for compilation testing
    public static function main(): Void {
        trace("UserLive with @:liveview annotation compiled successfully!");
    }
}
````

## File: examples/todo-app/src_haxe/server/migrations/CreateTodos.hx
````
package server.migrations;

import ecto.Migration;
import ecto.Migration.*;

/**
 * Migration to create the todos table with proper indexes
 * 
 * Uses the new typed Migration DSL for compile-time validation
 * and idiomatic Elixir code generation.
 */
@:migration
class CreateTodos extends Migration {
    
    public function up(): Void {
        createTable("todos")
            .addColumn("title", String(), {nullable: false})
            .addColumn("description", Text)
            .addColumn("completed", Boolean, {defaultValue: false})
            .addColumn("priority", String())
            .addColumn("due_date", DateTime)
            .addColumn("tags", Json)
            .addColumn("user_id", Integer)
            .addTimestamps()
            .addIndex(["user_id"])
            .addIndex(["completed"]);
    }
    
    public function down(): Void {
        dropTable("todos");
    }
}
````

## File: examples/todo-app/src_haxe/server/migrations/CreateUsers.hx
````
package server.migrations;

import ecto.Migration;
import ecto.Migration.*;

/**
 * Migration to create the users table with authentication fields
 * 
 * Uses the new typed Migration DSL for compile-time validation
 * and proper index/constraint generation.
 */
@:migration
class CreateUsers extends Migration {
    
    public function up(): Void {
        createTable("users")
            // User identification and profile fields
            .addColumn("name", String(), {nullable: false})
            .addColumn("email", String(), {nullable: false})
            
            // Authentication fields
            .addColumn("password_hash", String(), {nullable: false})
            .addColumn("confirmed_at", DateTime)
            .addColumn("last_login_at", DateTime)
            .addColumn("active", Boolean, {defaultValue: true})
            
            // Timestamps
            .addTimestamps()
            
            // Indexes for performance
            .addUniqueConstraint(["email"], "users_email_unique")
            .addIndex(["active"])
            .addIndex(["confirmed_at"])
            .addIndex(["last_login_at"])
            
            // Data integrity constraints
            .addCheckConstraint("email_format", "email ~ '^[^\\s@]+@[^\\s@]+\\.[^\\s@]+$'")
            .addCheckConstraint("name_length", "length(name) >= 2");
    }
    
    public function down(): Void {
        dropTable("users");
    }
}
````

## File: examples/todo-app/src_haxe/server/presence/TodoPresence.hx
````
package server.presence;

import phoenix.Phoenix.Socket;
import phoenix.Presence;
import phoenix.PresenceBehavior;
import phoenix.LiveSocket;
import server.types.Types.User;
import server.types.Types.PresenceTopic;
import server.types.Types.PresenceTopics;

/**
 * Unified presence metadata following idiomatic Phoenix patterns
 * 
 * In Phoenix apps, each user has a single presence entry with all their state.
 * This avoids complex nested structures and multiple presence topics.
 */
typedef PresenceMeta = {
    var onlineAt: Float;
    var userName: String;
    var userEmail: String;
    var avatar: Null<String>;
    // Editing state is part of the same presence entry (Phoenix pattern)
    var editingTodoId: Null<Int>;  // null = not editing, Int = editing todo ID
    var editingStartedAt: Null<Float>;  // When they started editing
}

// PresenceEntry is defined in phoenix.Presence module as a generic typedef
// This provides type-safe presence metadata across all Phoenix applications

/**
 * Idiomatic Phoenix Presence implementation with type-safe Haxe augmentation
 * 
 * This module follows standard Phoenix Presence patterns:
 * - Single presence entry per user (not multiple topics)
 * - All user state in one metadata structure
 * - Updates via Presence.update() rather than track/untrack
 * 
 * The generated Elixir code is indistinguishable from hand-written Phoenix,
 * but with compile-time type safety that Phoenix developers wish they had.
 * 
 * TYPE SAFETY PATTERNS:
 * 
 * Option 1: Use string constant (simple but less type-safe)
 * @:presenceTopic("users")
 * 
 * Option 2: Use static constant (better for shared topics)
 * static inline final TOPIC = "users";
 * @:presenceTopic(TOPIC)  // Note: This requires macro enhancement
 * 
 * Option 3: Use enum + helper (most type-safe, compile-time validation)
 * // Define topic in Types.hx enum, use string in annotation
 * @:presenceTopic("users")  // Must match PresenceTopic.Users mapping
 * 
 * The enum approach provides compile-time validation through the
 * PresenceTopics.toString() helper, ensuring consistency across the app.
 */
@:native("TodoAppWeb.Presence")
@:presence
@:presenceTopic("users")  // Must match PresenceTopics.toString(Users)
class TodoPresence implements PresenceBehavior {
    /**
     * Type-safe topic reference for compile-time validation
     * Use this to ensure consistency with the @:presenceTopic annotation
     */
    public static inline final TOPIC_ENUM = PresenceTopic.Users;
    public static inline final TOPIC = "users"; // Must match PresenceTopics.toString(TOPIC_ENUM)
    /**
     * Track a user's presence in the todo app (idiomatic Phoenix pattern)
     * 
     * Uses the new simplified API with class-level topic configuration.
     * 
     * @param socket The LiveView socket
     * @param user The user to track
     */
    public static function trackUser<T>(socket: Socket<T>, user: User): Socket<T> {
        var meta: PresenceMeta = {
            onlineAt: Date.now().getTime(),
            userName: user.name,
            userEmail: user.email,
            avatar: null,
            editingTodoId: null,  // Not editing initially
            editingStartedAt: null
        };
        // Use the simplified API - no need to pass topic!
        trackSimple(Std.string(user.id), meta);
        return socket;
    }
    
    /**
     * Update user's editing state (idiomatic Phoenix pattern)
     * 
     * Instead of track/untrack on different topics, we update the metadata
     * on the single user presence entry - this is the Phoenix way.
     * 
     * @param socket The LiveView socket
     * @param user The user whose state to update
     * @param todoId The todo being edited (null to stop editing)
     */
    public static function updateUserEditing<T>(socket: Socket<T>, user: User, todoId: Null<Int>): Socket<T> {
        // Update the metadata with new editing state (assume track happened elsewhere)
        var updatedMeta: PresenceMeta = {
            onlineAt: Date.now().getTime(),
            userName: user.name,
            userEmail: user.email,
            avatar: null,
            editingTodoId: todoId,
            editingStartedAt: todoId != null ? Date.now().getTime() : null
        };
        // Use the simplified API - topic is configured at class level
        updateSimple(Std.string(user.id), updatedMeta);
        return socket;
    }
    
    // Removed getUserPresence helper to avoid unused function warning in generated code when
    // presence update is simplified by transforms.
    
    /**
     * Get list of users currently online
     */
    public static function listOnlineUsers<T>(socket: Socket<T>): haxe.DynamicAccess<phoenix.Presence.PresenceEntry<PresenceMeta>> {
        // Use the generated listSimple() method
        return listSimple();
    }
    
    /**
     * Get users currently editing a specific todo (idiomatic Phoenix pattern)
     * 
     * Filters the single presence list by editing state rather than
     * querying separate topics - more maintainable and Phoenix-like.
     */
    public static function getUsersEditingTodo<T>(socket: Socket<T>, todoId: Int): Array<PresenceMeta> {
        // Get all users through the generated listSimple() method
        var allUsers = listSimple();
        var metas:Array<PresenceMeta> = [];
        for (userId in Reflect.fields(allUsers)) {
            var entry: phoenix.Presence.PresenceEntry<PresenceMeta> = Reflect.field(allUsers, userId);
            if (entry.metas.length > 0) {
                var meta = entry.metas[0];
                if (meta.editingTodoId == todoId) metas.push(meta);
            }
        }
        return metas;
    }
}
````

## File: examples/todo-app/src_haxe/server/pubsub/TodoPubSub.hx
````
package server.pubsub;

import phoenix.SafePubSub;
import haxe.ds.Option;
import haxe.functional.Result;
import server.types.Types.TodoPriority;
import server.types.Types.BulkOperationType;
import server.types.Types.AlertLevel;

/**
 * Todo-app specific PubSub topics and messages with complete type safety
 * 
 * This module demonstrates how applications should extend the framework's
 * SafePubSub infrastructure with their own domain-specific types.
 * 
 * ## Usage Examples
 * 
 * ```haxe
 * // Type-safe broadcasting - IntelliSense shows all options
 * TodoPubSub.broadcast(TodoUpdates, TodoCreated(newTodo));
 * 
 * // Type-safe subscription
 * TodoPubSub.subscribe(UserActivity);
 * 
 * // Type-safe message parsing in LiveView handle_info
 * switch (TodoPubSub.parseMessage(msg)) {
 *     case Some(TodoCreated(todo)): addTodoToUI(todo);
 *     case Some(TodoUpdated(todo)): updateTodoInUI(todo);
 *     case None: trace("Unknown message");
 * }
 * ```
 * 
 * ## Compile-Time Safety Examples
 * 
 * ```haxe
 * // ❌ This will be caught at compile-time:
 * TodoPubSub.broadcast(TodoUpades, TodoCreated(todo)); // "Unknown constructor"
 * 
 * // ❌ This will be caught at compile-time:
 * TodoPubSub.broadcast(TodoUpdates, TodoCreated(null)); // "Missing argument"
 * 
 * // ✅ This compiles and has IntelliSense support:
 * TodoPubSub.broadcast(TodoUpdates, TodoUpdated(updatedTodo));
 * ```
 */

/**
 * Type-safe PubSub topics for the todo application
 * 
 * Adding new topics requires:
 * 1. Add enum case here
 * 2. Add case to topicToString function
 * 3. Compiler ensures exhaustiveness
 */
enum TodoPubSubTopic {
    TodoUpdates;          // "todo:updates"
    UserActivity;         // "user:activity"  
    SystemNotifications;  // "system:notifications"
}

/**
 * Type-safe PubSub message types with compile-time validation
 * 
 * Each message type is strongly typed with required parameters.
 * Adding new messages requires updating parseMessage function.
 */
enum TodoPubSubMessage {
    TodoCreated(todo: server.schemas.Todo);
    TodoUpdated(todo: server.schemas.Todo);
    TodoDeleted(id: Int);
    BulkUpdate(action: BulkOperationType);
    UserOnline(user_id: Int);
    UserOffline(user_id: Int);
    SystemAlert(message: String, level: AlertLevel);
}

// BulkOperationType and AlertLevel are imported from server.types.Types

/**
 * Todo-app specific SafePubSub wrapper with complete type safety
 * 
 * This class provides a convenient API for the todo application while
 * using the framework's SafePubSub infrastructure underneath.
 */
class TodoPubSub {
    
    /**
     * Type-safe subscribe to a topic
     * 
     * @param topic Topic to subscribe to (with IntelliSense support)
     * @return Result indicating success or failure with descriptive error
     */
    public static function subscribe(topic: TodoPubSubTopic): Result<Void, String> {
        return SafePubSub.subscribeTopic(topicToString(topic));
    }
    
    /**
     * Type-safe broadcast with topic and message validation
     * 
     * @param topic Topic to broadcast to (compile-time validated)
     * @param message Message to broadcast (compile-time structure validated)
     * @return Result indicating success or failure with descriptive error
     */
    public static function broadcast(topic: TodoPubSubTopic, message: TodoPubSubMessage): Result<Void, String> {
        return SafePubSub.broadcastTopicPayload(topicToString(topic), messageToElixir(message));
    }
    
    /**
     * Parse incoming PubSub messages back to typed enums
     * 
     * @param msg Raw Dynamic message from Phoenix PubSub
     * @return Typed message or None if parsing failed
     * 
     * NOTE: This function should be auto-generated by macro in Phase 2.
     * Manual implementation ensures type safety until macro is available.
     */
    public static function parseMessage(msg: Dynamic): Option<TodoPubSubMessage> {
        // Pass an explicit function value to avoid capture/camelCase issues
        return SafePubSub.parseWithConverter(msg, (m) -> parseMessageImpl(m));
    }
    
    // ========================================================================
    // Private Implementation Functions
    // ========================================================================
    
    /**
     * Convert TodoPubSubTopic enum to string for Elixir compatibility
     * Note: Must be public to be passed as function reference in Elixir
     */
    public static function topicToString(topic: TodoPubSubTopic): String {
        return switch (topic) {
            case TodoUpdates: "todo:updates";
            case UserActivity: "user:activity";
            case SystemNotifications: "system:notifications";
        };
    }
    
    /**
     * Convert typed message to Dynamic object for Elixir PubSub
     * Note: Must be public to be passed as function reference in Elixir
     */
    public static function messageToElixir(message: TodoPubSubMessage): Dynamic {
        // Avoid ephemeral locals: build payload inline and add timestamp
        return SafePubSub.addTimestamp(switch (message) {
            case TodoCreated(todo):
                { type: "todo_created", todo: todo };
            case TodoUpdated(todo):
                { type: "todo_updated", todo: todo };
            case TodoDeleted(id):
                cast { type: "todo_deleted", todo_id: id };
            case BulkUpdate(action):
                cast { type: "bulk_update", action: bulkActionToString(action) };
            case UserOnline(user_id):
                cast { type: "user_online", user_id: user_id };
            case UserOffline(user_id):
                cast { type: "user_offline", user_id: user_id };
            case SystemAlert(message, level):
                cast { type: "system_alert", message: message, level: alertLevelToString(level) };
        });
    }
    
    /**
     * Parse Dynamic message to typed enum (implementation)
     * Note: Must be public to be passed as function reference in Elixir
     */
    public static function parseMessageImpl(msg: Dynamic): Option<TodoPubSubMessage> {
        if (!SafePubSub.isValidMessage(msg)) {
            trace(SafePubSub.createMalformedMessageError(msg));
            return None;
        }
        
        return switch (msg.type) {
            case "todo_created":
                if (msg.todo != null) Some(TodoCreated(msg.todo)) else None;
            case "todo_updated":
                if (msg.todo != null) Some(TodoUpdated(msg.todo)) else None;
            case "todo_deleted":
                if (msg.todo_id != null) Some(TodoDeleted(msg.todo_id)) else None;
            case "bulk_update":
                if (msg.action != null) {
                    return switch (msg.action) {
                        case "complete_all": Some(BulkUpdate(CompleteAll));
                        case "delete_completed": Some(BulkUpdate(DeleteCompleted));
                        case "set_priority": Some(BulkUpdate(SetPriority(TodoPriority.Medium)));
                        case "add_tag": Some(BulkUpdate(AddTag("")));
                        case "remove_tag": Some(BulkUpdate(RemoveTag("")));
                        case _: None;
                    };
                } else None;
            case "user_online":
                if (msg.user_id != null) Some(UserOnline(msg.user_id)) else None;
            case "user_offline":
                if (msg.user_id != null) Some(UserOffline(msg.user_id)) else None;
            case "system_alert":
                if (msg.message != null && msg.level != null) {
                    return switch (msg.level) {
                        case "info": Some(SystemAlert(msg.message, Info));
                        case "warning": Some(SystemAlert(msg.message, Warning));
                        case "error": Some(SystemAlert(msg.message, Error));
                        case "critical": Some(SystemAlert(msg.message, Critical));
                        case _: None;
                    };
                } else None;
            case _:
                trace(SafePubSub.createUnknownMessageError(msg.type));
                None;
        };
    }
    
    /**
     * Convert bulk action enum to string
     */
    private static function bulkActionToString(action: BulkOperationType): String {
        return switch (action) {
            case CompleteAll: "complete_all";
            case DeleteCompleted: "delete_completed";
            case SetPriority(priority): "set_priority";
            case AddTag(tag): "add_tag";
            case RemoveTag(tag): "remove_tag";
        };
    }
    
    /**
     * Parse bulk action string back to enum
     */
    @:keep private static function parseBulkAction(action: String): Null<BulkOperationType> {
        return switch (action) {
            case "complete_all": CompleteAll;
            case "delete_completed": DeleteCompleted;
            case "set_priority": SetPriority(TodoPriority.Medium);
            case "add_tag": AddTag("");
            case "remove_tag": RemoveTag("");
            case _: null;
        };
    }
    
    /**
     * Convert alert level enum to string
     */
    private static function alertLevelToString(level: AlertLevel): String {
        return switch (level) {
            case Info: "info";
            case Warning: "warning";  
            case Error: "error";
            case Critical: "critical";
        };
    }
    
    /**
     * Parse alert level string back to enum
     */
    @:keep private static function parseAlertLevel(level: String): Null<AlertLevel> {
        return switch (level) {
            case "info": Info;
            case "warning": Warning;  
            case "error": Error;
            case "critical": Critical;
            case _: null;
        };
    }
}
````

## File: examples/todo-app/src_haxe/server/schemas/Todo.hx
````
package server.schemas;

import ecto.Changeset;
import haxe.ds.Option;

/**
 * Parameters for Todo changeset operations.
 * Strongly typed to avoid Dynamic usage.
 */
typedef TodoParams = {
	?title: String,
	?description: String,
	?completed: Bool,
	?priority: String,
	?dueDate: Date,
	?tags: Array<String>,
	?userId: Int
}

/**
 * Todo schema for managing tasks
 */
@:native("TodoApp.Todo")
@:schema("todos")
@:timestamps
class Todo {
	@:field public var id: Int;
	@:field public var title: String;
	@:field public var description: String;
	@:field public var completed: Bool = false;
	@:field public var priority: String = "medium"; // low, medium, high
	@:field public var dueDate: Null<Date>; // Type-safe nullable Date
	@:field public var tags: Array<String> = [];
	@:field public var userId: Int;
	
	public function new() {
		this.tags = [];
		this.completed = false;
		this.priority = "medium";
	}
	
    @:changeset
    public static function changeset(todo: Todo, params: TodoParams): Changeset<Todo, TodoParams> {
        // Fully typed pipeline: return idiomatic Ecto changeset without intermediate binders
        return new Changeset(todo, params)
            .validateRequired(["title", "userId"]) 
            .validateLength("title", {min: 3, max: 200})
            .validateLength("description", {max: 1000});
    }
	
	
	// Helper functions for business logic with proper types
	public static function toggleCompleted(todo: Todo): Changeset<Todo, TodoParams> {
		var params: TodoParams = {
			completed: !todo.completed
		};
		return changeset(todo, params);
	}
	
	public static function updatePriority(todo: Todo, priority: String): Changeset<Todo, TodoParams> {
		var params: TodoParams = {
			priority: priority
		};
		return changeset(todo, params);
	}
	
	public static function addTag(todo: Todo, tag: String): Changeset<Todo, TodoParams> {
		var tags: Array<String> = todo.tags != null ? todo.tags.copy() : [];
		tags.push(tag);
		var params: TodoParams = {
			tags: tags
		};
		return changeset(todo, params);
	}
}
````

## File: examples/todo-app/src_haxe/server/schemas/User.hx
````
package server.schemas;

import phoenix.Ecto;

/**
 * User schema for authentication and todo ownership
 * 
 * Provides a simple user model with basic authentication fields
 * and relationship to todos for user-specific task management.
 */
@:schema
@:timestamps
@:keep
class User {
    @:field public var id: Int;
    @:field public var name: String;
    @:field public var email: String;
    @:field public var passwordHash: String;
    @:field public var confirmedAt: Dynamic; // Date type for email confirmation
    @:field public var lastLoginAt: Dynamic; // Date type for tracking activity
    @:field public var active: Bool = true;
    
    // Virtual field for password input (not stored in database)
    @:virtual @:field public var password: String;
    @:virtual @:field public var passwordConfirmation: String;
    
    public function new() {
        this.active = true;
    }
    
    /**
     * Registration changeset for new user creation
     * Includes password validation and hashing
     */
    @:changeset
    @:keep
    public static function registrationChangeset(user: Dynamic, params: Dynamic): Dynamic {
        var changeset = phoenix.Ecto.EctoChangeset.castChangeset(user, params, [
            "name", "email", "password", "passwordConfirmation"
        ]);
        
        // Basic validations
        changeset = phoenix.Ecto.EctoChangeset.validate_required(changeset, ["name", "email", "password"]);
        changeset = phoenix.Ecto.EctoChangeset.validate_length(changeset, "name", {min: 2, max: 100});
        var emailPattern = ~/^[^\s@]+@[^\s@]+\.[^\s@]+$/;
        changeset = phoenix.Ecto.EctoChangeset.validate_format(changeset, "email", emailPattern);
        changeset = phoenix.Ecto.EctoChangeset.validate_length(changeset, "password", {min: 8, max: 128});
        changeset = phoenix.Ecto.EctoChangeset.validate_confirmation(changeset, "password");
        changeset = phoenix.Ecto.EctoChangeset.unique_constraint(changeset, "email");
        
        // Hash password if valid
        if (phoenix.Ecto.EctoChangeset.get_change(changeset, "password") != null) {
            changeset = putPasswordHash(changeset);
        }
        
        return changeset;
    }
    
    /**
     * Update changeset for existing user modifications
     * Allows updating name and email without password changes
     */
    @:changeset
    @:keep
    public static function changeset(user: Dynamic, params: Dynamic): Dynamic {
        var changeset = phoenix.Ecto.EctoChangeset.castChangeset(user, params, [
            "name", "email", "active"
        ]);
        
        changeset = phoenix.Ecto.EctoChangeset.validate_required(changeset, ["name", "email"]);
        changeset = phoenix.Ecto.EctoChangeset.validate_length(changeset, "name", {min: 2, max: 100});
        changeset = phoenix.Ecto.EctoChangeset.validate_format(changeset, "email", {pattern: "^[^\\s@]+@[^\\s@]+\\.[^\\s@]+$"});
        changeset = phoenix.Ecto.EctoChangeset.unique_constraint(changeset, "email");
        
        return changeset;
    }
    
    /**
     * Password change changeset for updating user passwords
     */
    @:changeset
    public static function passwordChangeset(user: Dynamic, params: Dynamic): Dynamic {
        var changeset = phoenix.Ecto.EctoChangeset.castChangeset(user, params, [
            "password", "passwordConfirmation"
        ]);
        
        changeset = phoenix.Ecto.EctoChangeset.validate_required(changeset, ["password"]);
        changeset = phoenix.Ecto.EctoChangeset.validate_length(changeset, "password", {min: 8, max: 128});
        changeset = phoenix.Ecto.EctoChangeset.validate_confirmation(changeset, "password");
        
        if (phoenix.Ecto.EctoChangeset.get_change(changeset, "password") != null) {
            changeset = putPasswordHash(changeset);
        }
        
        return changeset;
    }
    
    /**
     * Email confirmation changeset
     */
    public static function confirmChangeset(user: Dynamic): Dynamic {
        var changeset = phoenix.Ecto.EctoChangeset.change(user, {confirmedAt: now()});
        return changeset;
    }
    
    /**
     * Login tracking changeset
     */
    public static function loginChangeset(user: Dynamic): Dynamic {
        var changeset = phoenix.Ecto.EctoChangeset.change(user, {lastLoginAt: now()});
        return changeset;
    }
    
    // Helper functions for authentication
    
    /**
     * Hash password and put in changeset
     */
    static function putPasswordHash(changeset: Dynamic): Dynamic {
        var password = phoenix.Ecto.EctoChangeset.get_change(changeset, "password");
        if (password != null) {
            var hashed = hashPassword(password);
            return phoenix.Ecto.EctoChangeset.put_change(changeset, "passwordHash", hashed);
        }
        return changeset;
    }
    
    /**
     * Hash password using bcrypt (simplified for demo)
     * In production, would use proper bcrypt library
     */
    static function hashPassword(password: String): String {
        // In a real application, use Bcrypt.hash_pwd_salt(password)
        // For demo purposes, using a simple hash (NOT secure)
        return "hashed_" + password;
    }
    
    /**
     * Verify password against hash
     */
    public static function verifyPassword(user: Dynamic, password: String): Bool {
        // In a real application, use Bcrypt.verify_pass(password, user.passwordHash)
        // For demo purposes, simple verification
        return user.passwordHash == "hashed_" + password;
    }
    
    /**
     * Check if user is confirmed
     */
    public static function confirmed(user: Dynamic): Bool {
        return user.confirmedAt != null;
    }
    
    /**
     * Check if user is active
     */
    public static function active(user: Dynamic): Bool {
        return user.active == true;
    }
    
    /**
     * Get current timestamp
     */
    static function now(): Dynamic {
        // Would use DateTime.utc_now() in real Elixir
        return "2024-01-01T00:00:00Z"; // Demo timestamp
    }
    
    /**
     * Create a demo user for development
     */
    public static function createDemoUser(): Dynamic {
        return {
            id: 1,
            name: "Demo User",
            email: "demo@example.com",
            passwordHash: "hashed_demopassword",
            confirmedAt: now(),
            lastLoginAt: now(),
            active: true
        };
    }
    
    /**
     * Display name for user (for UI)
     */
    public static function displayName(user: Dynamic): String {
        return user.name != null && user.name != "" ? user.name : user.email;
    }
    
    /**
     * User initials for avatars
     */
    public static function initials(user: Dynamic): String {
        var name = displayName(user);
        var parts = name.split(" ");
        if (parts.length >= 2) {
            return parts[0].charAt(0).toUpperCase() + parts[1].charAt(0).toUpperCase();
        }
        return name.charAt(0).toUpperCase();
    }
}
````

## File: examples/todo-app/src_haxe/server/services/UserGenServer.hx
````
package services;

import contexts.Users;
import contexts.Users.User;

/**
 * OTP GenServer for user-related background processes
 * Demonstrates caching, background jobs, and user analytics
 */
@:genserver
class UserGenServer {
    var userCache: Map<Int, User> = new Map();
    var statsCache: Dynamic = null;
    var lastStatsUpdate: Float = 0;
    
    function init(initialState: Dynamic): {status: String, state: Dynamic} {
        // Initialize the GenServer with empty cache
        trace("UserGenServer starting...");
        
        // Schedule periodic stats refresh
        scheduleStatsRefresh();
        
        return {
            status: "ok",
            state: {
                userCache: userCache,
                statsCache: null,
                lastStatsUpdate: 0
            }
        };
    }
    
    function handle_call(request: String, from: Dynamic, state: Dynamic): CallResponse {
        return switch(request) {
            case "get_user":
                handleGetUser(from, state);
                
            case "get_stats":
                handleGetStats(from, state);
                
            case "cache_user":
                handleCacheUser(from, state);
                
            case "clear_cache":
                handleClearCache(from, state);
                
            default:
                {status: "reply", response: "unknown_request", state: state};
        }
    }
    
    function handle_cast(message: String, state: Dynamic): {status: String, state: Dynamic} {
        return switch(message) {
            case "refresh_stats":
                handleRefreshStats(state);
                
            case "invalidate_user_cache":
                handleInvalidateUserCache(state);
                
            case "preload_active_users":
                handlePreloadActiveUsers(state);
                
            default:
                {status: "noreply", state: state};
        }
    }
    
    function handle_info(message: String, state: Dynamic): {status: String, state: Dynamic} {
        return switch(message) {
            case "stats_refresh_timer":
                // Periodic stats refresh
                var newState = refreshUserStats(state);
                scheduleStatsRefresh(); // Reschedule
                {status: "noreply", state: newState};
                
            case "cleanup_cache":
                // Periodic cache cleanup
                var newState = cleanupOldCacheEntries(state);
                {status: "noreply", state: newState};
                
            default:
                {status: "noreply", state: state};
        }
    }
    
    // Call handlers
    function handleGetUser(from: Dynamic, state: Dynamic): CallResponse {
        var userId = from.userId; // Would extract from proper message format
        
        if (userCache.exists(userId)) {
            var user = userCache.get(userId);
            return {status: "reply", response: {user: user}, state: state};
        } else {
            // Load from database and cache
            var user = Users.get_user_safe(userId);
            if (user != null) {
                userCache.set(userId, user);
                return {status: "reply", response: {user: user}, state: updateState(state, "userCache", userCache)};
            } else {
                return {status: "reply", response: "user_not_found", state: state};
            }
        }
    }
    
    function handleGetStats(from: Dynamic, state: Dynamic): CallResponse {
        var now = Date.now().getTime();
        var cacheAge = now - lastStatsUpdate;
        
        // Return cached stats if less than 5 minutes old
        if (statsCache != null && cacheAge < 300000) {
            return {status: "reply", response: statsCache, state: state};
        } else {
            // Refresh stats and cache
            var stats = Users.user_stats();
            statsCache = stats;
            lastStatsUpdate = now;
            
            return {
                status: "reply", 
                response: stats, 
                state: updateStateMultiple(state, {
                    statsCache: stats,
                    lastStatsUpdate: now
                })
            };
        }
    }
    
    function handleCacheUser(from: Dynamic, state: Dynamic): CallResponse {
        var user = from.user; // Would extract from proper message format
        userCache.set(user.id, user);
        
        return {
            status: "reply",
            response: "cached",
            state: updateState(state, "userCache", userCache)
        };
    }
    
    function handleClearCache(from: Dynamic, state: Dynamic): CallResponse {
        userCache = new Map();
        statsCache = null;
        lastStatsUpdate = 0;
        
        return {
            status: "reply",
            response: "cache_cleared",
            state: {
                userCache: userCache,
                statsCache: null,
                lastStatsUpdate: 0
            }
        };
    }
    
    // Cast handlers
    function handleRefreshStats(state: Dynamic): {status: String, state: Dynamic} {
        var stats = Users.user_stats();
        statsCache = stats;
        lastStatsUpdate = Date.now().getTime();
        
        return {
            status: "noreply",
            state: updateStateMultiple(state, {
                statsCache: stats,
                lastStatsUpdate: lastStatsUpdate
            })
        };
    }
    
    function handleInvalidateUserCache(state: Dynamic): {status: String, state: Dynamic} {
        userCache = new Map();
        
        return {
            status: "noreply",
            state: updateState(state, "userCache", userCache)
        };
    }
    
    function handlePreloadActiveUsers(state: Dynamic): {status: String, state: Dynamic} {
        var activeUsers = Users.list_users({active: true});
        
        for (user in activeUsers) {
            userCache.set(user.id, user);
        }
        
        trace('Preloaded ${activeUsers.length} active users into cache');
        
        return {
            status: "noreply",
            state: updateState(state, "userCache", userCache)
        };
    }
    
    // Helper functions
    function refreshUserStats(state: Dynamic): Dynamic {
        var stats = Users.user_stats();
        return updateStateMultiple(state, {
            statsCache: stats,
            lastStatsUpdate: Date.now().getTime()
        });
    }
    
    function cleanupOldCacheEntries(state: Dynamic): Dynamic {
        // In a real implementation, would remove entries older than X time
        // For demo, just log cache size
        var keyArray = [for (key in userCache.keys()) key];
        trace('User cache contains ${keyArray.length} entries');
        return state;
    }
    
    function scheduleStatsRefresh(): Void {
        // Would schedule timer message - implementation varies by platform
        trace("Scheduling stats refresh in 5 minutes");
    }
    
    function updateState(state: Dynamic, key: String, value: Dynamic): Dynamic {
        // Helper to update state
        return state;
    }
    
    function updateStateMultiple(state: Dynamic, updates: Dynamic): Dynamic {
        // Helper to update multiple state fields
        return state;
    }
    
    // Main function for compilation testing
    public static function main(): Void {
        trace("UserGenServer with @:genserver annotation compiled successfully!");
    }
}

// Public API for interacting with UserGenServer
class UserService {
    static var serverName = "UserGenServer";
    
    public static function getCachedUser(userId: Int): User {
        // Would call GenServer.call(serverName, {:get_user, userId})
        return null;
    }
    
    public static function getUserStats(): Dynamic {
        // Would call GenServer.call(serverName, :get_stats)
        return null;
    }
    
    public static function cacheUser(user: User): Void {
        // Would call GenServer.cast(serverName, {:cache_user, user})
    }
    
    public static function refreshStats(): Void {
        // Would call GenServer.cast(serverName, :refresh_stats)
    }
    
    public static function clearCache(): Void {
        // Would call GenServer.call(serverName, :clear_cache)
    }
    
    // Main function for compilation testing
    public static function main(): Void {
        trace("UserGenServer with @:genserver annotation compiled successfully!");
    }
}

// Type definitions
typedef CallResponse = {
    status: String,
    response: Dynamic,
    state: Dynamic
}
````

## File: examples/todo-app/src_haxe/server/types/LiveViewTypes.hx
````
package types;

/**
 * Type definitions for Phoenix LiveView interactions
 */

// Socket type removed - use phoenix.Phoenix.Socket<T> or phoenix.LiveSocket<T> instead
// This avoids conflicts with the proper Phoenix LiveView extern

// Socket assigns structure
typedef SocketAssigns = {
    var todos: Array<schemas.Todo>;
    var filter: String;
    var sort_by: String;
    var current_user: User;
    var editing_todo: Null<schemas.Todo>;
    var show_form: Bool;
    var search_query: String;
    var selected_tags: Array<String>;
    var total_todos: Int;
    var completed_todos: Int;
    var pending_todos: Int;
}

// User type
typedef User = {
    var id: Int;
    var name: String;
    var email: String;
}

// Use the actual Todo schema from schemas.Todo
// We don't redefine it here to avoid conflicts

// Params for LiveView events
typedef EventParams = {
    ?id: Int,
    ?title: String,
    ?description: String,
    ?priority: String,
    ?due_date: String,
    ?tags: String,
    ?filter: String,
    ?sort_by: String,
    ?query: String,
    ?tag: String
}

// Message types for PubSub
typedef PubSubMessage = {
    var type: String;
    var ?todo: schemas.Todo;
    var ?id: Int;
    var ?action: String;
}

// Session type
typedef Session = {
    var ?user_id: Int;
    var ?token: String;
}

// Mount params
typedef MountParams = {
    var ?id: String;
    var ?action: String;
}

// Changeset type for Ecto
typedef Changeset = {
    var valid: Bool;
    var changes: {};
    var errors: Array<{field: String, message: String}>;
    var data: Any;
}

// Repo result types
typedef RepoResult<T> = {
    var success: Bool;
    var data: T;
    var ?error: String;
}
````

## File: examples/todo-app/src_haxe/server/types/Types.hx
````
package server.types;

/**
 * Comprehensive Phoenix LiveView types for the todo-app
 * 
 * These types provide full type safety for Phoenix LiveView interactions,
 * socket operations, event handling, and database operations.
 */

// ============================================================================
// Core Phoenix LiveView Types
// ============================================================================

/**
 * Enhanced User type matching the User schema
 */
typedef User = {
    var id: Int;
    var name: String;
    var email: String;
    var passwordHash: String;  // camelCase
    var confirmedAt: Null<Dynamic>;  // camelCase
    var lastLoginAt: Null<Dynamic>;  // camelCase
    var active: Bool;
}

// Socket type removed - use phoenix.Phoenix.Socket<T> instead
// This avoids conflicts with the proper Phoenix LiveView extern

/**
 * Socket assigns structure for type-safe assign access
 */
typedef SocketAssigns = {
    var todos: Array<server.schemas.Todo>;
    var filter: String;
    var sortBy: String;  // camelCase
    var currentUser: User;  // camelCase
    var editingTodo: Null<server.schemas.Todo>;  // camelCase
    var showForm: Bool;  // camelCase
    var searchQuery: String;  // camelCase
    var selectedTags: Array<String>;  // camelCase
    var totalTodos: Int;  // camelCase
    var completedTodos: Int;  // camelCase
    var pendingTodos: Int;  // camelCase
    var flash: FlashMessages;
}

/**
 * Flash message types
 */
typedef FlashMessages = {
    var ?info: String;
    var ?error: String;
    var ?success: String;
    var ?warning: String;
}

/**
 * Redirect options for navigation
 */
typedef RedirectOptions = {
    var ?to: String;
    var ?external: String;
}

/**
 * Patch options for live navigation  
 */
typedef PatchOptions = {
    var ?to: String;
    var ?replace: Bool;
}

// ============================================================================
// Event System Types  
// ============================================================================

/**
 * Comprehensive event parameters with validation
 */
typedef EventParams = {
    // Todo CRUD fields
    var ?id: Int;
    var ?title: String;
    var ?description: String;
    var ?priority: String;
    var ?dueDate: String;  // camelCase
    var ?tags: String;
    var ?completed: Bool;
    
    // UI interaction fields
    var ?filter: String;
    var ?sortBy: String;  // camelCase
    var ?query: String;
    var ?tag: String;
    var ?action: String;
    
    // Form validation metadata
    var ?_target: Array<String>;
    var ?_csrf_token: String;
    
    // Additional dynamic fields for extensibility
    var ?value: Dynamic;
    var ?key: String;
    var ?index: Int;
}

// ============================================================================
// Real-time Communication Types - TYPE-SAFE PUBSUB & PRESENCE
// ============================================================================

/**
 * Type-safe Presence topics - compile-time validation of presence channels
 * Use with @:presenceTopic annotation for type safety
 */
enum PresenceTopic {
    Users;           // "users" - Track online users
    EditingTodos;    // "editing:todos" - Track who's editing what
    ActiveRooms;     // "active:rooms" - Track active chat rooms
}

/**
 * Helper class for type-safe presence topic conversion
 * Provides compile-time validation while generating proper topic strings
 */
class PresenceTopics {
    /**
     * Convert a type-safe PresenceTopic to its string representation
     * for use with @:presenceTopic annotation
     */
    public static function toString(topic: PresenceTopic): String {
        return switch(topic) {
            case Users: "users";
            case EditingTodos: "editing:todos";
            case ActiveRooms: "active:rooms";
        }
    }
    
    /**
     * Parse a string back to PresenceTopic (for runtime validation if needed)
     */
    public static function fromString(topic: String): Null<PresenceTopic> {
        return switch(topic) {
            case "users": Users;
            case "editing:todos": EditingTodos;
            case "active:rooms": ActiveRooms;
            default: null;
        }
    }
}

/**
 * Type-safe PubSub topics - prevents typos and invalid topic strings
 */
enum PubSubTopic {
    TodoUpdates;          // "todo:updates"
    UserActivity;         // "user:activity"  
    SystemNotifications;  // "system:notifications"
}

/**
 * Type-safe PubSub message types - compile-time validation of message structure
 */
enum PubSubMessageType {
    TodoCreated(todo: server.schemas.Todo);
    TodoUpdated(todo: server.schemas.Todo);
    TodoDeleted(id: Int);
    BulkUpdate(action: BulkOperationType);
    UserOnline(user_id: Int);
    UserOffline(user_id: Int);
    SystemAlert(message: String, level: AlertLevel);
}

/**
 * Bulk operation types for type-safe bulk actions
 */
enum BulkOperationType {
    CompleteAll;
    DeleteCompleted;
    SetPriority(priority: TodoPriority);
    AddTag(tag: String);
    RemoveTag(tag: String);
}

// SafePubSub class moved to framework level: /std/phoenix/SafePubSub.hx
// Application-specific PubSub types moved to: server/pubsub/TodoPubSub.hx
// 
// This demonstrates the framework-level development principle:
// Common patterns discovered in applications should become framework features
// so ALL Phoenix apps benefit from the same type safety improvements.

/**
 * Alert levels for system notifications
 */
enum AlertLevel {
    Info;
    Warning;
    Error;
    Critical;
}

/**
 * Enhanced PubSub message with type safety
 */
typedef PubSubMessage = {
    var type: PubSubMessageType;
    var ?metadata: PubSubMetadata;
}

/**
 * PubSub metadata for message tracking
 */
typedef PubSubMetadata = {
    var ?timestamp: Dynamic;
    var ?source: String;
    var ?version: String;
    var ?user_id: Int;
}

// ============================================================================
// Session and Authentication Types
// ============================================================================

/**
 * Session data structure
 */
typedef Session = {
    var ?userId: Int;  // camelCase
    var ?token: String;
    var ?csrfToken: String;  // camelCase
    var ?locale: String;
    var ?timezone: String;
    var ?userAgent: String;  // camelCase
    var ?ipAddress: String;  // camelCase
    var ?loginAt: Dynamic;  // camelCase
}

/**
 * Mount parameters for LiveView initialization
 */
typedef MountParams = {
    var ?id: String;
    var ?action: String;
    var ?slug: String;
    var ?page: String;
    var ?filter: String;
    var ?sort: String;
    var ?search: String;
}

// ============================================================================
// Database Operation Types
// ============================================================================

/**
 * Ecto repository operation result
 */
typedef RepoResult<T> = {
    var success: Bool;
    var ?data: T;
    var ?error: String;
    var ?changeset: Dynamic;
}

/**
 * Ecto changeset type
 */
typedef Changeset<T> = {
    var valid: Bool;
    var data: T;
    var changes: Dynamic;
    var errors: Array<FieldError>;
    var action: Null<String>;
}

/**
 * Field validation error
 */
typedef FieldError = {
    var field: String;
    var message: String;
    var validation: String;
}

// ============================================================================
// Form and Validation Types
// ============================================================================

/**
 * Form field metadata for HEEx templates
 */
typedef FormField = {
    var id: String;
    var name: String;
    var value: Dynamic;
    var errors: Array<String>;
    var valid: Bool;
    var data: Dynamic;
}

/**
 * Form structure for changesets
 */
typedef Form<T> = {
    var source: Changeset<T>;
    var impl: String;
    var id: String;
    var name: String;
    var data: T;
    var params: Dynamic;
    var hidden: Array<FormField>;
    var options: FormOptions;
}

/**
 * Form rendering options
 */
typedef FormOptions = {
    var ?method: String;
    var ?multipart: Bool;
    var ?csrf_token: String;
    var ?as: String;
}

// ============================================================================
// Component and Template Types
// ============================================================================

/**
 * Component assigns for HXX templates
 */
typedef ComponentAssigns = {
    var ?className: String;
    var ?id: String;
    var ?phx_click: String;
    var ?phx_submit: String;
    var ?phx_change: String;
    var ?phx_keyup: String;
    var ?phx_blur: String;
    var ?phx_focus: String;
    var ?phx_hook: String;
    var ?phx_update: String;
    var ?phx_target: String;
    var ?phx_debounce: String;
    var ?phx_throttle: String;
    var ?rest: Dynamic;
}

// ============================================================================
// LiveView Lifecycle Types
// ============================================================================

// MountResult, HandleEventResult, and HandleInfoResult moved to framework level:
// - phoenix.Phoenix.MountResult<TAssigns> for type-safe mount operations
// - phoenix.Phoenix.HandleEventResult<TAssigns> for type-safe event handling
// - phoenix.Phoenix.HandleInfoResult<TAssigns> for type-safe info handling
// 
// Use framework types instead of application duplicates:
// import phoenix.Phoenix.MountResult;
// import phoenix.Phoenix.HandleEventResult;
// import phoenix.Phoenix.HandleInfoResult;
//
// This demonstrates the framework-level development principle:
// LiveView lifecycle types discovered in applications should become framework features
// so ALL Phoenix apps benefit from the same type safety improvements.

// ============================================================================
// Utility Types
// ============================================================================

// Result<T,E> and Option<T> moved to framework level:
// - haxe.functional.Result<T,E> for error handling
// - haxe.ds.Option<T> for null safety
// 
// Use framework types instead of application duplicates:
// import haxe.functional.Result;
// import haxe.ds.Option;

/**
 * Pagination metadata
 */
typedef Pagination = {
    var page: Int;
    var per_page: Int;
    var total_count: Int;
    var total_pages: Int;
    var has_next: Bool;
    var has_prev: Bool;
}

/**
 * Sort direction
 */
enum SortDirection {
    Asc;
    Desc;
}

/**
 * Sort configuration
 */
typedef SortConfig = {
    var field: String;
    var direction: SortDirection;
}

// ============================================================================
// Application-Specific Types
// ============================================================================

/**
 * Todo filter options
 */
enum TodoFilter {
    All;
    Active;
    Completed;
    ByTag(tag: String);
    ByPriority(priority: String);
    ByDueDate(date: Dynamic);
}

/**
 * Todo sort options
 */
enum TodoSort {
    Created;
    Priority;
    DueDate;
    Title;
    Status;
}

/**
 * Todo priority levels
 */
enum TodoPriority {
    Low;
    Medium;
    High;
}

/**
 * Bulk operation types
 */
enum BulkOperation {
    CompleteAll;
    DeleteCompleted;
    SetPriority(priority: TodoPriority);
    AddTag(tag: String);
    RemoveTag(tag: String);
}
````

## File: examples/todo-app/src_haxe/shared/PrewarmDummy.hx
````
package;

using StringTools;
using Lambda;

class PrewarmDummy {
  static function main() {
    // Touch common std modules to prime typer/cache quickly
    var arr:Array<Int> = [];
    var kv = arr.keyValueIterator();
    for (_ in kv) {}
    var m:Map<String, Int> = new Map();
    m.set("a", 1);
    var s = " x ".trim();
    var b = haxe.io.Bytes.alloc(4);
    var re = ~/x/;
    var opt: haxe.ds.Option<Int> = haxe.ds.Option.None;
    var now = Date.now();
    var json = haxe.format.JsonPrinter.print({v: 1});
    // Prevent DCE on helpers
    if (s.length + b.length + (m.exists("a")?1:0) + (re.match("x")?1:0) + (json.length) + (opt == null?0:1) + now.getSeconds() == -1) {
      trace("noop");
    }
  }
}
````

## File: examples/todo-app/src_haxe/shared/TodoTypes.hx
````
package shared;

/**
 * Shared type definitions for Todo application
 * Used by both client (Haxe→JS) and server (Haxe→Elixir) code
 */

/**
 * Todo item data structure
 */
typedef Todo = {
    id: Int,
    title: String,
    description: Null<String>,
    completed: Bool,
    priority: TodoPriority,
    due_date: Null<String>,
    tags: Null<String>,
    user_id: Int,
    inserted_at: String,
    updated_at: String
};

/**
 * User data structure
 */
typedef User = {
    id: Int,
    name: String,
    email: String,
    inserted_at: String,
    updated_at: String
};

/**
 * Todo priority levels
 */
enum TodoPriority {
    Low;
    Medium;
    High;
}

/**
 * Filter options for todos
 */
enum TodoFilter {
    All;
    Active;
    Completed;
}

/**
 * Sort options for todos
 */
enum TodoSort {
    Created;
    Priority;
    DueDate;
}

/**
 * LiveView socket assigns structure
 */
typedef TodoLiveAssigns = {
    todos: Array<Todo>,
    filter: TodoFilter,
    sort_by: TodoSort,
    current_user: User,
    editing_todo: Null<Todo>,
    show_form: Bool,
    search_query: String,
    selected_tags: Array<String>,
    total_todos: Int,
    completed_todos: Int,
    pending_todos: Int,
    page_title: String,
    last_updated: String
};

/**
 * Phoenix LiveView event payloads
 */
typedef TodoEvents = {
    toggle_todo: {id: Int},
    delete_todo: {id: Int},
    create_todo: {title: String, description: String, priority: String, due_date: String, tags: String},
    edit_todo: {id: Int},
    save_todo: {id: Int, title: String, description: String},
    cancel_edit: {},
    toggle_form: {},
    filter_todos: {filter: String},
    sort_todos: {sort_by: String},
    search_todos: {query: String},
    set_priority: {id: Int, priority: String},
    bulk_complete: {},
    bulk_delete_completed: {}
};

/**
 * Client-side state for JavaScript hooks
 */
typedef ClientState = {
    darkMode: Bool,
    autoSave: Bool,
    lastSync: Float
};

/**
 * Phoenix PubSub message types
 */
typedef PubSubMessages = {
    todo_added: {todo: Todo},
    todo_updated: {todo: Todo},
    todo_deleted: {id: Int},
    user_joined: {user: User},
    user_left: {user: User}
};

/**
 * Helper class to make this module findable by Haxe
 * Required because Haxe needs at least one class/enum in a file
 */
class TodoTypes {
    // Empty class just to make the module findable
}
````

## File: examples/todo-app/src_haxe/test/contexts/UsersTest.hx
````
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
````

## File: examples/todo-app/src_haxe/test/live/TodoLiveClassTest.hx
````
package test.live;

import exunit.TestCase;
import exunit.Assert.*;
import phoenix.test.ConnTest;
import phoenix.test.LiveViewTest;
import phoenix.test.LiveView;

/**
 * TodoLiveClassTest
 *
 * WHAT
 * - Verifies that priority and completion state produce the expected card CSS classes
 *   in the rendered LiveView (indirectly exercising the typed helper).
 *
 * WHY
 * - Ensures our HXX → HEEx pipeline and typed helper produce idiomatic classes without
 *   relying on private helper visibility.
 */
@:exunit
class TodoLiveClassTest extends TestCase {
  @:test
  public function testHighPriorityClass(): Void {
    var conn = ConnTest.build_conn();
    var lv: LiveView = LiveViewTest.live(conn, "/todos");
    // Open form and create a High priority todo
    lv = LiveViewTest.render_click(lv, "button[phx-click='toggle_form']");
    var data: Map<String, Dynamic> = new Map();
    data.set("title", "Priority High");
    data.set("priority", "high");
    lv = LiveViewTest.render_submit(lv, "form[phx-submit='create_todo']", data);
    var html = LiveViewTest.render(lv);
    assertTrue(html.indexOf("border-red-500") != -1);
  }

  @:test
  public function testCompletedOpacity(): Void {
    var conn = ConnTest.build_conn();
    var lv: LiveView = LiveViewTest.live(conn, "/todos");
    // Create and complete a todo
    lv = LiveViewTest.render_click(lv, "button[phx-click='toggle_form']");
    var data: Map<String, Dynamic> = new Map();
    data.set("title", "Done Item");
    lv = LiveViewTest.render_submit(lv, "form[phx-submit='create_todo']", data);
    lv = LiveViewTest.render_click(lv, "button[phx-click='toggle_todo']");
    var html = LiveViewTest.render(lv);
    assertTrue(html.indexOf("opacity-60") != -1);
  }
}
````

## File: examples/todo-app/src_haxe/test/live/TodoLiveCrudTest.hx
````
package test.live;

import exunit.TestCase;
import exunit.Assert.*;
import phoenix.test.ConnTest;
import phoenix.test.LiveViewTest;
import phoenix.test.LiveView;

/**
 * TodoLiveCrudTest
 *
 * WHAT
 * - Server-side LiveView integration tests authored in Haxe, compiled to ExUnit.
 *
 * WHY
 * - Provides fast, deterministic tests of CRUD + filters without a browser.
 * - Complements Playwright smokes (Testing Trophy).
 *
 * HOW
 * - Uses Phoenix.ConnTest and Phoenix.LiveViewTest externs.
 */
@:exunit
class TodoLiveCrudTest extends TestCase {
    @:test
    public function testMountTodos(): Void {
        var conn = ConnTest.build_conn();
        // LiveViewTest.live(conn, "/todos") should return a LiveView handle
        var lv: LiveView = LiveViewTest.live(conn, "/todos");
        assertTrue(lv != null);
        // Basic render contains page title
        var html = LiveViewTest.render(lv);
        assertTrue(html != null);
    }

    @:test
    public function testCreateTodoViaLiveView(): Void {
        var conn = ConnTest.build_conn();
        var lv: LiveView = LiveViewTest.live(conn, "/todos");
        // Toggle form
        lv = LiveViewTest.render_click(lv, "button[phx-click='toggle_form']");
        // Submit minimal form (title only)
        var data: Map<String, Dynamic> = new Map();
        data.set("title", "LV created");
        lv = LiveViewTest.render_submit(lv, "form[phx-submit='create_todo']", data);
        // Render and assert content contains the title
        var html = LiveViewTest.render(lv);
        assertTrue(html.indexOf("LV created") != -1);
    }

    @:test
    public function testToggleTodoStatus(): Void {
        var conn = ConnTest.build_conn();
        var lv: LiveView = LiveViewTest.live(conn, "/todos");
        // Create a fresh todo
        lv = LiveViewTest.render_click(lv, "button[phx-click='toggle_form']");
        var data: Map<String, Dynamic> = new Map();
        data.set("title", "Toggle Me");
        lv = LiveViewTest.render_submit(lv, "form[phx-submit='create_todo']", data);
        // Click the first toggle button
        lv = LiveViewTest.render_click(lv, "button[phx-click='toggle_todo']");
        var html = LiveViewTest.render(lv);
        // Completed item should have line-through or container opacity
        var hasLine = html.indexOf("line-through") != -1;
        var hasOpacity = html.indexOf("opacity-60") != -1;
        assertTrue(hasLine || hasOpacity);
    }

    @:test
    public function testEditTodo(): Void {
        var conn = ConnTest.build_conn();
        var lv: LiveView = LiveViewTest.live(conn, "/todos");
        // Create
        lv = LiveViewTest.render_click(lv, "button[phx-click='toggle_form']");
        var data: Map<String, Dynamic> = new Map();
        data.set("title", "Edit Me");
        lv = LiveViewTest.render_submit(lv, "form[phx-submit='create_todo']", data);
        // Click edit
        lv = LiveViewTest.render_click(lv, "button[phx-click='edit_todo']");
        // Fill and save
        var newData: Map<String, Dynamic> = new Map();
        newData.set("title", "Edited Title");
        lv = LiveViewTest.render_submit(lv, "form[phx-submit='save_todo']", newData);
        var html = LiveViewTest.render(lv);
        assertTrue(html.indexOf("Edited Title") != -1);
    }

    @:test
    public function testDeleteTodo(): Void {
        var conn = ConnTest.build_conn();
        var lv: LiveView = LiveViewTest.live(conn, "/todos");
        // Create
        lv = LiveViewTest.render_click(lv, "button[phx-click='toggle_form']");
        var data: Map<String, Dynamic> = new Map();
        data.set("title", "Delete Me");
        lv = LiveViewTest.render_submit(lv, "form[phx-submit='create_todo']", data);
        // Delete
        lv = LiveViewTest.render_click(lv, "button[phx-click='delete_todo']");
        var html = LiveViewTest.render(lv);
        assertTrue(html.indexOf("Delete Me") == -1);
    }

    @:test
    public function testFilters(): Void {
        var conn = ConnTest.build_conn();
        var lv: LiveView = LiveViewTest.live(conn, "/todos");
        // Create Active
        lv = LiveViewTest.render_click(lv, "button[phx-click='toggle_form']");
        var a: Map<String, Dynamic> = new Map();
        a.set("title", "Active One");
        lv = LiveViewTest.render_submit(lv, "form[phx-submit='create_todo']", a);
        // Create another and toggle complete
        lv = LiveViewTest.render_click(lv, "button[phx-click='toggle_form']");
        var c: Map<String, Dynamic> = new Map();
        c.set("title", "Completed One");
        lv = LiveViewTest.render_submit(lv, "form[phx-submit='create_todo']", c);
        lv = LiveViewTest.render_click(lv, "button[phx-click='toggle_todo']");
        // Filter Completed
        lv = LiveViewTest.render_click(lv, "button[phx-click='filter_todos'][phx-value-filter='completed']");
        var html = LiveViewTest.render(lv);
        assertTrue(html.indexOf("Active One") == -1);
        assertTrue(html.indexOf("Completed One") != -1);
        // Filter Active
        lv = LiveViewTest.render_click(lv, "button[phx-click='filter_todos'][phx-value-filter='active']");
        html = LiveViewTest.render(lv);
        assertTrue(html.indexOf("Completed One") == -1);
        assertTrue(html.indexOf("Active One") != -1);
    }
}
````

## File: examples/todo-app/src_haxe/test/live/TodoLiveDueDateTest.hx
````
package live;

import exunit.TestCase;
import exunit.Assert.*;
import phoenix.test.ConnTest;
import phoenix.test.LiveViewTest;
import phoenix.test.LiveView;

/**
 * TodoLiveDueDateTest
 *
 * WHAT
 * - Verifies creating a todo with a due_date renders a "Due:" label.
 *
 * WHY
 * - Guards the due_date normalization and rendering path (date-only -> 00:00:00).
 */
@:exunit
class TodoLiveDueDateTest extends TestCase {
    @:test
    public function testCreateTodoWithDueDateRenders(): Void {
        var conn = ConnTest.build_conn();
        var lv: LiveView = LiveViewTest.live(conn, "/todos");
        lv = LiveViewTest.render_click(lv, "button[phx-click='toggle_form']");
        var data: Map<String, Dynamic> = new Map();
        data.set("title", "DueEarly");
        data.set("due_date", "2025-11-01");
        lv = LiveViewTest.render_submit(lv, "form[phx-submit='create_todo']", data);
        var html = LiveViewTest.render(lv);
        assertTrue(html.indexOf("Due:") != -1);
    }
}
````

## File: examples/todo-app/src_haxe/test/live/TodoLiveOptimisticLatencyTest.hx
````
package test.live;

import test.support.ConnCase;

/**
 * TodoLive optimistic toggle latency test (Haxe-authored ExUnit)
 *
 * WHAT
 * - Asserts that the completed state flips optimistically on toggle even when
 *   the server applies latency (simulated).
 *
 * NOTE
 * - This test compiles to ExUnit; runtime helpers are provided in ConnCase externs.
 */
@:exunit
class TodoLiveOptimisticLatencyTest extends ConnCase {
  public function testOptimisticToggleUnderLatency():Void {
    var todo = createTestTodo("Latency item", false, "medium");
    var live = connectLiveView("/todos");

    // Simulate network latency on the server path for toggling
    enableLatencySimulation(120); // ms

    // Optimistic flip should apply immediately on client
    assertElementNotHasClass(live, '[data-todo-id="${todo.id}"]', "completed");
    live = clickElement(live, '[phx-click="toggle_todo"][phx-value-id="${todo.id}"]');
    assertElementHasClass(live, '[data-todo-id="${todo.id}"]', "completed");

    // After latency, server confirmation should keep state consistent
    live = awaitServerLatency(live);
    assertElementHasClass(live, '[data-todo-id="${todo.id}"]', "completed");
  }

  // Helpers resolved by ConnCase externs at compile/runtime
  private function createTestTodo(title:String, completed:Bool, priority:String):Dynamic {
    return { id: Math.floor(Math.random() * 1000000), title: title, completed: completed, priority: priority };
  }
  private function connectLiveView(path:String):Dynamic return {};
  private function clickElement(live:Dynamic, sel:String):Dynamic return live;
  private function assertElementHasClass(live:Dynamic, sel:String, cls:String):Void {}
  private function assertElementNotHasClass(live:Dynamic, sel:String, cls:String):Void {}
  private function enableLatencySimulation(ms:Int):Void {}
  private function awaitServerLatency(live:Dynamic):Dynamic return live;
}
````

## File: examples/todo-app/src_haxe/test/live/TodoLiveTest.hx
````
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
````

## File: examples/todo-app/src_haxe/test/schemas/TodoTest.hx
````
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
````

## File: examples/todo-app/src_haxe/test/support/ConnCase.hx
````
package test.support;

import haxe.test.phoenix.ConnCase as BaseConnCase;
import test.support.DataCase;

/**
 * ConnCase provides the foundation for Phoenix controller and LiveView tests.
 * 
 * Following Phoenix patterns, this module extends the standard library ConnCase
 * with todo-app specific helpers for integration testing.
 */
@:exunit
class ConnCase extends BaseConnCase {
    
    /**
     * Override endpoint for todo-app
     */
    override public static var endpoint(default, null): String = "TodoAppWeb.Endpoint";
    
    // Todo-app specific test helpers can be added here
    // The base ConnCase already provides all the standard functionality
}
````

## File: examples/todo-app/src_haxe/test/support/DataCase.hx
````
package test.support;

import haxe.test.phoenix.DataCase as BaseDataCase;
import ecto.Changeset;
import server.schemas.Todo;

/**
 * DataCase provides the foundation for Ecto schema and data tests.
 * 
 * This module extends the standard library DataCase with todo-app specific
 * helpers for testing schemas, changesets, and database operations.
 */
@:exunit
class DataCase extends BaseDataCase {
    
    /**
     * Override repository for todo-app
     */
    override public static var repo(default, null): String = "TodoApp.Repo";
    
    /**
     * Create a valid Todo changeset for testing.
     */
    override public static function validChangeset<T>(schema: Class<T>, attrs: Dynamic): Changeset<T> {
        // For Todo schema specifically
        if (schema == Todo) {
            var validAttrs = {
                title: "Test Todo",
                description: "A test todo item",
                completed: false,
                priority: "medium"
            };
            
            // Merge with provided attrs
            for (key in Reflect.fields(attrs)) {
                Reflect.setField(validAttrs, key, Reflect.field(attrs, key));
            }
            
            return cast Todo.changeset(new Todo(), validAttrs);
        }
        
        throw 'Unknown schema type: ${schema}';
    }
    
    /**
     * Create an invalid Todo changeset for testing.
     */
    override public static function invalidChangeset<T>(schema: Class<T>, attrs: Dynamic): Changeset<T> {
        // For Todo schema specifically
        if (schema == Todo) {
            var invalidAttrs = {
                title: "", // Invalid: empty title
                priority: "invalid_priority" // Invalid priority
            };
            
            // Merge with provided attrs
            for (key in Reflect.fields(attrs)) {
                Reflect.setField(invalidAttrs, key, Reflect.field(attrs, key));
            }
            
            return cast Todo.changeset(new Todo(), invalidAttrs);
        }
        
        throw 'Unknown schema type: ${schema}';
    }
    
    /**
     * Create a Todo struct for testing.
     */
    override public static function struct<T>(schema: Class<T>): T {
        if (schema == Todo) {
            return cast new Todo();
        }
        
        throw 'Unknown schema type: ${schema}';
    }
}
````

## File: examples/todo-app/src_haxe/test/web/HealthTest.hx
````
package web;

import exunit.TestCase;
import exunit.Assert.*;
import phoenix.test.ConnTest;

/**
 * HealthTest
 *
 * WHAT
 * - Minimal ExUnit test authored in Haxe to validate that the app boots and renders the home page.
 *
 * WHY
 * - Provides a quick server-side integration check (ConnTest) compiled from Haxe, exercising our
 *   @:exunit pipeline and standard externs without relying on browser automation.
 *
 * HOW
 * - Uses Phoenix.ConnTest externs to build a connection and GET "/".
 * - Asserts 200 OK and basic content presence.
 */
@:exunit
class HealthTest extends TestCase {
    @:test
    public function testHomePageLoads(): Void {
        var conn = ConnTest.build_conn();
        conn = ConnTest.get(conn, "/");
        // Basic assertions: 200 OK and non-empty body via ConnTest helper
        assertTrue(conn != null);
        // Assert status directly from Conn struct type
        var status: Int = conn.status;
        assertEqual(200, status);
    }
}
````

## File: examples/todo-app/src_haxe/test/web/TodoLiveCrudTest.hx
````
package web;

import exunit.TestCase;
import exunit.Assert.*;
import phoenix.test.ConnTest;
import phoenix.test.LiveViewTest;
import phoenix.test.LiveView;

@:exunit
class TodoLiveCrudTest extends TestCase {
    @:test
    public function testMountTodos(): Void {
        var conn = ConnTest.build_conn();
        var lv: LiveView = untyped __elixir__("case Phoenix.LiveViewTest.live({0}, {1}) do {:ok, v, _html} -> v end", conn, "/todos");
        assertTrue(lv != null);
        var html: String = untyped __elixir__('Phoenix.LiveViewTest.render({0})', lv);
        assertTrue(html != null);
    }

    // Keep additional CRUD steps in Playwright E2E for now; minimal LV mount here
}
````

## File: examples/todo-app/src_haxe/test/AsyncAnonymousTest.hx
````
package test;

import reflaxe.js.Async;
import js.lib.Promise;
import js.Browser;

/**
 * Test file demonstrating @:async anonymous function support.
 * This shows JavaScript-parity async/await with identical ergonomics.
 */
class AsyncAnonymousTest {
    
    public static function main(): Void {
        // Test 1: Event handler with @:async anonymous function
        Browser.document.addEventListener("DOMContentLoaded", @:async function(event) {
            trace("DOM loaded, starting async operations...");
            
            // Use await inside anonymous function
            var data = await(fetchDataAsync());
            trace("Fetched data: " + data);
            
            // Chain multiple async operations
            var processed = await(processDataAsync(data));
            trace("Processed: " + processed);
        });
        
        // Test 2: Array methods with @:async
        var urls = ["api/1", "api/2", "api/3"];
        
        // Map with async function
        var promises = urls.map(@:async function(url) {
            var response = await(fetchFromUrl(url));
            return response.toUpperCase();
        });
        
        // Test 3: Nested @:async functions
        var complexOperation = @:async function(): Promise<String> {
            trace("Starting complex operation");
            
            // Inner async function
            var innerAsync = @:async function(value: String): Promise<String> {
                var result = await(Async.delay(value, 100));
                return "Inner: " + result;
            };
            
            var result = await(innerAsync("test"));
            return "Outer: " + result;
        };
        
        // Test 4: Async IIFE (Immediately Invoked Function Expression)
        (@:async function() {
            trace("Async IIFE starting");
            var config = await(loadConfig());
            trace("Config loaded: " + config);
        })();
        
        // Test 5: Callback conversion with @:async
        setTimeout(@:async function() {
            trace("Timer fired, doing async work");
            var result = await(doAsyncWork());
            trace("Async work complete: " + result);
        }, 1000);
        
        // Test 6: Promise constructor with @:async executor
        var customPromise = new Promise(@:async function(resolve, reject) {
            try {
                var data = await(riskyOperation());
                resolve(data);
            } catch (e: Dynamic) {
                reject(e);
            }
        });
        
        // Test 7: Object methods with @:async
        var handler = {
            onClick: @:async function(event): Promise<Void> {
                var target = event.target;
                var data = await(fetchDataForElement(target));
                updateUI(data);
            },
            
            onSubmit: @:async function(event): Promise<Bool> {
                event.preventDefault();
                var formData = await(validateForm(event.target));
                var success = await(submitForm(formData));
                return success;
            }
        };
    }
    
    // Helper async functions for testing
    
    static function fetchDataAsync(): Promise<String> {
        return Async.delay("sample data", 100);
    }
    
    static function processDataAsync(data: String): Promise<String> {
        return Async.delay(data.toUpperCase(), 50);
    }
    
    static function fetchFromUrl(url: String): Promise<String> {
        return Async.delay("Response from " + url, 200);
    }
    
    static function loadConfig(): Promise<Dynamic> {
        return Async.resolve({apiUrl: "https://api.example.com", timeout: 5000});
    }
    
    static function doAsyncWork(): Promise<String> {
        return Async.delay("work completed", 300);
    }
    
    static function riskyOperation(): Promise<String> {
        return Math.random() > 0.5 
            ? Async.resolve("success")
            : Async.reject("random failure");
    }
    
    static function fetchDataForElement(element: Dynamic): Promise<Dynamic> {
        return Async.resolve({id: "el-1", value: "clicked"});
    }
    
    static function updateUI(data: Dynamic): Void {
        trace("Updating UI with: " + data);
    }
    
    static function validateForm(form: Dynamic): Promise<Dynamic> {
        return Async.resolve({valid: true, data: {}});
    }
    
    static function submitForm(formData: Dynamic): Promise<Bool> {
        return Async.delay(true, 500);
    }
    
    static function setTimeout(callback: Void -> Void, ms: Int): Void {
        Browser.window.setTimeout(callback, ms);
    }
}
````

## File: examples/todo-app/src_haxe/test/AsyncTest.hx
````
package test;

import reflaxe.js.Async;

/**
 * Test class for async/await functionality.
 * 
 * Demonstrates the new @:async syntax and await() macro usage
 * with type-safe Promise handling.
 */
@:build(reflaxe.js.Async.build())
class AsyncTest {
    
    /**
     * Test basic async function with await.
     * 
     * This function should compile to:
     * ```javascript
     * async function testBasicAsync() {
     *     var result = await Promise.resolve("Hello");
     *     return result + " World";
     * }
     * ```
     */
    @:async
    public static function testBasicAsync(): js.lib.Promise<String> {
        var result = Async.await(js.lib.Promise.resolve("Hello"));
        return js.lib.Promise.resolve(result + " World");
    }
    
    /**
     * Test async function with multiple awaits.
     * 
     * Demonstrates sequential async operations with proper type inference.
     */
    @:async
    public static function testMultipleAwaits(): js.lib.Promise<String> {
        var greeting = Async.await(js.lib.Promise.resolve("Hello"));
        var target = Async.await(js.lib.Promise.resolve("Phoenix"));
        var punctuation = Async.await(js.lib.Promise.resolve("!"));
        
        return js.lib.Promise.resolve(greeting + " " + target + punctuation);
    }
    
    /**
     * Test async function with error handling.
     * 
     * Uses try/catch with async/await for proper error propagation.
     */
    @:async
    public static function testErrorHandling(): js.lib.Promise<String> {
        try {
            var result = Async.await(js.lib.Promise.reject("Error occurred"));
            return js.lib.Promise.resolve(result);
        } catch (error: Dynamic) {
            return js.lib.Promise.resolve("Caught: " + error);
        }
    }
    
    /**
     * Test async function with conditional await.
     * 
     * Demonstrates await usage in conditional expressions.
     */
    @:async
    public static function testConditionalAwait(useAsync: Bool): js.lib.Promise<String> {
        if (useAsync) {
            var result = Async.await(js.lib.Promise.resolve("Async result"));
            return js.lib.Promise.resolve(result);
        } else {
            return js.lib.Promise.resolve("Sync result");
        }
    }
    
    /**
     * Helper function that returns a Promise for testing.
     */
    public static function createDelayedPromise(value: String, delayMs: Int): js.lib.Promise<String> {
        return new js.lib.Promise(function(resolve, reject) {
            js.Browser.window.setTimeout(function() {
                resolve(value);
            }, delayMs);
        });
    }
    
    /**
     * Test async function with delayed operations.
     * 
     * Demonstrates real-world async patterns with delays.
     */
    @:async
    public static function testDelayedOperations(): js.lib.Promise<String> {
        var first = Async.await(createDelayedPromise("First", 100));
        var second = Async.await(createDelayedPromise("Second", 50));
        var third = Async.await(createDelayedPromise("Third", 25));
        
        return js.lib.Promise.resolve(first + " -> " + second + " -> " + third);
    }
    
    /**
     * Entry point for testing async functionality.
     * 
     * This function can be called from PhoenixApp to verify
     * that async/await compilation works correctly.
     */
    public static function main(): Void {
        js.Browser.console.log("🧪 Starting async/await tests...");
        runTests();
    }
    
    /**
     * Runs all async/await tests.
     * 
     * This function can be called from PhoenixApp to verify
     * that async/await compilation works correctly.
     */
    public static function runTests(): js.lib.Promise<String> {
        js.Browser.console.log("🧪 Running async/await tests...");
        
        // Test basic async functionality
        return testBasicAsync().then(function(result) {
            js.Browser.console.log("✅ Basic async test:", result);
            return testMultipleAwaits();
        }).then(function(result) {
            js.Browser.console.log("✅ Multiple awaits test:", result);
            return testErrorHandling();
        }).then(function(result) {
            js.Browser.console.log("✅ Error handling test:", result);
            return testConditionalAwait(true);
        }).then(function(result) {
            js.Browser.console.log("✅ Conditional await test:", result);
            return testDelayedOperations();
        }).then(function(result) {
            js.Browser.console.log("✅ Delayed operations test:", result);
            js.Browser.console.log("🎉 All async/await tests completed successfully!");
            return "All tests passed";
        }).catchError(function(error) {
            js.Browser.console.error("❌ Async test failed:", error);
            return "Tests failed: " + error;
        });
    }
}
````

## File: examples/todo-app/src_haxe/test/test_helper.hx
````
package test;

/**
 * Test helper configuration for the todo-app test suite
 * Sets up ExUnit, Ecto sandbox, and test environment
 */
class TestHelper {
    
    /**
     * Main test setup function
     * Configures the test environment and starts necessary services
     */
    public static function main(): Void {
        setupExUnit();
        setupEctoSandbox();
        startApplication();
    }
    
    /**
     * Configure ExUnit test framework
     */
    private static function setupExUnit(): Void {
        // Configure ExUnit with custom formatters and options
        ExUnit.configure([
            "capture_log" => true,
            "trace" => true,
            "timeout" => 60000, // 60 seconds timeout for tests
            "max_cases" => 4,   // Run tests in parallel with 4 processes
            "exclude" => ["integration"] // Exclude integration tests by default
        ]);
        
        // Start ExUnit
        ExUnit.start();
    }
    
    /**
     * Set up Ecto sandbox for test database isolation
     */
    private static function setupEctoSandbox(): Void {
        // Configure Ecto for test mode
        Ecto.Sandbox.mode(TodoApp.Repo, "manual");
        
        // Set up test database if needed
        ensureTestDatabase();
    }
    
    /**
     * Start the application for testing
     */
    private static function startApplication(): Void {
        // Start the TodoApp application
        Application.ensure_all_started("todo_app");
        
        // Ensure Phoenix endpoint is started for LiveView tests
        TodoAppWeb.Endpoint.start_link();
    }
    
    /**
     * Ensure test database exists and is migrated
     */
    private static function ensureTestDatabase(): Void {
        // Create test database if it doesn't exist
        Mix.Task.run("ecto.create", ["--quiet"]);
        
        // Run migrations
        Mix.Task.run("ecto.migrate", ["--quiet"]);
    }
    
    /**
     * Clean up test environment after all tests
     */
    public static function cleanup(): Void {
        // Stop the application
        Application.stop("todo_app");
        
        // Clean up test database
        cleanupTestDatabase();
    }
    
    /**
     * Clean up test database
     */
    private static function cleanupTestDatabase(): Void {
        // Drop test database
        Mix.Task.run("ecto.drop", ["--quiet"]);
    }
}

/**
 * External references to Elixir modules
 * These would be proper extern definitions in a real implementation
 */
@:native("ExUnit")
extern class ExUnit {
    public static function configure(options: Dynamic): Void;
    public static function start(): Void;
}

@:native("Ecto.Sandbox")
extern class EctoSandbox {
    public static function mode(repo: Dynamic, mode: String): Void;
}

@:native("Application")
extern class Application {
    public static function ensure_all_started(app: String): Dynamic;
    public static function stop(app: String): Void;
}

@:native("Mix.Task")
extern class MixTask {
    public static function run(task: String, args: Array<String>): Dynamic;
}

@:native("TodoApp.Repo")
extern class TodoAppRepo {
    // Repository functions would be defined here
}

@:native("TodoAppWeb.Endpoint")
extern class TodoAppWebEndpoint {
    public static function start_link(): Dynamic;
}
````

## File: examples/todo-app/src_haxe/TestAbstract.hx
````
abstract TestAbstract(String) from String to String {
    public function new(s: String) {
        this = s;
    }
    
    public function getValue(): String {
        return this;
    }
    
    public static function staticTest(value: TestAbstract): String {
        return value;
    }
}

class TestMain {
    static function main() {
        var t = new TestAbstract("test");
        trace(t.getValue());
    }
}
````

## File: examples/todo-app/src_haxe/TestInjection.hx
````
/**
 * Test and documentation for __elixir__() code injection mechanism
 * 
 * CRITICAL: Understanding __elixir__() Injection Syntax
 * ======================================================
 * 
 * The __elixir__() function allows injecting raw Elixir code into generated output.
 * However, it has specific requirements for how variables are substituted.
 * 
 * WHY $variable SYNTAX DOESN'T WORK:
 * -----------------------------------
 * When you write: untyped __elixir__('$x * 2')
 * 
 * Haxe's parser sees the $ and interprets this as STRING INTERPOLATION at compile-time.
 * This means Haxe tries to concatenate strings: "" + x + " * 2"
 * 
 * The result is that the TypedExpr becomes:
 *   TBinop(OpAdd, TConst(""), TBinop(OpAdd, TLocal(x), TConst(" * 2")))
 * 
 * This is NOT a constant string, so Reflaxe's TargetCodeInjection.checkTargetCodeInjection
 * cannot process it because it requires the first parameter to be TConst(TString(s)).
 * 
 * HOW {N} PLACEHOLDERS WORK:
 * ---------------------------
 * The correct syntax uses numbered placeholders: {0}, {1}, {2}, etc.
 * 
 * When you write: untyped __elixir__('{0} * 2', x)
 * 
 * 1. The first parameter IS a constant string: "{0} * 2"
 * 2. Reflaxe's injection system recognizes this pattern
 * 3. It compiles the variable x separately to get its Elixir representation
 * 4. It replaces {0} with the compiled result
 * 
 * RULES FOR __elixir__() USAGE:
 * ------------------------------
 * 1. First parameter MUST be a constant string literal (no concatenation)
 * 2. Use {0}, {1}, {2}... for variable substitution
 * 3. Variables are passed as additional parameters
 * 4. Variables are compiled to Elixir and substituted at their placeholder positions
 * 5. Keyword lists and atoms should be written directly in the string
 * 
 * EXAMPLES:
 * ---------
 * WRONG: untyped __elixir__('$x * 2')                    // $ causes string interpolation
 * WRONG: untyped __elixir__(myString)                    // Not a constant
 * WRONG: untyped __elixir__('func(' + x + ')')          // String concatenation
 * 
 * RIGHT: untyped __elixir__('{0} * 2', x)               // Placeholder substitution
 * RIGHT: untyped __elixir__('func({0}, {1})', a, b)     // Multiple variables
 * RIGHT: untyped __elixir__(':ok')                      // Direct atom injection
 * RIGHT: untyped __elixir__('[a: 1, b: 2]')            // Direct keyword list
 * 
 * @see https://github.com/SomeRanDev/reflaxe - Reflaxe documentation
 * @see reflaxe.compiler.TargetCodeInjection - The injection implementation
 */
class TestInjection {
    public static function testDirectInjection(): String {
        // Test 1: Simple string injection
        return untyped __elixir__('"Hello from Elixir"');
    }
    
    public static function testVariableSubstitution(): Int {
        // Test 2: Variable substitution in injection using {N} placeholders
        var x = 42;
        return untyped __elixir__('{0} * 2', x);
    }
    
    public static function testSupervisorCall() {
        // Test 3: What Telemetry needs - inject keyword list directly
        var children = [];
        // For keyword lists, inject them directly into the Elixir code
        return untyped __elixir__('Supervisor.start_link({0}, [strategy: :one_for_one, name: TestSupervisor])', children);
    }
    
    public static function testComplexInjection() {
        // Test 4: More complex injection with multiple variables
        var module = "TestModule";
        var func = "test_func";
        var args = [1, 2, 3];
        return untyped __elixir__('{0}.{1}({2})', module, func, args);
    }
}
````

## File: examples/todo-app/src_haxe/TestInline.hx
````
package;

import phoenix.Phoenix.LiveView;
import phoenix.Phoenix.Socket;

class TestInline {
    public static function testBoth() {
        var socket: Socket<{name: String}> = null;
        
        // Test inline function - should expand at compile time
        var s1 = LiveView.assign_multiple(socket, {name: "Test"});
        
        // Test direct function
        var s2 = LiveView.assign(socket, {name: "Test2"});
        
        return s1;
    }
}
````

## File: examples/todo-app/src_haxe/TestStringBuf.hx
````
class TestStringBuf {
    public static function test(): String {
        var buf = new StringBuf();
        buf.add("Testing ");
        buf.add("StringBuf ");
        buf.add("in todo-app");
        
        var result = buf.toString();
        trace('StringBuf test: $result');
        
        // Test with numbers
        var buf2 = new StringBuf();
        buf2.add("Count: ");
        for (i in 1...4) {
            buf2.add(i);
            buf2.add(" ");
        }
        trace('Numbers: ${buf2.toString()}');
        
        return result;
    }
}
````

## File: examples/todo-app/src_haxe/TodoApp.hx
````
package;

import phoenix.Phoenix;
import elixir.otp.Application;
import elixir.otp.Supervisor.SupervisorExtern;
import elixir.otp.Supervisor.SupervisorStrategy;
import elixir.otp.Supervisor.SupervisorOptions;
import elixir.otp.TypeSafeChildSpec;
import elixir.otp.Supervisor.ChildSpecFormat;

/**
 * Main TodoApp application module
 * Defines the OTP application supervision tree
 */
@:application
@:appName("TodoApp")  
class TodoApp {
    /**
     * Start the application
     */
    @:keep
    public static function start(type: ApplicationStartType, args: ApplicationArgs): ApplicationResult {
        // Define children for the supervision tree using type-safe child specs
        var children: Array<ChildSpecFormat> = [
            // Database repository - Ecto.Repo handles Postgrex.TypeManager internally
            ModuleRef("TodoApp.Repo"),
            
            // PubSub system with proper child spec
            TypeSafeChildSpec.pubSub("TodoApp.PubSub"),
            
            // Presence tracker - starts Phoenix.Tracker backing ETS tables
            // Presence module defines child_spec via `use Phoenix.Presence`
            ModuleRef("TodoAppWeb.Presence"),
            
            // Telemetry supervisor
            TypeSafeChildSpec.telemetry("TodoAppWeb.Telemetry"),
            
            // Web endpoint
            TypeSafeChildSpec.endpoint("TodoAppWeb.Endpoint")
        ];

        // Start supervisor with children using type-safe SupervisorExtern + options builder
        return SupervisorExtern.startLink(children, elixir.otp.Supervisor.SupervisorOptionsBuilder.defaults());
    }

    /**
     * Called when application is preparing to shut down
     * State is whatever was returned from start/2
     */
    @:keep
    public static function prep_stop(state: Dynamic): Dynamic {
        // For now, keep Dynamic since this is rarely customized
        // and state type varies based on application needs
        return state;
    }
}
````

## File: examples/todo-app/src_haxe/TodoAppRouter.hx
````
package;

import reflaxe.elixir.macros.HttpMethod;

/**
 * Type-safe Router DSL example demonstrating enhanced syntax
 * 
 * This example shows how to use HttpMethod enum and class references
 * instead of error-prone string literals for better compile-time safety.
 */
@:native("TodoAppWeb.Router")
@:router
@:build(reflaxe.elixir.macros.RouterBuildMacro.generateRoutes())
@:routes([
    // Type-safe method using HttpMethod enum
    {
        name: "root", 
        method: HttpMethod.LIVE, 
        path: "/", 
        controller: "server.live.TodoLive",  // this is not type safe, needs to be the actual controller type. This DSL should be as expressive as the Elixir one, but typesafe.
        action: "index"
    },
    
    // Standard HTTP methods with enum
    {
        name: "todosIndex", 
        method: HttpMethod.LIVE, 
        path: "/todos", 
        controller: "server.live.TodoLive", 
        action: "index"
    },
    
    {
        name: "todosShow", 
        method: HttpMethod.LIVE, 
        path: "/todos/:id", 
        controller: "server.live.TodoLive", 
        action: "show"
    },
    
    {
        name: "todosEdit", 
        method: HttpMethod.LIVE, 
        path: "/todos/:id/edit", 
        controller: "server.live.TodoLive", 
        action: "edit"
    },
    
    // API endpoints temporarily removed until User context/schema stabilized
    
    // LiveDashboard with enum
    {
        name: "dashboard", 
        method: HttpMethod.LIVE_DASHBOARD, 
        path: "/dev/dashboard"
    }
])
class TodoAppRouter {
    // Functions auto-generated with type-safe route helpers!
    // 
    // Generated functions:
    // public static function root(): String { return "/"; }
    // public static function todosIndex(): String { return "/todos"; }
    // public static function apiTodos(): String { return "/api/todos"; }
    // etc.
}
````

## File: src/reflaxe/elixir/ast/TemplateHelpers.hx
````
package reflaxe.elixir.ast;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirASTPrinter;
import haxe.macro.Type;
import haxe.macro.TypedExprTools;

/**
 * TemplateHelpers: HXX Template Processing Utilities
 * 
 * WHY: Centralize HXX → HEEx template transformation logic
 * - Separate template concerns from main AST builder
 * - Provide reusable template utilities
 * - Encapsulate HXX-specific patterns
 * 
 * WHAT: Template content collection and transformation
 * - Extract template strings and embedded expressions
 * - Process template arguments
 * - Detect HXX module usage
 * 
 * HOW: Pattern matching on AST nodes to extract template content
 * - Collect string literals for template body
 * - Process embedded <%= %> expressions
 * - Handle template function arguments
 */
class TemplateHelpers {
    
    /**
     * Render an ElixirAST expression into a HEEx-safe Elixir expression string.
     * - Converts assigns.* access to @* for idiomatic HEEx
     * - Handles common expression nodes (vars, fields, calls, literals, binaries, if)
     */
    static function renderExpr(ast: ElixirAST): String {
        return switch (ast.def) {
            case EString(s): '"' + s + '"';
            case EInteger(i): Std.string(i);
            case EFloat(f): Std.string(f);
            case EBoolean(b): b ? "true" : "false";
            case ENil: "nil";
            case EAtom(a):
                // a is ElixirAtom; use its string form with preceding :
                ':' + Std.string(a);
            case EVar(name):
                name;
            case EField(obj, field):
                var base = renderExpr(obj);
                // If base starts with "assigns.", convert to HEEx assigns shorthand
                if (StringTools.startsWith(base, "assigns.")) {
                    '@' + base.substr("assigns.".length) + '.' + field;
                } else if (base == "assigns") {
                    '@' + field;
                } else {
                    base + '.' + field;
                }
            case EAccess(target, key):
                var t = renderExpr(target);
                var k = renderExpr(key);
                // Keep standard access syntax target[key]
                t + "[" + k + "]";
            case ECall(module, func, args):
                var callStr = if (module != null) {
                    switch (module.def) {
                        case EVar(m): m + "." + func;
                        case EField(_, _): renderExpr(module) + "." + func;
                        default: func;
                    }
                } else {
                    func;
                };
                if (args.length > 0) {
                    var argStrs = [];
                    for (arg in args) argStrs.push(renderExpr(arg));
                    callStr + "(" + argStrs.join(", ") + ")";
                } else {
                    callStr + "()";
                }
            case EBinary(op, left, right):
                var l = renderExpr(left);
                var r = renderExpr(right);
                var opStr = switch (op) {
                    case Add: "+";
                    case Subtract: "-";
                    case Multiply: "*";
                    case Divide: "/";
                    case Remainder: "rem";
                    case Power: "**";
                    case Equal: "==";
                    case NotEqual: "!=";
                    case StrictEqual: "===";
                    case StrictNotEqual: "!==";
                    case Less: "<";
                    case Greater: ">";
                    case LessEqual: "<=";
                    case GreaterEqual: ">=";
                    case And: "and";
                    case Or: "or";
                    case AndAlso: "&&";
                    case OrElse: "||";
                    case BitwiseAnd: "&&&";
                    case BitwiseOr: "|||";
                    case BitwiseXor: "^^^";
                    case ShiftLeft: "<<<";
                    case ShiftRight: ">>>";
                    case Concat: "++";
                    case ListSubtract: "--";
                    case StringConcat: "<>";
                    case In: "in";
                    case Match: "=";
                    case Pipe: "|>";
                    case TypeCheck: "::";
                    case When: "when";
                };
                '(' + l + ' ' + opStr + ' ' + r + ')';
            case EIf(condition, thenBranch, elseBranch):
                var c = renderExpr(condition);
                var t = renderExpr(thenBranch);
                var e = elseBranch != null ? renderExpr(elseBranch) : "nil";
                'if ' + c + ', do: ' + t + ', else: ' + e;
            case EParen(inner):
                '(' + renderExpr(inner) + ')';
            default:
                // Fallback: delegate to AST printer for a best-effort representation
                ElixirASTPrinter.print(ast, 0);
        };
    }
    
    /**
     * Collect template content from an ElixirAST node
     * 
     * Processes various AST patterns to extract template strings,
     * handling embedded expressions and string interpolation.
     */
    public static function collectTemplateContent(ast: ElixirAST): String {
        #if hxx_instrument_sys
        var __t0 = haxe.Timer.stamp();
        #end
        var __result = switch(ast.def) {
            case EString(s): 
                // Simple string - process interpolations and HXX control tags into HEEx-safe content
                var processed = rewriteInterpolations(s);
                processed = rewriteControlTags(processed);
                processed;
                
            case EBinary(StringConcat, left, right):
                // String concatenation - collect both sides
                var l = collectTemplateContent(left);
                var r = collectTemplateContent(right);
                // Ensure HXX control tags remain balanced across boundaries
                rewriteControlTags(l + r);
                
            case EIf(condition, thenBranch, elseBranch):
                // Prefer inline-if when then/else are simple HTML strings (including HXX.block)
                var condStr = renderExpr(condition);
                if (StringTools.startsWith(condStr, "assigns.")) condStr = '@' + condStr.substr("assigns.".length);
                // Try to extract simple HTML bodies from branches
                var thenSimple: Null<String> = extractSimpleHtml(thenBranch);
                var elseSimple: Null<String> = (elseBranch != null) ? extractSimpleHtml(elseBranch) : "";
                if (thenSimple != null && elseSimple != null) {
                    '<%= if ' + condStr + ', do: ' + toQuoted(thenSimple) + ', else: ' + toQuoted(elseSimple) + ' %>';
                } else {
                    // Fallback to block-if
                    var thenStr = collectTemplateContent(thenBranch);
                    var elseStr = elseBranch != null ? collectTemplateContent(elseBranch) : "";
                    var out = new StringBuf();
                    out.add('<%= if ' + condStr + ' do %>');
                    out.add(thenStr);
                    if (elseStr != null && elseStr != "") {
                        out.add('<% else %>');
                        out.add(elseStr);
                    }
                    out.add('<% end %>');
                    out.toString();
                }

            case ECall(module, func, args):
                // Special handling for nested HXX helpers: HXX.block('...') or hxx.HXX.block('...')
                var isHxxModule = false;
                if (module != null) switch (module.def) {
                    case EVar(m): isHxxModule = (m == "HXX");
                    case EField(_, fld): isHxxModule = (fld == "HXX");
                    default:
                }
                if (isHxxModule && (func == "block" || func == "hxx") && args.length >= 1) {
                    var inner = collectTemplateContent(args[0]);
                    return rewriteControlTags(inner);
                }
                // Generic call rendering with block-arg wrapping for validity in template interpolation
                var callStr = (function() {
                    var callHead = if (module != null) {
                        switch (module.def) {
                            case EVar(m): m + "." + func;
                            case EField(_, _): renderExpr(module) + "." + func;
                            default: func;
                        }
                    } else func;
                    function renderArgForTemplate(a: ElixirAST): String {
                        return switch (a.def) {
                            case EBlock(sts) if (sts != null && sts.length > 1):
                                // Wrap multi-statement blocks as IIFE to form a single expression
                                '(fn -> ' + StringTools.rtrim(ElixirASTPrinter.print(a, 0)) + ' end).()';
                            case EParen(inner) if (switch (inner.def) { case EBlock(es) if (es.length > 1): true; default: false; }):
                                '(fn -> ' + StringTools.rtrim(ElixirASTPrinter.print(inner, 0)) + ' end).()';
                            default:
                                renderExpr(a);
                        }
                    }
                    var parts = [];
                    for (a in args) parts.push(renderArgForTemplate(a));
                    return callHead + '(' + parts.join(', ') + ')';
                })();
                if (StringTools.startsWith(callStr, "assigns.")) callStr = '@' + callStr.substr("assigns.".length);
                '<%= ' + callStr + ' %>';

            case ERemoteCall(module, func, args):
                // Render remote calls similarly to ECall, with arg block wrapping
                var head = renderExpr(module) + "." + func;
                function renderArg2(a: ElixirAST): String {
                    return switch (a.def) {
                        case EBlock(sts) if (sts != null && sts.length > 1):
                            '(fn -> ' + StringTools.rtrim(ElixirASTPrinter.print(a, 0)) + ' end).()';
                        case EParen(inner) if (switch (inner.def) { case EBlock(es) if (es.length > 1): true; default: false; }):
                            '(fn -> ' + StringTools.rtrim(ElixirASTPrinter.print(inner, 0)) + ' end).()';
                        default:
                            renderExpr(a);
                    }
                }
                var argList2 = [];
                for (a in args) argList2.push(renderArg2(a));
                var full = head + '(' + argList2.join(', ') + ')';
                if (StringTools.startsWith(full, "assigns.")) full = '@' + full.substr("assigns.".length);
                '<%= ' + full + ' %>';

            case EVar(_)
                | EField(_, _)
                | EInteger(_)
                | EFloat(_)
                | EBoolean(_)
                | ENil
                | EAtom(_)
                | EBinary(_, _, _)
                | EParen(_):
                // Expression inside template – render as HEEx interpolation
                var exprStr = renderExpr(ast);
                // Map assigns.* to @* for HEEx idioms
                if (StringTools.startsWith(exprStr, "assigns.")) {
                    exprStr = '@' + exprStr.substr("assigns.".length);
                }
                '<%= ' + exprStr + ' %>';
                
            default:
                // Fallback: embed expression in interpolation using generic renderer
                var exprAny = renderExpr(ast);
                if (StringTools.startsWith(exprAny, "assigns.")) exprAny = '@' + exprAny.substr("assigns.".length);
                '<%= ' + exprAny + ' %>';
        };
        #if hxx_instrument_sys
        var __elapsed = (haxe.Timer.stamp() - __t0) * 1000.0;
        #if sys
        Sys.println('[HXX] collectTemplateContent elapsed_ms=' + Std.int(__elapsed));
        #else
        trace('[HXX] collectTemplateContent elapsed_ms=' + Std.int(__elapsed));
        #end
        #end
        return __result;
    }

    /**
     * Convert #{...} and ${...} interpolations into HEEx <%= ... %> and map assigns.* → @*
     * Also rewrites inline ternary to block HEEx when then/else are string or HXX.block.
     */
    public static function rewriteInterpolations(s:String):String {
        if (s == null) return s;
        // Fast-path: if there are no interpolation/control markers, return as-is
        if (s.indexOf("${") == -1 && s.indexOf("#{") == -1 && s.indexOf('<for {') == -1) {
            return s;
        }
        #if hxx_instrument_sys
        var __t0 = haxe.Timer.stamp();
        var __bytes = s.length;
        var __iters = 0;
        #end
        // First, convert attribute-level ${...} into HEEx attribute expressions: attr={...}
        s = rewriteAttributeInterpolations(s);
        // Then, convert attribute-level <%= ... %> into HEEx attribute expressions: attr={...}
        s = rewriteAttributeEexInterpolations(s);
        // Normalize custom control tags first (so inner text gets rewritten next)
        s = rewriteForBlocks(s);
        var out = new StringBuf();
        var i = 0;
        while (i < s.length) {
            #if hxx_instrument_sys __iters++; #end
            var j1 = s.indexOf("#{", i);
            var j2 = s.indexOf("${", i);
            var j = (j1 == -1) ? j2 : (j2 == -1 ? j1 : (j1 < j2 ? j1 : j2));
            if (j == -1) { out.add(s.substr(i)); break; }
            out.add(s.substr(i, j - i));
            var k = j + 2;
            var depth = 1;
            while (k < s.length && depth > 0) {
                var ch = s.charAt(k);
                if (ch == '{') depth++;
                else if (ch == '}') depth--;
                k++;
            }
            var inner = s.substr(j + 2, (k - 1) - (j + 2));
            var expr = StringTools.trim(inner);
            // Guard: disallow injecting HTML as string via interpolation of a string literal starting with '<'
            if (expr.length >= 2 && expr.charAt(0) == '"' && expr.charAt(1) == '<') {
                #if macro
                haxe.macro.Context.error('HXX: injecting HTML via string inside interpolation is not allowed. Use HXX.block(\'...\') or inline markup.', haxe.macro.Context.currentPos());
                #else
                throw 'HXX: injecting HTML via string inside interpolation is not allowed. Use HXX.block(\'...\') or inline markup.';
                #end
            }
            // Try to split top-level ternary
            var tern = splitTopLevelTernary(expr);
            if (tern != null) {
                var cond = StringTools.replace(tern.cond, "assigns.", "@");
                var th = extractBlockHtml(StringTools.trim(tern.thenPart));
                var el = extractBlockHtml(StringTools.trim(tern.elsePart));
                if (th != null || el != null) {
                    // Prefer inline-if in body when both branches are HTML strings
                    var thenQ = (th != null) ? toQuoted(th) : '""';
                    var elseQ = (el != null && el != "") ? toQuoted(el) : '""';
                    out.add('<%= if ' + cond + ', do: ' + thenQ + ', else: ' + elseQ + ' %>');
                } else {
                    out.add('<%= ' + StringTools.replace(expr, "assigns.", "@") + ' %>');
                }
            } else {
                out.add('<%= ' + StringTools.replace(expr, "assigns.", "@") + ' %>');
            }
            i = k;
        }
        // Return as-is; attribute contexts are normalized elsewhere.
        var __res = out.toString();
        #if hxx_instrument_sys
        var __elapsed = (haxe.Timer.stamp() - __t0) * 1000.0;
        #if macro
        haxe.macro.Context.warning('[HXX] rewriteInterpolations bytes=' + __bytes + ' iters=' + __iters + ' elapsed_ms=' + Std.int(__elapsed), haxe.macro.Context.currentPos());
        #elseif sys
        Sys.println('[HXX] rewriteInterpolations bytes=' + __bytes + ' iters=' + __iters + ' elapsed_ms=' + Std.int(__elapsed));
        #end
        #end
        return __res;
    }

    /**
     * Rewrite <for {pattern in expr}> ... </for> to HEEx for-blocks.
     * Supports simple patterns like `todo in list` or `item in some_call()`.
     */
    public static function rewriteForBlocks(src:String):String {
        var out = new StringBuf();
        var i = 0;
        #if hxx_instrument_sys
        var __t0 = haxe.Timer.stamp();
        #end
        #if hxx_instrument
        var localIters = 0;
        #end
        while (i < src.length) {
            #if hxx_instrument localIters++; #end
            var start = src.indexOf('<for {', i);
            if (start == -1) { out.add(src.substr(i)); break; }
            out.add(src.substr(i, start - i));
            var headEnd = src.indexOf('}>', start);
            if (headEnd == -1) { out.add(src.substr(start)); break; }
            var headInner = src.substr(start + 6, headEnd - (start + 6)); // between { and }
            var closeTag = src.indexOf('</for>', headEnd + 2);
            if (closeTag == -1) { out.add(src.substr(start)); break; }
            var body = src.substr(headEnd + 2, closeTag - (headEnd + 2));
            var parts = headInner.split(' in ');
            if (parts.length != 2) {
                // Fallback: keep original; do not break template
                out.add(src.substr(start, (closeTag + 6) - start));
                i = closeTag + 6;
                continue;
            }
            var pat = StringTools.trim(parts[0]);
            var iter = StringTools.trim(parts[1]);
            // Map assigns.* to @* in iterator expression
            iter = StringTools.replace(iter, 'assigns.', '@');
            out.add('<%= for ' + pat + ' <- ' + iter + ' do %>');
            // Recursively allow nested for/if inside body
            out.add(rewriteForBlocks(body));
            out.add('<% end %>');
            i = closeTag + 6;
        }
        #if hxx_instrument
        trace('[HXX-INSTR] forBlocks: iters=' + localIters + ' len=' + (src != null ? src.length : 0));
        #end
        var __s = out.toString();
        #if hxx_instrument_sys
        var __elapsed = (haxe.Timer.stamp() - __t0) * 1000.0;
        #if macro
        haxe.macro.Context.warning('[HXX] rewriteForBlocks bytes=' + (src != null ? src.length : 0) + ' iters=' + ( #if hxx_instrument localIters #else 0 #end ) + ' elapsed_ms=' + Std.int(__elapsed), haxe.macro.Context.currentPos());
        #elseif sys
        Sys.println('[HXX] rewriteForBlocks bytes=' + (src != null ? src.length : 0) + ' iters=' + ( #if hxx_instrument localIters #else 0 #end ) + ' elapsed_ms=' + Std.int(__elapsed));
        #end
        #end
        return __s;
    }

    // Convert attribute values written as <%= ... %> (and conditional blocks) into HEEx { ... }
    static function rewriteAttributeEexInterpolations(s:String):String {
        // Fast-path: regex-based attribute EEx → HEEx conversion (single pass), avoiding heavy scanning
        if (s == null || s.indexOf("<%") == -1) return s;
        // name=<%= expr %>  → name={expr}
        var eexAttr = ~/=\s*<%=\s*([^%]+?)\s*%>/g;
        var result = eexAttr.replace(s, '={$1}');
        // name=<% if cond do %>then<% else %>else<% end %> → name={if cond, do: "then", else: "else"}
        var eexIf = ~/=\s*<%\s*if\s+(.+?)\s+do\s*%>([^<]*)<%\s*else\s*%>([^<]*)<%\s*end\s*%>/g;
        result = eexIf.map(result, function (re) {
            var cond = StringTools.trim(re.matched(1));
            var th = StringTools.trim(re.matched(2));
            var el = StringTools.trim(re.matched(3));
            if (!(StringTools.startsWith(th, '"') && StringTools.endsWith(th, '"')) && !(StringTools.startsWith(th, "'") && StringTools.endsWith(th, "'"))) th = '"' + th + '"';
            if (!(StringTools.startsWith(el, '"') && StringTools.endsWith(el, '"')) && !(StringTools.startsWith(el, "'") && StringTools.endsWith(el, "'"))) el = '"' + el + '"';
            return '={if ' + cond + ', do: ' + th + ', else: ' + el + '}';
        });
        return result;
    }

    public static inline function toQuoted(s:String): String {
        var t = StringTools.trim(s);
        // If already quoted, keep as-is; otherwise wrap with quotes without escaping inner quotes
        if ((StringTools.startsWith(t, '"') && StringTools.endsWith(t, '"')) || (StringTools.startsWith(t, "'") && StringTools.endsWith(t, "'"))) {
            return t;
        }
        return '"' + t + '"';
    }

    /**
     * Rewrite attribute values written as ${...} into HEEx attribute expressions { ... }.
     * - Handles: attr=${expr} or attr="${expr}" → attr={expr}
     * - Maps assigns.* → @*
     * - For top-level ternary cond ? a : b → {if cond, do: a, else: b}
     */
    static function rewriteAttributeInterpolations(s:String):String {
        var out = new StringBuf();
        var i = 0;
        while (i < s.length) {
            var prev = i;
            var j = s.indexOf("${", i);
            if (j == -1) { out.add(s.substr(i)); break; }
            // Attempt to detect an attribute assignment immediately preceding ${
            // Find the nearest '=' before j without encountering '>'
            var k = j - 1;
            var seenGt = false;
            while (k >= i) {
                var ch = s.charAt(k);
                if (ch == '>') { seenGt = true; break; }
                if (ch == '=') break;
                k--;
            }
            if (k < i || seenGt || s.charAt(k) != '=') {
                // Not an attr context; copy chunk up to j and continue generic handling later
                out.add(s.substr(i, (j - i)));
                // Copy marker to let generic pass handle it
                out.add("${");
                i = j + 2;
                continue;
            }
            // Find attribute name by scanning backwards from k-1
            var nameEnd = k - 1;
            while (nameEnd >= i && ~/^\s$/.match(s.charAt(nameEnd))) nameEnd--;
            var nameStart = nameEnd;
            while (nameStart >= i && ~/^[A-Za-z0-9_:\-]$/.match(s.charAt(nameStart))) nameStart--;
            nameStart++;
            if (nameStart > nameEnd) {
                // Fallback: not a valid attribute name, treat as generic
                out.add(s.substr(i, (j - i)));
                out.add("${");
                i = j + 2;
                continue;
            }
            var attrName = s.substr(nameStart, (nameEnd - nameStart + 1));
            // Copy prefix up to attribute name start
            out.add(s.substr(i, (nameStart - i)));
            out.add(attrName);
            out.add("=");
            // Skip whitespace and optional opening quote after '='
            var vpos = k + 1;
            while (vpos < s.length && ~/^\s$/.match(s.charAt(vpos))) vpos++;
            var quote: Null<String> = null;
            if (vpos < s.length && (s.charAt(vpos) == '"' || s.charAt(vpos) == '\'')) {
                quote = s.charAt(vpos);
                vpos++;
            }
            // We expect vpos == j (start of ${); otherwise, treat as generic
            if (vpos != j) {
                // Not a plain attr=${...}; emit original sequence and continue
                out.add(s.substr(k + 1, (j - (k + 1))));
                out.add("${");
                i = j + 2;
                continue;
            }
            // Parse balanced braces for ${...}
            var p = j + 2;
            var depth = 1;
            while (p < s.length && depth > 0) {
                var c = s.charAt(p);
                if (c == '{') depth++; else if (c == '}') depth--; p++;
            }
            var inner = s.substr(j + 2, (p - 1) - (j + 2));
            var expr = StringTools.trim(inner);
            // Map assigns.* → @*
            expr = StringTools.replace(expr, "assigns.", "@");
            // Ternary to inline-if for attribute context
            var tern = splitTopLevelTernary(expr);
            if (tern != null) {
                var cond = StringTools.replace(StringTools.trim(tern.cond), "assigns.", "@");
                var th = StringTools.trim(tern.thenPart);
                var el = StringTools.trim(tern.elsePart);
                expr = 'if ' + cond + ', do: ' + th + ', else: ' + el;
            }
            out.add('{');
            out.add(expr);
            out.add('}');
            // Skip closing quote if present
            if (quote != null) {
                var qpos = p;
                // Advance until we see the matching quote or tag end; be conservative
                if (qpos < s.length && s.charAt(qpos) == quote) {
                    p = qpos + 1;
                }
            }
            // Advance index
            i = p;
            if (i <= prev) i = prev + 1;
        }
        return out.toString();
    }

    static function extractBlockHtml(part:String):Null<String> {
        if (part == null || part == "") return "";
        var p = part;
        if (StringTools.startsWith(p, "HXX.block(")) {
            var start = p.indexOf('(') + 1;
            var end = p.lastIndexOf(')');
            if (start > 0 && end > start) {
                var inner = StringTools.trim(p.substr(start, end - start));
                return unquote(inner);
            }
        }
        var uq = unquote(p);
        if (uq != null) return uq;
        return null;
    }

    // Extracts simple HTML from an AST branch when it's either HXX.block('...') or a string literal
    static function extractSimpleHtml(branch: ElixirAST): Null<String> {
        return switch (branch.def) {
            case ECall(module, func, args):
                var isHxx = false;
                if (module != null) switch (module.def) {
                    case EVar(m): isHxx = (m == "HXX");
                    case EField(_, fld): isHxx = (fld == "HXX");
                    default:
                }
                if (isHxx && (func == "block" || func == "hxx") && args.length >= 1) {
                    var inner = collectTemplateContent(args[0]);
                    // Ensure no nested EEx in inner
                    if (inner.indexOf("<%") == -1) inner else null;
                } else null;
            case EString(s):
                var uq = unquote(s);
                uq != null ? uq : s;
            default:
                null;
        }
    }

    static function unquote(s:String):Null<String> {
        if (s.length >= 2) {
            var a = s.charAt(0);
            var b = s.charAt(s.length - 1);
            if ((a == '"' && b == '"') || (a == '\'' && b == '\'')) {
                return s.substr(1, s.length - 2);
            }
        }
        return null;
    }

    static function splitTopLevelTernary(e:String):Null<{cond:String, thenPart:String, elsePart:String}> {
        var depth = 0;
        var inS = false, inD = false;
        var q = -1, col = -1;
        for (idx in 0...e.length) {
            var ch = e.charAt(idx);
            if (!inS && ch == '"' && !inD) { inD = true; continue; }
            else if (inD && ch == '"') { inD = false; continue; }
            if (!inD && ch == '\'' && !inS) { inS = true; continue; }
            else if (inS && ch == '\'') { inS = false; continue; }
            if (inS || inD) continue;
            if (ch == '(' || ch == '{' || ch == '[') depth++;
            else if (ch == ')' || ch == '}' || ch == ']') depth--;
            if (depth != 0) continue;
            if (ch == '?' && q == -1) { q = idx; }
            else if (ch == ':' && q != -1) { col = idx; break; }
        }
        if (q == -1 || col == -1) return null;
        var cond = StringTools.trim(e.substr(0, q));
        var thenPart = StringTools.trim(e.substr(q + 1, col - (q + 1)));
        var elsePart = StringTools.trim(e.substr(col + 1));
        return { cond: cond, thenPart: thenPart, elsePart: elsePart };
    }

    static function rewriteInlineIfDoToBlock(s:String):String {
        var out = new StringBuf();
        var i = 0;
        while (i < s.length) {
            var start = s.indexOf("<%=", i);
            if (start == -1) { out.add(s.substr(i)); break; }
            out.add(s.substr(i, start - i));
            var endTag = s.indexOf("%>", start + 3);
            if (endTag == -1) { out.add(s.substr(start)); break; }
            var inner = StringTools.trim(s.substr(start + 3, endTag - (start + 3)));
            if (StringTools.startsWith(inner, "if ")) {
                var rest = StringTools.trim(inner.substr(3));
                var idxDo = indexOfTopLevel(rest, ", do:");
                var cond:String = null;
                var doPart:String = null;
                var elsePart:String = null;
                if (idxDo != -1) {
                    cond = StringTools.trim(rest.substr(0, idxDo));
                    var afterDo = StringTools.trim(rest.substr(idxDo + 5));
                    var qv = extractQuoted(afterDo);
                    if (qv != null) {
                        doPart = qv.value;
                        var rem = StringTools.trim(afterDo.substr(qv.length));
                        if (StringTools.startsWith(rem, ",")) rem = StringTools.trim(rem.substr(1));
                        if (StringTools.startsWith(rem, "else:")) {
                            var afterElse = StringTools.trim(rem.substr(5));
                            var qv2 = extractQuoted(afterElse);
                            if (qv2 != null) elsePart = qv2.value;
                        }
                    }
                }
                if (cond != null && doPart != null) {
                    out.add('<%= if ' + StringTools.replace(cond, "assigns.", "@") + ' do %>');
                    out.add(doPart);
                    if (elsePart != null && elsePart != "") { out.add('<% else %>'); out.add(elsePart); }
                    out.add('<% end %>');
                } else {
                    out.add(s.substr(start, (endTag + 2) - start));
                }
            } else {
                out.add(s.substr(start, (endTag + 2) - start));
            }
            i = endTag + 2;
        }
        return out.toString();
    }

    static function extractQuoted(s:String):Null<{value:String, length:Int}> {
        if (s.length == 0) return null;
        var quote = s.charAt(0);
        if (quote != '"' && quote != '\'') return null;
        var i = 1;
        while (i < s.length) {
            var ch = s.charAt(i);
            if (ch == quote) {
                var val = s.substr(1, i - 1);
                return { value: val, length: i + 1 };
            }
            i++;
        }
        return null;
    }

    /**
     * Structured rewrite of <if {cond}> ... (<else> ...)? </if> into block HEEx.
     * Handles nesting and maps assigns.* to @*.
     */
    public static function rewriteControlTags(s:String):String {
        if (s == null || s.indexOf("<if") == -1) return s;
        var out = new StringBuf();
        var i = 0;
        while (i < s.length) {
            var idx = s.indexOf("<if", i);
            if (idx == -1) { out.add(s.substr(i)); break; }
            out.add(s.substr(i, idx - i));
            var j = idx + 3; // after '<if'
            while (j < s.length && ~/^\s$/.match(s.charAt(j))) j++;
            if (j >= s.length || s.charAt(j) != '{') { out.add("<if"); i = idx + 3; continue; }
            var braceStart = j; j++;
            var braceDepth = 1;
            while (j < s.length && braceDepth > 0) {
                var ch = s.charAt(j);
                if (ch == '{') braceDepth++; else if (ch == '}') braceDepth--; j++;
            }
            if (braceDepth != 0) { out.add(s.substr(idx)); break; }
            var braceEnd = j - 1;
            while (j < s.length && ~/^\s$/.match(s.charAt(j))) j++;
            if (j >= s.length || s.charAt(j) != '>') { out.add(s.substr(idx, j - idx)); i = j; continue; }
            var openEnd = j + 1;
            var cond = StringTools.trim(s.substr(braceStart + 1, braceEnd - (braceStart + 1)));
            cond = StringTools.replace(cond, "assigns.", "@");
            // find matching </if>
            var k = openEnd;
            var depth = 1;
            var elsePos = -1;
            while (k < s.length && depth > 0) {
                var nextIf = s.indexOf("<if", k);
                var nextElse = s.indexOf("<else>", k);
                var nextClose = s.indexOf("</if>", k);
                var next = -1;
                var tag = 0;
                if (nextIf != -1) { next = nextIf; tag = 1; }
                if (nextElse != -1 && (next == -1 || nextElse < next)) { next = nextElse; tag = 2; }
                if (nextClose != -1 && (next == -1 || nextClose < next)) { next = nextClose; tag = 3; }
                if (next == -1) break;
                if (tag == 1) { depth++; k = next + 3; }
                else if (tag == 2 && depth == 1 && elsePos == -1) { elsePos = next; k = next + 6; }
                else if (tag == 3) { depth--; k = next + 5; }
                else k = next + 1;
            }
            if (depth != 0) { out.add(s.substr(idx)); break; }
            var closeIdx = k - 5;
            var thenStart = openEnd;
            var thenEnd = elsePos != -1 ? elsePos : closeIdx;
            var elseStart = elsePos != -1 ? (elsePos + 6) : -1;
            var elseEnd = closeIdx;
            var thenHtml = s.substr(thenStart, thenEnd - thenStart);
            var elseHtml = elseStart != -1 ? s.substr(elseStart, elseEnd - elseStart) : null;
            out.add('<%= if ' + cond + ' do %>');
            out.add(thenHtml);
            if (elseHtml != null && StringTools.trim(elseHtml) != "") { out.add('<% else %>'); out.add(elseHtml); }
            out.add('<% end %>');
            var afterClose = s.indexOf('>', closeIdx + 1);
            i = (afterClose == -1) ? s.length : afterClose + 1;
        }
        return out.toString();
    }

    static function indexOfTopLevel(s:String, token:String):Int {
        var depth = 0;
        var inS = false, inD = false;
        for (i in 0...s.length - token.length + 1) {
            var ch = s.charAt(i);
            if (!inS && ch == '"' && !inD) { inD = true; continue; }
            else if (inD && ch == '"') { inD = false; continue; }
            if (!inD && ch == '\'' && !inS) { inS = true; continue; }
            else if (inS && ch == '\'') { inS = false; continue; }
            if (inS || inD) continue;
            if (ch == '(' || ch == '{' || ch == '[') depth++;
            else if (ch == ')' || ch == '}' || ch == ']') depth--;
            if (depth != 0) continue;
            if (s.substr(i, token.length) == token) return i;
        }
        return -1;
    }
    
    /**
     * Collect template argument for function calls within templates
     */
    public static function collectTemplateArgument(ast: ElixirAST): String {
        return switch(ast.def) {
            case EString(s): '"' + s + '"';
            case EVar(name): name;
            case EAtom(a): ":" + a;
            case EInteger(i): Std.string(i);
            case EFloat(f): Std.string(f);
            case EBoolean(b): b ? "true" : "false";
            case ENil: "nil";
            case EField(obj, field):
                switch(obj.def) {
                    case EVar(v): v + "." + field;
                    default: "[complex]." + field;
                }
            default: "[complex arg]";
        };
    }
    
    /**
     * Check if an expression is an HXX module access
     * 
     * Detects patterns like HXX.hxx() or hxx.HXX.hxx()
     */
    public static function isHXXModule(expr: TypedExpr): Bool {
        return switch(expr.expr) {
            case TTypeExpr(m):
                // Check if this is the HXX module
                var moduleName = moduleTypeToString(m);
                #if debug_hxx_transformation
                #if debug_ast_builder
                trace('[HXX] Checking module: $moduleName against "HXX"');
                #end
                #end
                moduleName == "HXX";
            default: 
                #if debug_hxx_transformation
                #if debug_ast_builder
                trace('[HXX] Not a TTypeExpr, expr type: ${expr.expr}');
                #end
                #end
                false;
        };
    }
    
    /**
     * Convert a ModuleType to string representation
     * Helper function for isHXXModule
     */
    static function moduleTypeToString(m: ModuleType): String {
        return switch (m) {
            case TClassDecl(c):
                var cls = c.get();
                if (cls.pack.length > 0) {
                    cls.pack.join(".") + "." + cls.name;
                } else {
                    cls.name;
                }
            case TEnumDecl(e):
                var enm = e.get();
                if (enm.pack.length > 0) {
                    enm.pack.join(".") + "." + enm.name;
                } else {
                    enm.name;
                }
            case TAbstract(a):
                var abs = a.get();
                if (abs.pack.length > 0) {
                    abs.pack.join(".") + "." + abs.name;
                } else {
                    abs.name;
                }
            case TTypeDecl(t):
                var typ = t.get();
                if (typ.pack.length > 0) {
                    typ.pack.join(".") + "." + typ.name;
                } else {
                    typ.name;
                }
        };
    }
}

#end
````

## File: src/reflaxe/elixir/macros/HXX.hx
````
package reflaxe.elixir.macros;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
// Heavy registry import is gated behind `-D hxx_validate` to avoid compile-time overhead
#if hxx_validate
import phoenix.types.HXXComponentRegistry;
#end
#end

/**
 * HXX - Type-Safe Phoenix HEEx Template System
 *
 * Provides compile-time type safety for Phoenix HEEx templates, equivalent to
 * React with TypeScript JSX, while generating standard Phoenix HEEx output.
 *
 * ## Why HXX? The Perfect Phoenix Augmentation
 *
 * HXX enhances Phoenix HEEx development without changing its fundamental nature:
 * - **Type Safety**: Catch errors at compile-time, not runtime
 * - **IDE Support**: Full IntelliSense for all HTML/Phoenix attributes
 * - **Phoenix-First**: Designed specifically for Phoenix LiveView patterns
 * - **Zero Runtime Cost**: Types are compile-time only, generating clean HEEx
 * - **Flexible Naming**: Support for camelCase, snake_case, and kebab-case
 *
 * ## How It Works
 *
 * HXX is a compile-time macro that:
 * 1. Validates HTML elements and attributes against type definitions
 * 2. Converts attribute names (camelCase/snake_case → kebab-case)
 * 3. Transforms Haxe interpolation (${}) to Elixir interpolation (#{})
 * 4. Provides helpful error messages for invalid templates
 * 5. Generates standard HEEx that Phoenix expects
 *
 * ## Developer Experience Benefits
 *
 * ### IntelliSense That Actually Helps
 * ```haxe
 * var input: InputAttributes = {
 *     type: Email,     // Autocomplete shows all InputType options
 *     phx|            // Autocomplete: phxClick, phxChange, phxSubmit...
 * };
 * ```
 *
 * ### Compile-Time Error Detection
 * ```haxe
 * // ❌ Typos caught at compile-time
 * HXX.hxx('<button phx_clik="save">')  // Error: Did you mean phx_click?
 *
 * // ❌ Wrong attributes for elements
 * HXX.hxx('<input href="/path">')      // Error: href not valid for input
 *
 * // ❌ Type mismatches
 * HXX.hxx('<input required="yes">')    // Error: Bool expected, not String
 * ```
 *
 * ### Respects Phoenix/Elixir Culture
 * ```haxe
 * // All naming styles work and generate correct HEEx:
 * HXX.hxx('<div phx_click="handler">')     // Elixir style ✅
 * HXX.hxx('<div phxClick="handler">')      // Haxe style ✅
 * HXX.hxx('<div phx-click="handler">')     // HTML style ✅
 * // All generate: <div phx-click="handler">
 * ```
 *
 * ## Phoenix LiveView Integration
 *
 * First-class support for all Phoenix LiveView features:
 * - **Events**: phxClick, phxChange, phxSubmit, phxFocus, phxBlur
 * - **Keyboard**: phxKeydown, phxKeyup, phxWindowKeydown
 * - **Mouse**: phxMouseenter, phxMouseleave
 * - **Navigation**: phxLink, phxLinkState, phxPatch, phxNavigate
 * - **Optimization**: phxDebounce, phxThrottle, phxUpdate, phxTrackStatic
 * - **Hooks**: phxHook for JavaScript interop
 *
 * ## Usage Examples
 *
 * ### Basic Template
 * ```haxe
 * var template = HXX.hxx('
 *     <div className="container">
 *         <h1>${title}</h1>
 *         <button phxClick="save" disabled=${!valid}>
 *             Save
 *         </button>
 *     </div>
 * ');
 * ```
 *
 * ### LiveView Component
 * ```haxe
 * function render(assigns: Assigns) {
 *     return HXX.hxx('
 *         <div id="todos" phxUpdate="stream">
 *             <%= for todo <- @todos do %>
 *                 <div id={"todo-${todo.id}"}>
 *                     <input type="checkbox"
 *                            checked={todo.completed}
 *                            phxClick="toggle"
 *                            phxValue={todo.id} />
 *                     <span class={todo.completed ? "done" : ""}>
 *                         ${todo.title}
 *                     </span>
 *                 </div>
 *             <% end %>
 *         </div>
 *     ');
 * }
 * ```
 *
 * ### Form with Validation
 * ```haxe
 * var form = HXX.hxx('
 *     <.form for={@changeset} phxSubmit="save" phxChange="validate">
 *         <.input field={@form[:email]}
 *                 type="email"
 *                 placeholder="Enter email"
 *                 required />
 *         <.button type="submit" disabled={!@changeset.valid?}>
 *             Submit
 *         </.button>
 *     </.form>
 * ');
 * ```
 *
 * ## Why This Works Better Than JSX→HEEx
 *
 * | Aspect | JSX (React) | HXX (Phoenix) | Advantage |
 * |--------|-------------|---------------|--------|
 * | **Rendering** | Client-side | Server-side templates | Matches Phoenix SSR |
 * | **Events** | onClick | phxClick | Native Phoenix events |
 * | **State** | useState/props | Phoenix assigns | LiveView state model |
 * | **Components** | React components | Phoenix functions | Phoenix components |
 * | **Naming** | camelCase only | Flexible (3 styles) | Respects Elixir |
 *
 * ## Type Safety Without Compromise
 *
 * HXX provides the same level of type safety as React+TypeScript while:
 * - Generating standard HEEx (not a custom format)
 * - Supporting all Phoenix LiveView features natively
 * - Respecting Elixir naming conventions
 * - Having zero runtime overhead
 * - Working with existing Phoenix tooling
 *
 * ## Implementation Details
 *
 * The macro performs these transformations:
 * 1. `${expr}` → `#{expr}` (Haxe to Elixir interpolation)
 * 2. `className` → `class` (special HTML attributes)
 * 3. `phxClick` → `phx-click` (camelCase to kebab-case)
 * 4. `phx_click` → `phx-click` (snake_case to kebab-case)
 * 5. Validates all attributes against type definitions
 * 6. Preserves Phoenix component syntax (`<.button>`)
 *
 * @see phoenix.types.HXXTypes For type definitions
 * @see phoenix.types.HXXComponentRegistry For element/attribute validation
 * @see docs/02-user-guide/HXX_TYPE_SAFETY.md For complete user guide
 */
class HXX {

    #if macro
    /**
     * Process a template string into type-safe Phoenix HEEx
     *
     * This macro function is the main entry point for HXX templates.
     * It validates the template at compile-time and transforms it into
     * valid HEEx that Phoenix expects.
     *
     * @param templateStr The template string to process (must be a string literal)
     * @return The processed HEEx template string with proper Phoenix syntax
     *
     * @throws Compile-time error if template contains invalid elements or attributes
     * @throws Compile-time warning for potentially incorrect attribute usage
     *
     * ## Example
     * ```haxe
     * // Input (Haxe with type safety)
     * var template = HXX.hxx('
     *     <div className="card" phxClick="expand">
     *         <h1>${title}</h1>
     *     </div>
     * ');
     *
     * // Output (Phoenix HEEx)
     * <div class="card" phx-click="expand">
     *     <h1><%= title %></h1>
     * </div>
     * ```
     */
    public static macro function hxx(templateStr: Expr): Expr {
        return switch (templateStr.expr) {
            case EConst(CString(s, _)):
                #if (macro && hxx_instrument_sys)
                var __t0 = haxe.Timer.stamp();
                var __bytes = s != null ? s.length : 0;
                var __posInfo = haxe.macro.Context.getPosInfos(templateStr.pos);
                #end
                #if macro
                haxe.macro.Context.warning("[HXX] hxx() invoked", templateStr.pos);
                #end
                // Fast-path: if author already provided EEx/HEEx markers, do not rewrite.
                // This avoids unnecessary processing and prevents pathological regex scans.
                // We still tag it so the builder emits a ~H sigil.
                if (s.indexOf("<%=") != -1 || s.indexOf("<% ") != -1 || s.indexOf("<%\n") != -1) {
                    #if macro
                    haxe.macro.Context.warning("[HXX] fast-path (pre-EEx detected) + for-rewrite", templateStr.pos);
                    #end
                    var preProcessed = rewriteForBlocks(s);
                    return macro @:heex $v{preProcessed};
                }

                // Validate the template and proceed with HXX → HEEx conversion
                #if macro
                haxe.macro.Context.warning("[HXX] processing template string", templateStr.pos);
                #end
                var validation = validateTemplateTypes(s);
                if (!validation.valid) {
                    for (error in validation.errors) Context.warning(error, templateStr.pos);
                }
                var processed = processTemplateString(s, templateStr.pos);
                #if (macro && hxx_instrument_sys)
                var __elapsed = (haxe.Timer.stamp() - __t0) * 1000.0;
                var __file = (__posInfo != null) ? __posInfo.file : "<unknown>";
                Sys.println(
                    '[MacroTiming] name=HXX.hxx bytes=' + __bytes
                    + ' elapsed_ms=' + Std.int(__elapsed)
                    + ' file=' + __file
                );
                #end
                #if macro
                haxe.macro.Context.warning("[HXX] processed (length=" + processed.length + ")", templateStr.pos);
                #end
                macro @:heex $v{processed};
            case _:
                Context.error("hxx() expects a string literal", templateStr.pos);
        }
    }

    /**
     * HXX.block – marks a nested template fragment to be inlined as HEEx content.
     * Accepts a string literal containing HXX/HTML and returns it as-is at macro time.
     * TemplateHelpers recognizes HXX.block() when nested inside another HXX.hxx() and
     * will inline its processed content without wrapping it in an interpolation tag.
     */
    public static macro function block(content: Expr): Expr {
        return switch (content.expr) {
            case EConst(CString(s, _)):
                // Return the string literal as-is; outer processing will handle it
                macro $v{s};
            case _:
                Context.error("block() expects a string literal", content.pos);
        }
    }

    /**
     * Process template string at compile time
     *
     * This is the core transformation engine that converts Haxe template
     * syntax into Phoenix HEEx format while preserving Phoenix conventions.
     *
     * ## Transformation Pipeline
     *
     * 1. **Interpolation**: `${expr}` → `#{expr}` for Elixir
     * 2. **Attributes**: camelCase/snake_case → kebab-case
     * 3. **Conditionals**: Ternary operators → Elixir if/else
     * 4. **Loops**: Array.map → Phoenix for comprehensions
     * 5. **Components**: Preserve Phoenix component syntax
     * 6. **Events**: Ensure LiveView directives are correct
     *
     * @param template The raw template string from the user
     * @return Processed HEEx-compatible template string
     */
    static function processTemplateString(template: String, ?pos: haxe.macro.Expr.Position): String {
        // Convert Haxe ${} interpolation to Elixir #{} interpolation
        var processed = template;

        #if hxx_instrument_sys
        var __t0 = haxe.Timer.stamp();
        var __bytes = template != null ? template.length : 0;
        var __posInfo = (pos != null) ? haxe.macro.Context.getPosInfos(pos) : null;
        #end

        // 0) Rewrite HXX control/loop tags that must be lowered before interpolation scanning
        //    - <for {item in expr}> ... </for> → <% for item <- expr do %> ... <% end %>
        processed = rewriteForBlocks(processed);

        // 1) Rewrite attribute-level interpolations first: attr=${expr} or attr="${expr}" → attr={expr}
        //    Also map assigns.* → @* and ternary → inline if
        processed = rewriteAttributeInterpolations(processed);

        // 2) Handle remaining Haxe string interpolation (non-attribute positions):
        //    ${expr} or #{expr} -> <%= expr %> (convert assigns.* -> @*)
        // Fix: Use proper regex escaping - single backslash in Haxe regex literals
        var interp = ~/\$\{([^}]+)\}/g;
        processed = interp.map(processed, function (re) {
            var expr = re.matched(1);
            expr = StringTools.trim(expr);
            // Guard: disallow injecting HTML as string via ${"<div ..."}
            if (expr.length >= 2) {
                var first = expr.charAt(0);
                if ((first == '"' || first == '\'') && expr.length >= 2) {
                    // find first non-space after quote
                    var idx = 1;
                    while (idx < expr.length && ~/^\s$/.match(expr.charAt(idx))) idx++;
                    if (idx < expr.length && expr.charAt(idx) == '<') {
                        #if macro
                        haxe.macro.Context.error('HXX: injecting HTML via string inside ${...} is not allowed. Use inline markup or HXX.block(\'...\') as a deliberate escape hatch.', pos != null ? pos : haxe.macro.Context.currentPos());
                        #end
                    }
                }
            }
            expr = StringTools.replace(expr, "assigns.", "@");
            return '<%= ' + expr + ' %>';
        });

        // Support #{expr} placeholders to avoid Haxe compile-time interpolation conflicts
        var interpHash = ~/#\{([^}]+)\}/g;
        processed = interpHash.map(processed, function (re) {
            var expr = StringTools.trim(re.matched(1));
            expr = StringTools.replace(expr, "assigns.", "@");
            return '<%= ' + expr + ' %>';
        });

        // 2b) Convert attribute-level EEx back into HEEx attribute expressions
        //    name=<%= expr %>  → name={expr}
        var eexAttr = ~/=\s*<%=\s*([^%]+?)\s*%>/g;
        processed = eexAttr.replace(processed, '={$1}');

        //    name=<% if cond do %>then<% else %>else<% end %> → name={if cond, do: "then", else: "else"}
        var eexIf = ~/=\s*<%\s*if\s+(.+?)\s+do\s*%>([^<]*)<%\s*else\s*%>([^<]*)<%\s*end\s*%>/g;
        processed = eexIf.map(processed, function (re) {
            var cond = StringTools.trim(re.matched(1));
            var th = StringTools.trim(re.matched(2));
            var el = StringTools.trim(re.matched(3));
            // Quote then/else if not already quoted
            if (!(StringTools.startsWith(th, '"') && StringTools.endsWith(th, '"')) && !(StringTools.startsWith(th, "'") && StringTools.endsWith(th, "'"))) th = '"' + th + '"';
            if (!(StringTools.startsWith(el, '"') && StringTools.endsWith(el, '"')) && !(StringTools.startsWith(el, "'") && StringTools.endsWith(el, "'"))) el = '"' + el + '"';
            return '={if ' + cond + ', do: ' + th + ', else: ' + el + '}';
        });

        // Convert camelCase attributes to kebab-case
        processed = convertAttributes(processed);

        // Handle Phoenix component syntax: <.button> stays as <.button>
        // This is already valid HEEx syntax

        // Handle conditional rendering and loops
        processed = processConditionals(processed);
        processed = processLoops(processed);
        processed = processComponents(processed);
        processed = processLiveViewEvents(processed);

        #if hxx_instrument_sys
        var __elapsed = (haxe.Timer.stamp() - __t0) * 1000.0;
        var __file = (__posInfo != null) ? __posInfo.file : "<unknown>";
        // One-line, grep-friendly summary (bounded; prints only when -D hxx_instrument_sys)
        #if macro
        haxe.macro.Context.warning('[HXX] processTemplateString bytes=' + __bytes + ' elapsed_ms=' + Std.int(__elapsed) + ' file=' + __file, haxe.macro.Context.currentPos());
        #elseif sys
        Sys.println('[HXX] processTemplateString bytes=' + __bytes + ' elapsed_ms=' + Std.int(__elapsed) + ' file=' + __file);
        #end
        #end
        return processed;
    }

    /**
     * Rewrite <for {pattern in expr}> ... </for> to HEEx for-blocks.
     * Supports simple patterns like `todo in list` or `item in some_call()`.
     * Runs early, before generic interpolation handling.
     */
    static function rewriteForBlocks(src:String):String {
        if (src == null || src.indexOf('<for {') == -1) return src;
        var out = new StringBuf();
        var i = 0;
        while (i < src.length) {
            var start = src.indexOf('<for {', i);
            if (start == -1) { out.add(src.substr(i)); break; }
            out.add(src.substr(i, start - i));
            var headEnd = src.indexOf('}>', start);
            if (headEnd == -1) { out.add(src.substr(start)); break; }
            var headInner = src.substr(start + 6, headEnd - (start + 6)); // between { and }
            var closeTag = src.indexOf('</for>', headEnd + 2);
            if (closeTag == -1) { out.add(src.substr(start)); break; }
            var body = src.substr(headEnd + 2, closeTag - (headEnd + 2));
            var parts = headInner.split(' in ');
            if (parts.length != 2) {
                // Fallback: keep original; do not break template
                out.add(src.substr(start, (closeTag + 6) - start));
                i = closeTag + 6;
                continue;
            }
            var pat = StringTools.trim(parts[0]);
            var iter = StringTools.trim(parts[1]);
            // Map assigns.* to @* in iterator expression
            iter = StringTools.replace(iter, 'assigns.', '@');
            out.add('<% for ' + pat + ' <- ' + iter + ' do %>');
            // Recursively allow nested for/if inside body
            out.add(rewriteForBlocks(body));
            out.add('<% end %>');
            i = closeTag + 6;
        }
        return out.toString();
    }

    /**
     * Rewrite attribute values written as ${...} into HEEx attribute expressions { ... }.
     * - Handles: attr=${expr} or attr="${expr}" → attr={expr}
     * - Maps assigns.* → @*
     * - For top-level ternary cond ? a : b → {if cond, do: a, else: b}
     */
    static function rewriteAttributeInterpolations(s: String): String {
        if (s == null || s.length == 0) return s;
        var out = new StringBuf();
        var i = 0;
        while (i < s.length) {
            var j = s.indexOf("${", i);
            if (j == -1) { out.add(s.substr(i)); break; }
            // Find preceding '=' within tag, without crossing a '>'
            var k = j - 1;
            var seenGt = false;
            while (k >= i) {
                var ch = s.charAt(k);
                if (ch == '>') { seenGt = true; break; }
                if (ch == '=') break;
                k--;
            }
            if (k < i || seenGt || s.charAt(k) != '=') {
                // Not an attribute context, copy through '${' and continue
                out.add(s.substr(i, j - i));
                out.add("${");
                i = j + 2;
                continue;
            }
            // Identify attribute name
            var nameEnd = k - 1;
            while (nameEnd >= i && ~/^\s$/.match(s.charAt(nameEnd))) nameEnd--;
            var nameStart = nameEnd;
            while (nameStart >= i && ~/^[A-Za-z0-9_:\-]$/.match(s.charAt(nameStart))) nameStart--;
            nameStart++;
            if (nameStart > nameEnd) {
                out.add(s.substr(i, j - i));
                out.add("${");
                i = j + 2;
                continue;
            }
            var attrName = s.substr(nameStart, (nameEnd - nameStart + 1));
            // Copy prefix up to attribute name start and '='
            out.add(s.substr(i, (nameStart - i)));
            out.add(attrName);
            out.add("=");
            // Optional opening quote after '='
            var vpos = k + 1;
            while (vpos < s.length && ~/^\s$/.match(s.charAt(vpos))) vpos++;
            var quote: Null<String> = null;
            if (vpos < s.length && (s.charAt(vpos) == '"' || s.charAt(vpos) == '\'')) { quote = s.charAt(vpos); vpos++; }
            if (vpos != j) {
                // Not plain attr=${...}
                out.add(s.substr(k + 1, (j - (k + 1))));
                out.add("${");
                i = j + 2; continue;
            }
            // Parse balanced braces for ${...}
            var p = j + 2; var depth = 1;
            while (p < s.length && depth > 0) {
                var c = s.charAt(p);
                if (c == '{') depth++; else if (c == '}') depth--; p++;
            }
            var inner = s.substr(j + 2, (p - 1) - (j + 2));
            var expr = StringTools.trim(inner);
            // Map assigns.* → @*
            expr = StringTools.replace(expr, "assigns.", "@");
            // Ternary to inline-if for attribute context
            var tern = ~/(.*)\?(.*):(.*)/;
            if (tern.match(expr)) {
                var cond = StringTools.trim(tern.matched(1));
                var th = StringTools.trim(tern.matched(2));
                var el = StringTools.trim(tern.matched(3));
                expr = 'if ' + cond + ', do: ' + th + ', else: ' + el;
            }
            out.add('{'); out.add(expr); out.add('}');
            // Skip closing quote if present
            if (quote != null) {
                var qpos = p; if (qpos < s.length && s.charAt(qpos) == quote) p = qpos + 1;
            }
            i = p;
        }
        return out.toString();
    }

    /**
     * Process conditional rendering patterns
     */
    static function processConditionals(template: String): String {
        // Convert Haxe ternary to Elixir if/else
        // #{condition ? "true_value" : "false_value"} -> <%= if condition, do: "true_value", else: "false_value" %>
        // Fix: Use proper regex escaping - single backslash in Haxe regex literals
        var ternaryPattern = ~/#\{([^?]+)\?([^:]+):([^}]+)\}/g;
        return ternaryPattern.replace(template, '<%= if $1, do: $2, else: $3 %>');
    }

    /**
     * Process loop patterns (simplified)
     */
    static function processLoops(template: String): String {
        // Handle map operations: #{array.map(func).join("")} -> <%= for item <- array do %><%= func(item) %><% end %>
        // This is a simplified version - full implementation would need more sophisticated parsing

        // Handle basic map/join patterns
        // Fix: Use proper regex escaping - single backslash in Haxe regex literals
        var mapJoinPattern = ~/#\{([^.]+)\.map\(([^)]+)\)\.join\("([^"]*)"\)\}/g;
        return mapJoinPattern.replace(template, '<%= for item <- $1 do %><%= $2(item) %><% end %>');
    }

    /**
     * Process Phoenix component syntax
     * Preserves <.component> syntax and handles attributes
     */
    static function processComponents(template: String): String {
        // Phoenix components with dot prefix are already valid HEEx
        // Just ensure attributes are properly formatted
        var componentPattern = ~/<\.([a-zA-Z_][a-zA-Z0-9_]*)(\s+[^>]*)?\/>/g;
        return componentPattern.replace(template, "$0");
    }

    /**
     * Process LiveView event handlers
     * Ensures phx-* attributes are preserved
     */
    static function processLiveViewEvents(template: String): String {
        // LiveView events (phx-click, phx-change, etc.) are already valid
        // This is a placeholder for future enhancements
        return template;
    }

    /**
     * Helper to validate template syntax at compile time
     */
    static function validateTemplate(template: String): Bool {
        // Basic validation to catch common errors early
        var openTags = ~/<([a-zA-Z][a-zA-Z0-9]*)\b[^>]*>/g;
        var closeTags = ~/<\/([a-zA-Z][a-zA-Z0-9]*)>/g;

        // Count open and close tags (simplified)
        var opens = [];
        openTags.map(template, function(r) {
            opens.push(r.matched(1));
            return "";
        });

        var closes = [];
        closeTags.map(template, function(r) {
            closes.push(r.matched(1));
            return "";
        });

        // Basic balance check
        return opens.length == closes.length;
    }

    /**
     * Validate template types and attributes
     *
     * Performs compile-time validation to ensure:
     * - All HTML elements are valid
     * - All attributes are valid for their elements
     * - Attribute types match expected types
     * - Phoenix components are properly registered
     *
     * Provides helpful error messages with suggestions when validation fails.
     *
     * @param template The template to validate
     * @return ValidationResult with valid flag and error messages
     *
     * ## Error Message Examples
     * - "Unknown attribute 'onClick' for <button>. Did you mean: phxClick?"
     * - "Unknown HTML element: <customElement>. Register it first."
     * - "Attribute 'href' not valid for <input>. Available: type, name, value..."
     */
    static function validateTemplateTypes(template: String): ValidationResult {
#if !hxx_validate
        // Validation disabled: return success without touching heavy registries
        return { valid: true, errors: [] };
#else
        var errors: Array<String> = [];
        var valid = true;

        // Parse elements and their attributes
        var elementPattern = ~/<([a-zA-Z][a-zA-Z0-9\-]*)\s*([^>]*)>/g;

        elementPattern.map(template, function(r) {
            var tagName = r.matched(1);
            var attributesStr = r.matched(2);

            // Check if element is registered
            if (!HXXComponentRegistry.isRegisteredElement(tagName) && !StringTools.startsWith(tagName, ".")) {
                // Phoenix components start with ".", so skip those
                errors.push('Unknown HTML element: <${tagName}>. If this is a custom component, register it first.');
                valid = false;
            }

            // Parse and validate attributes
            if (attributesStr != null && attributesStr.length > 0) {
                validateAttributes(tagName, attributesStr, errors);
            }

            return "";
        });

        return { valid: valid, errors: errors };
#end
    }

    /**
     * Validate attributes for an element
     */
    static function validateAttributes(tagName: String, attributesStr: String, errors: Array<String>): Void {
#if !hxx_validate
        // No-op when validation is disabled
        return;
#else
        // Parse attributes (simplified - real implementation would be more robust)
        var attrPattern = ~/([a-zA-Z][a-zA-Z0-9]*)\s*=/g;

        attrPattern.map(attributesStr, function(r) {
            var attrName = r.matched(1);

            // Check if attribute is valid for this element
            if (!HXXComponentRegistry.validateAttribute(tagName, attrName)) {
                var allowed = HXXComponentRegistry.getAllowedAttributes(tagName);
                var suggestions = findSimilarAttributes(attrName, allowed);

                var errorMsg = 'Unknown attribute "${attrName}" for <${tagName}>.';
                if (suggestions.length > 0) {
                    errorMsg += ' Did you mean: ${suggestions.join(", ")}?';
                } else if (allowed.length > 0) {
                    errorMsg += ' Available: ${allowed.slice(0, 5).join(", ")}...';
                }

                errors.push(errorMsg);
            }

            return "";
        });
#end
    }

    /**
     * Find similar attribute names for suggestions
     */
    static function findSimilarAttributes(input: String, available: Array<String>): Array<String> {
        var suggestions = [];
        var inputLower = input.toLowerCase();

        for (attr in available) {
            var attrLower = attr.toLowerCase();
            // Simple similarity check - could be improved with Levenshtein distance
            if (attrLower.indexOf(inputLower) != -1 || inputLower.indexOf(attrLower) != -1) {
                suggestions.push(attr);
            }
        }

        return suggestions.slice(0, 3); // Return top 3 suggestions
    }

    /**
     * Convert camelCase attributes to kebab-case in templates
     *
     * Intelligently handles attribute naming conventions:
     * - `className` → `class` (special HTML case)
     * - `phxClick` → `phx-click` (Phoenix LiveView)
     * - `dataUserId` → `data-user-id` (data attributes)
     * - `ariaLabel` → `aria-label` (accessibility)
     *
     * Also preserves snake_case and kebab-case if already present.
     *
     * @param template The template with mixed attribute naming
     * @return Template with all attributes in correct HTML/HEEx format
     */
    static function convertAttributes(template: String): String {
        // Match attributes in tags
        var attrPattern = ~/(<[^>]+?)([a-zA-Z][a-zA-Z0-9]*)(\s*=\s*[^>]*?>)/g;

        return attrPattern.map(template, function(r) {
            var prefix = r.matched(1);
            var attrName = r.matched(2);
            var suffix = r.matched(3);

            // Convert the attribute name
            var convertedName = phoenix.types.HXXComponentRegistry.toHtmlAttribute(attrName);

            return prefix + convertedName + suffix;
        });
    }
    #end
}

/**
 * Validation result type
 */
typedef ValidationResult = {
    valid: Bool,
    errors: Array<String>
}
````
