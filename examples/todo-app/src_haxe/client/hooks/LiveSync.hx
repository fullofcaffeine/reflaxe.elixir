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