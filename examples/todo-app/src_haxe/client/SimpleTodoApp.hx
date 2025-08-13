package client;

import js.Browser;
import js.html.*;
import js.Syntax;
import js.Lib;
import haxe.Json;

/**
 * Phoenix Socket extern for proper typing
 */
@:native("Socket")
extern class PhoenixSocket {
    function new(): Void;
}

/**
 * Phoenix LiveSocket extern for proper typing  
 */
@:native("LiveSocket")
extern class PhoenixLiveSocket {
    var hooks: Dynamic;
    
    function new(url: String, socket: PhoenixSocket, ?opts: Dynamic): Void;
    function connect(): Void;
    function disconnect(): Void;
    function enableDebug(): Void;
    function enableLatencySim(upper_ms: Int): Void;
    function disableLatencySim(): Void;
    function pushEvent(event: String, payload: Dynamic): Void;
}

/**
 * Phoenix LiveView Hook - Proper extern definition
 * Based on Phoenix LiveView's JavaScript hook lifecycle
 */
@:native("Object") 
extern class LiveViewHook {
    /** The DOM element the hook is attached to */
    var el: Element;
    
    /** 
     * Push an event to the LiveView process 
     * @param event - Event name to trigger on the server
     * @param payload - Data to send with the event
     * @param callback - Optional callback function
     */
    function pushEvent(event: String, payload: {}, ?callback: Dynamic -> Void): Void;
    
    /**
     * Push an event to a specific target component
     * @param target - Target element or selector  
     * @param event - Event name
     * @param payload - Event payload
     * @param callback - Optional callback
     */
    function pushEventTo(target: Dynamic, event: String, payload: {}, ?callback: Dynamic -> Void): Void;
    
    /**
     * Execute JavaScript in the hook's context
     * @param callback - Function to execute
     */
    function handleEvent(event: String, callback: Dynamic -> Void): Void;
    
    /**
     * Upload files through LiveView
     */
    var upload: Dynamic;
    
    /**
     * Hook lifecycle: called when element is added to DOM
     */
    @:optional function mounted(): Void;
    
    /**
     * Hook lifecycle: called when element is updated  
     */
    @:optional function updated(): Void;
    
    /**
     * Hook lifecycle: called before element is removed
     */
    @:optional function beforeUpdate(): Void;
    
    /**
     * Hook lifecycle: called when element is removed from DOM
     */
    @:optional function destroyed(): Void;
    
    /**
     * Hook lifecycle: called when connection is lost
     */
    @:optional function disconnected(): Void;
    
    /**
     * Hook lifecycle: called when connection is restored
     */
    @:optional function reconnected(): Void;
}

/**
 * Haxe client that AUGMENTS LiveView (doesn't replace it):
 * - Visual feedback & animations (LiveView can't do)
 * - Browser APIs (localStorage, notifications) 
 * - Keyboard shortcuts for UX
 * - Drag & drop visual feedback
 * 
 * All business logic stays server-side in LiveView!
 */
class SimpleTodoApp {
    static var hooks: Dynamic = {};
    static var liveSocket: Dynamic;
    
    public static function main(): Void {
        Browser.window.addEventListener("DOMContentLoaded", function() {
            setupLiveViewHooks();
            setupGlobalKeyboardShortcuts();
            trace("✅ Haxe Todo Client initialized!");
        });
    }
    
    /**
     * Helper to create a LiveView hook function with proper 'this' context
     * Uses Reflect.callMethod to bind the JavaScript 'this' to our typed handler
     */
    static function createHookFunction(handler: LiveViewHook -> Void): Dynamic {
        return function() {
            // Use Reflect.callMethod pattern - 'this' becomes the hook context  
            var hook: LiveViewHook = cast untyped js.Lib.nativeThis;
            handler(hook);
        };
    }

    static function setupLiveViewHooks(): Void {
        // Create hooks using proper context binding - much cleaner!
        
        // Drag visual feedback hook
        Reflect.setField(hooks, "TodoDragVisuals", {
            mounted: createHookFunction(function(hook) addDragVisualFeedback(hook.el)),
            updated: createHookFunction(function(hook) addUpdateFlash(hook.el))
        });
        
        // Offline cache hook  
        Reflect.setField(hooks, "TodoOfflineCache", {
            mounted: createHookFunction(function(hook) loadOfflineIndicator(hook.el)),
            updated: createHookFunction(function(hook) cacheForOffline(hook.el))
        });
        
        // Animation/keyboard hook
        Reflect.setField(hooks, "TodoAnimations", {
            mounted: createHookFunction(function(hook) setupKeyboardShortcuts(hook))
        });
    }
    
    static function addDragVisualFeedback(container: Element): Void {
        var items = container.querySelectorAll(".todo-item");
        for (i in 0...items.length) {
            var item = cast(items[i], Element);
            
            item.addEventListener("mousedown", function(e: MouseEvent) {
                cast(e.target, Element).classList.add("grabbing");
            });
            
            item.addEventListener("mouseup", function(e: MouseEvent) {
                cast(e.target, Element).classList.remove("grabbing");
            });
            
            item.addEventListener("mouseenter", function(e: MouseEvent) {
                cast(e.target, Element).classList.add("haxe-hover");
            });
            
            item.addEventListener("mouseleave", function(e: MouseEvent) {
                cast(e.target, Element).classList.remove("haxe-hover");
            });
        }
    }
    
    static function addUpdateFlash(element: Element): Void {
        element.classList.add("updated-flash");
        Browser.window.setTimeout(function() {
            element.classList.remove("updated-flash");
        }, 200);
    }
    
    static function loadOfflineIndicator(element: Element): Void {
        var storage = Browser.getLocalStorage();
        var cached = storage.getItem("todos_cache");
        if (cached != null) {
            element.classList.add("has-offline-cache");
        }
    }
    
    static function cacheForOffline(element: Element): Void {
        var storage = Browser.getLocalStorage();
        var todosData = untyped element.dataset.todos; // Only untyped for dataset access
        if (todosData != null) {
            storage.setItem("todos_cache", todosData);
            storage.setItem("todos_cache_time", Std.string(Date.now().getTime()));
        }
    }
    
    static function setupKeyboardShortcuts(hook: LiveViewHook): Void {
        hook.el.addEventListener("keydown", function(e: KeyboardEvent) {
            if ((e.ctrlKey || e.metaKey) && e.key == "Enter") {
                e.preventDefault();
                hook.pushEvent("toggle_todo", {});
            }
            
            if (e.key == "Delete") {
                e.preventDefault();
                hook.pushEvent("delete_todo", {});
            }
            
            if (e.key == "Escape") {
                e.preventDefault();
                hook.pushEvent("cancel_edit", {});
            }
        });
    }
    
    
    static function setupGlobalKeyboardShortcuts(): Void {
        Browser.document.addEventListener("keydown", function(e: KeyboardEvent) {
            // Ctrl/Cmd + N: New todo
            if ((e.ctrlKey || e.metaKey) && e.key == "n") {
                e.preventDefault();
                pushGlobalEvent("new_todo", {});
            }
            
            // Ctrl/Cmd + F: Focus search
            if ((e.ctrlKey || e.metaKey) && e.key == "f") {
                e.preventDefault();
                var searchInput = Browser.document.querySelector(".search-input");
                if (searchInput != null) {
                    untyped searchInput.focus();
                }
            }
            
            // Alt + A/C: Filter todos
            if (e.altKey) {
                switch (e.key) {
                    case "a": pushGlobalEvent("filter_todos", {filter: "all"});
                    case "c": pushGlobalEvent("filter_todos", {filter: "completed"});
                    case "p": pushGlobalEvent("filter_todos", {filter: "pending"});
                }
            }
        });
    }
    
    // Note: LiveSocket connection now handled by app.js
    // Hooks are exposed via window.HaxeTodoHooks for integration
    
    static function pushGlobalEvent(event: String, payload: Dynamic): Void {
        if (liveSocket != null) {
            untyped liveSocket.pushEvent(event, payload);
        }
    }
    
    static function showToast(message: String, ?type: String = "info"): Void {
        var toast = Browser.document.createDivElement();
        toast.className = 'haxe-toast haxe-toast-$type';
        toast.textContent = message;
        
        // Add styles
        untyped toast.style.cssText = '
            position: fixed;
            top: 20px;
            right: 20px;
            background: #333;
            color: white;
            padding: 12px 20px;
            border-radius: 4px;
            z-index: 1000;
            opacity: 0;
            transition: opacity 0.3s;
        ';
        
        Browser.document.body.appendChild(toast);
        
        // Fade in
        untyped setTimeout(function() {
            untyped toast.style.opacity = "1";
        }, 10);
        
        // Remove after 3 seconds
        untyped setTimeout(function() {
            untyped toast.style.opacity = "0";
            untyped setTimeout(function() {
                if (toast.parentNode != null) {
                    toast.parentNode.removeChild(toast);
                }
            }, 300);
        }, 3000);
    }
}