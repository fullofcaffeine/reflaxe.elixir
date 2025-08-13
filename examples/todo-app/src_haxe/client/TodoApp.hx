package client;

import js.Browser;
import js.html.*;

/**
 * Client-side Haxe application for enhanced todo interactions
 * Compiles to JavaScript for Phoenix app
 */
class TodoApp {
	static var liveSocket: Dynamic;
	static var hooks: Dynamic = {};
	
	public static function main(): Void {
		// Initialize Phoenix LiveView hooks
		setupHooks();
		
		// Initialize enhanced UI features
		setupDragAndDrop();
		setupKeyboardShortcuts();
		setupNotifications();
		setupOfflineSupport();
		setupAnimations();
		
		// Connect to LiveView socket
		connectLiveView();
		
		trace("Todo App client initialized!");
	}
	
	static function setupHooks(): Void {
		// Hook for drag and drop reordering
		hooks.TodoDragDrop = {
			mounted: function() {
				var container = this.el;
				setupSortable(container);
			},
			updated: function() {
				// Re-initialize after LiveView updates
				var container = this.el;
				setupSortable(container);
			}
		};
		
		// Hook for local storage sync
		hooks.LocalStorage = {
			mounted: function() {
				// Load cached todos on mount
				var cached = localStorage.getItem("todos_cache");
				if (cached != null && !navigator.onLine) {
					this.pushEvent("load_cached", {todos: JSON.parse(cached)});
				}
			},
			updated: function() {
				// Cache todos on every update
				var todos = this.el.dataset.todos;
				if (todos != null) {
					localStorage.setItem("todos_cache", todos);
					localStorage.setItem("todos_cache_time", Date.now().toString());
				}
			}
		};
		
		// Hook for notifications
		hooks.Notifications = {
			mounted: function() {
				// Request notification permission
				if ("Notification" in Browser.window && Notification.permission == "default") {
					Notification.requestPermission();
				}
				
				// Listen for notification events from server
				this.handleEvent("notify", function(payload) {
					showNotification(payload.title, payload.body, payload.icon);
				});
			}
		};
		
		// Hook for keyboard shortcuts
		hooks.KeyboardShortcuts = {
			mounted: function() {
				var component = this;
				
				Browser.document.addEventListener("keydown", function(e: KeyboardEvent) {
					// Ctrl/Cmd + N: New todo
					if ((e.ctrlKey || e.metaKey) && e.key == "n") {
						e.preventDefault();
						component.pushEvent("toggle_form", {});
					}
					
					// Ctrl/Cmd + F: Focus search
					if ((e.ctrlKey || e.metaKey) && e.key == "f") {
						e.preventDefault();
						var search: InputElement = cast Browser.document.querySelector(".search-bar input");
						if (search != null) search.focus();
					}
					
					// Escape: Close forms/modals
					if (e.key == "Escape") {
						component.pushEvent("cancel_edit", {});
						component.pushEvent("toggle_form", {show: false});
					}
					
					// Alt + 1/2/3: Filter views
					if (e.altKey) {
						switch (e.key) {
							case "1": component.pushEvent("filter_todos", {filter: "all"});
							case "2": component.pushEvent("filter_todos", {filter: "active"});
							case "3": component.pushEvent("filter_todos", {filter: "completed"});
						}
					}
				});
			}
		};
		
		// Hook for rich text editor
		hooks.RichTextEditor = {
			mounted: function() {
				var textarea = this.el;
				setupMarkdownEditor(textarea);
			}
		};
	}
	
	static function setupDragAndDrop(): Void {
		// Enable drag and drop file uploads
		var dropZone = Browser.document.querySelector(".todo-form");
		if (dropZone == null) return;
		
		dropZone.addEventListener("dragover", function(e: DragEvent) {
			e.preventDefault();
			dropZone.classList.add("drag-over");
		});
		
		dropZone.addEventListener("dragleave", function(e: DragEvent) {
			dropZone.classList.remove("drag-over");
		});
		
		dropZone.addEventListener("drop", function(e: DragEvent) {
			e.preventDefault();
			dropZone.classList.remove("drag-over");
			
			var files = e.dataTransfer.files;
			for (i in 0...files.length) {
				processFile(files[i]);
			}
		});
	}
	
	static function setupSortable(container: Element): Void {
		// Make todo list sortable via drag and drop
		var items = container.querySelectorAll(".todo-item");
		var draggedItem: Element = null;
		
		for (item in items) {
			item.setAttribute("draggable", "true");
			
			item.addEventListener("dragstart", function(e: DragEvent) {
				draggedItem = cast e.target;
				e.dataTransfer.effectAllowed = "move";
				e.dataTransfer.setData("text/html", draggedItem.innerHTML);
				draggedItem.classList.add("dragging");
			});
			
			item.addEventListener("dragend", function(e: DragEvent) {
				draggedItem.classList.remove("dragging");
				draggedItem = null;
			});
			
			item.addEventListener("dragover", function(e: DragEvent) {
				if (e.preventDefault != null) e.preventDefault();
				e.dataTransfer.dropEffect = "move";
				
				var target: Element = cast e.target;
				if (target != null && target != draggedItem) {
					var rect = target.getBoundingClientRect();
					var midpoint = rect.top + rect.height / 2;
					
					if (e.clientY < midpoint) {
						target.parentNode.insertBefore(draggedItem, target);
					} else {
						target.parentNode.insertBefore(draggedItem, target.nextSibling);
					}
				}
				
				return false;
			});
		}
	}
	
	static function setupKeyboardShortcuts(): Void {
		// Quick add with Cmd+Enter
		var quickAddInput = Browser.document.querySelector("#quick-add");
		if (quickAddInput != null) {
			quickAddInput.addEventListener("keydown", function(e: KeyboardEvent) {
				if ((e.ctrlKey || e.metaKey) && e.key == "Enter") {
					var input: InputElement = cast quickAddInput;
					if (input.value.trim() != "") {
						pushEvent("quick_add", {title: input.value});
						input.value = "";
					}
				}
			});
		}
	}
	
	static function setupNotifications(): Void {
		// Setup browser notifications for reminders
		if ("Notification" in Browser.window) {
			// Check for todos with due dates
			setInterval(function() {
				checkDueDates();
			}, 60000); // Check every minute
		}
	}
	
	static function checkDueDates(): Void {
		var todos = Browser.document.querySelectorAll(".todo-item[data-due-date]");
		var now = Date.now();
		
		for (todo in todos) {
			var dueDate = Date.parse(todo.getAttribute("data-due-date"));
			var timeDiff = dueDate.getTime() - now;
			
			// Notify 15 minutes before due
			if (timeDiff > 0 && timeDiff < 15 * 60 * 1000) {
				var title = todo.querySelector(".todo-title").textContent;
				showNotification("Todo Due Soon", 'The todo "$title" is due in 15 minutes!', "📅");
			}
		}
	}
	
	static function showNotification(title: String, body: String, icon: String): Void {
		if ("Notification" in Browser.window && Notification.permission == "granted") {
			var notification = new Notification(title, {
				body: body,
				icon: icon,
				tag: "todo-reminder"
			});
			
			notification.onclick = function() {
				Browser.window.focus();
				notification.close();
			};
			
			// Auto-close after 5 seconds
			setTimeout(function() {
				notification.close();
			}, 5000);
		}
	}
	
	static function setupOfflineSupport(): Void {
		// Monitor online/offline status
		Browser.window.addEventListener("online", function() {
			showToast("Back online! Syncing changes...", "success");
			syncOfflineChanges();
		});
		
		Browser.window.addEventListener("offline", function() {
			showToast("You're offline. Changes will sync when reconnected.", "warning");
		});
		
		// Cache actions when offline
		if (!navigator.onLine) {
			interceptActions();
		}
	}
	
	static function interceptActions(): Void {
		// Store actions in local storage when offline
		var offlineQueue = [];
		var stored = localStorage.getItem("offline_queue");
		if (stored != null) {
			offlineQueue = JSON.parse(stored);
		}
		
		// Override push event to queue when offline
		var originalPush = window.liveSocket.pushEvent;
		window.liveSocket.pushEvent = function(event, payload) {
			if (!navigator.onLine) {
				offlineQueue.push({event: event, payload: payload, timestamp: Date.now()});
				localStorage.setItem("offline_queue", JSON.stringify(offlineQueue));
				showToast("Action queued for sync", "info");
			} else {
				originalPush.call(this, event, payload);
			}
		};
	}
	
	static function syncOfflineChanges(): Void {
		var stored = localStorage.getItem("offline_queue");
		if (stored != null) {
			var queue = JSON.parse(stored);
			for (action in queue) {
				window.liveSocket.pushEvent(action.event, action.payload);
			}
			localStorage.removeItem("offline_queue");
			showToast("Synced " + queue.length + " offline changes", "success");
		}
	}
	
	static function setupAnimations(): Void {
		// Add smooth animations for todo state changes
		var style = Browser.document.createStyleElement();
		style.textContent = '
			.todo-item {
				transition: all 0.3s ease;
				transform: translateX(0);
			}
			.todo-item.dragging {
				opacity: 0.5;
				transform: scale(1.05);
			}
			.todo-item.completed {
				opacity: 0.7;
			}
			.todo-item.completed .todo-title {
				text-decoration: line-through;
			}
			.todo-item:hover {
				transform: translateX(5px);
				box-shadow: 0 2px 8px rgba(0,0,0,0.1);
			}
			@keyframes slideIn {
				from { 
					opacity: 0;
					transform: translateY(-20px);
				}
				to {
					opacity: 1;
					transform: translateY(0);
				}
			}
			.todo-item.new {
				animation: slideIn 0.3s ease;
			}
		';
		Browser.document.head.appendChild(style);
	}
	
	static function processFile(file: File): Void {
		// Process dropped files (e.g., attach to todo)
		if (file.type.startsWith("image/")) {
			var reader = new FileReader();
			reader.onload = function(e) {
				pushEvent("attach_image", {
					name: file.name,
					data: e.target.result
				});
			};
			reader.readAsDataURL(file);
		} else if (file.type == "text/plain" || file.type == "text/markdown") {
			var reader = new FileReader();
			reader.onload = function(e) {
				pushEvent("import_todos", {
					content: e.target.result
				});
			};
			reader.readAsText(file);
		}
	}
	
	static function setupMarkdownEditor(textarea: Element): Void {
		// Add markdown shortcuts
		textarea.addEventListener("keydown", function(e: KeyboardEvent) {
			var ta: TextAreaElement = cast textarea;
			
			// Bold: Ctrl/Cmd + B
			if ((e.ctrlKey || e.metaKey) && e.key == "b") {
				e.preventDefault();
				wrapSelection(ta, "**", "**");
			}
			
			// Italic: Ctrl/Cmd + I
			if ((e.ctrlKey || e.metaKey) && e.key == "i") {
				e.preventDefault();
				wrapSelection(ta, "_", "_");
			}
			
			// Link: Ctrl/Cmd + K
			if ((e.ctrlKey || e.metaKey) && e.key == "k") {
				e.preventDefault();
				var url = prompt("Enter URL:");
				if (url != null) {
					wrapSelection(ta, "[", "](" + url + ")");
				}
			}
		});
	}
	
	static function wrapSelection(textarea: TextAreaElement, before: String, after: String): Void {
		var start = textarea.selectionStart;
		var end = textarea.selectionEnd;
		var text = textarea.value;
		var selected = text.substring(start, end);
		
		textarea.value = text.substring(0, start) + before + selected + after + text.substring(end);
		textarea.selectionStart = start + before.length;
		textarea.selectionEnd = end + before.length;
		textarea.focus();
	}
	
	static function connectLiveView(): Void {
		// Initialize LiveView socket with our hooks
		if (untyped window.liveSocket != null) {
			liveSocket = untyped window.liveSocket;
			
			// Add our hooks
			for (key in Reflect.fields(hooks)) {
				Reflect.setField(liveSocket.hooks, key, Reflect.field(hooks, key));
			}
			
			trace("LiveView hooks registered");
		}
	}
	
	static function pushEvent(event: String, payload: Dynamic): Void {
		if (liveSocket != null) {
			liveSocket.pushEvent(event, payload);
		}
	}
	
	static function showToast(message: String, type: String): Void {
		var toast = Browser.document.createDivElement();
		toast.className = 'toast toast-$type';
		toast.textContent = message;
		Browser.document.body.appendChild(toast);
		
		// Animate in
		setTimeout(function() {
			toast.classList.add("show");
		}, 10);
		
		// Remove after 3 seconds
		setTimeout(function() {
			toast.classList.remove("show");
			setTimeout(function() {
				toast.remove();
			}, 300);
		}, 3000);
	}
}