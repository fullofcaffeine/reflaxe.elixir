# Your First Reflaxe.Elixir Project: Step-by-Step Tutorial

This tutorial will walk you through creating your first Elixir application using Haxe and Reflaxe.Elixir. We'll build a simple task manager application that demonstrates the power of type-safe Elixir development.

## Prerequisites

Before starting, ensure you have:
- **Haxe 4.3+** installed ([installation guide](https://haxe.org/download/))
- **Elixir 1.14+** installed ([installation guide](https://elixir-lang.org/install.html))
- **Node.js 16+** installed (for package management)
- **lix** package manager (we'll install this)

## Step 1: Install Reflaxe.Elixir

First, let's install lix (the Haxe package manager) and Reflaxe.Elixir:

```bash
# Install lix globally
npm install -g lix

# Install Reflaxe.Elixir
lix install github:fullofcaffeine/reflaxe.elixir
```

Verify the installation:
```bash
haxelib run reflaxe.elixir version
# Output: Reflaxe.Elixir v0.1.0
```

## Step 2: Create Your First Project

Let's create a simple task manager application:

```bash
# Create a new project
haxelib run reflaxe.elixir create task-manager

# The interactive CLI will guide you:
# Project type? → Choose "1. Basic - Standard Mix project"
# Include example modules? → Yes
# Install dependencies now? → Yes
```

This creates the following structure:
```
task-manager/
├── src_haxe/           # Your Haxe source files
│   └── Main.hx         # Entry point
├── lib/                # Elixir code (generated + manual)
│   └── generated/      # Generated from Haxe
├── test/               # Tests
├── build.hxml          # Haxe build configuration
├── mix.exs             # Elixir project file
└── package.json        # Node dependencies
```

## Step 3: Explore the Project Structure

Navigate to your project:
```bash
cd task-manager
```

Open `src_haxe/Main.hx` in your editor:

```haxe
package;

/**
 * Main entry point for the Task Manager application
 */
@:module
class Main {
    public static function main(): Void {
        trace("Welcome to Task Manager!");
        
        // Create a new task manager
        var manager = new TaskManager();
        manager.run();
    }
}
```

## Step 4: Create Your First Module

Let's create a `TaskManager` class. Create `src_haxe/TaskManager.hx`:

```haxe
package;

import elixir.IO;
import elixir.Enum;
import elixir.ElixirMap;

/**
 * Simple task manager with type-safe operations
 */
@:module
class TaskManager {
    private var tasks: Array<Task>;
    private var nextId: Int;
    
    public function new() {
        this.tasks = [];
        this.nextId = 1;
    }
    
    public function run(): Void {
        IO.puts("Task Manager v1.0");
        IO.puts("================");
        
        // Add some example tasks
        addTask("Learn Reflaxe.Elixir", "high");
        addTask("Build awesome apps", "medium");
        addTask("Share with community", "low");
        
        // Display all tasks
        listTasks();
        
        // Complete a task
        completeTask(1);
        
        // Show updated list
        IO.puts("\nAfter completing task 1:");
        listTasks();
    }
    
    public function addTask(title: String, priority: String): Task {
        var task: Task = {
            id: nextId++,
            title: title,
            priority: priority,
            completed: false,
            createdAt: Date.now()
        };
        
        tasks.push(task);
        IO.puts('Added task #${task.id}: ${task.title}');
        return task;
    }
    
    public function completeTask(id: Int): Bool {
        for (task in tasks) {
            if (task.id == id) {
                task.completed = true;
                IO.puts('Completed task #${id}');
                return true;
            }
        }
        IO.puts('Task #${id} not found');
        return false;
    }
    
    public function listTasks(): Void {
        IO.puts("\nCurrent Tasks:");
        IO.puts("-------------");
        
        for (task in tasks) {
            var status = task.completed ? "✓" : " ";
            var priority = switch (task.priority) {
                case "high": "🔴";
                case "medium": "🟡";
                case "low": "🟢";
                default: "⚪";
            }
            IO.puts('[$status] $priority Task #${task.id}: ${task.title}');
        }
    }
}

typedef Task = {
    id: Int,
    title: String,
    priority: String,
    completed: Bool,
    createdAt: Date
}
```

## Step 5: Compile Haxe to Elixir

Now let's compile our Haxe code to Elixir:

```bash
# Compile the project
npx haxe build.hxml

# Or use the npm script
npm run compile
```

This generates Elixir code in `lib/generated/`. Check `lib/generated/task_manager.ex` to see the generated Elixir code:

```elixir
defmodule TaskManager do
  @moduledoc """
  Simple task manager with type-safe operations
  """
  
  defstruct tasks: [], next_id: 1
  
  def new() do
    %TaskManager{tasks: [], next_id: 1}
  end
  
  def run(manager) do
    IO.puts("Task Manager v1.0")
    IO.puts("================")
    # ... generated code
  end
  
  # ... more generated functions
end
```

## Step 6: Run Your Application

Execute your application using Mix:

```bash
# Run the application
mix run -e "Main.main()"

# Output:
# Welcome to Task Manager!
# Task Manager v1.0
# ================
# Added task #1: Learn Reflaxe.Elixir
# Added task #2: Build awesome apps
# Added task #3: Share with community
#
# Current Tasks:
# -------------
# [ ] 🔴 Task #1: Learn Reflaxe.Elixir
# [ ] 🟡 Task #2: Build awesome apps
# [ ] 🟢 Task #3: Share with community
# Completed task #1
#
# After completing task 1:
# Current Tasks:
# -------------
# [✓] 🔴 Task #1: Learn Reflaxe.Elixir
# [ ] 🟡 Task #2: Build awesome apps
# [ ] 🟢 Task #3: Share with community
```

## Step 7: Add Persistence with GenServer

Let's make our task manager persistent using OTP GenServer. Create `src_haxe/TaskServer.hx`:

```haxe
package;

import elixir.GenServer;
import elixir.ElixirMap;

/**
 * GenServer-based task storage
 */
@:genserver
class TaskServer {
    // State
    public var tasks: Array<Task>;
    public var nextId: Int;
    
    // GenServer callbacks
    public function init(args: Dynamic): Dynamic {
        return {:ok, %{tasks: [], nextId: 1}};
    }
    
    public function handleCall(request: Dynamic, from: Dynamic, state: Dynamic): Dynamic {
        return switch (request) {
            case {:add_task, title, priority}:
                var task = createTask(state.nextId, title, priority);
                var newState = %{
                    tasks: state.tasks ++ [task],
                    nextId: state.nextId + 1
                };
                {:reply, task, newState};
                
            case {:get_tasks}:
                {:reply, state.tasks, state};
                
            case {:complete_task, id}:
                var tasks = updateTaskStatus(state.tasks, id, true);
                {:reply, :ok, %{state | tasks: tasks}};
                
            default:
                {:reply, :error, state};
        };
    }
    
    // Helper functions
    private static function createTask(id: Int, title: String, priority: String): Task {
        return {
            id: id,
            title: title,
            priority: priority,
            completed: false,
            createdAt: Date.now()
        };
    }
    
    private static function updateTaskStatus(tasks: Array<Task>, id: Int, completed: Bool): Array<Task> {
        return tasks.map(function(task) {
            if (task.id == id) {
                return {...task, completed: completed};
            }
            return task;
        });
    }
}
```

## Step 8: Add Tests

Create `test/task_manager_test.exs`:

```elixir
defmodule TaskManagerTest do
  use ExUnit.Case
  
  test "creates new task manager" do
    manager = TaskManager.new()
    assert manager.next_id == 1
    assert manager.tasks == []
  end
  
  test "adds tasks with incrementing IDs" do
    manager = TaskManager.new()
    task1 = TaskManager.add_task(manager, "First task", "high")
    assert task1.id == 1
    assert task1.title == "First task"
    assert task1.priority == "high"
    assert task1.completed == false
  end
  
  test "completes tasks by ID" do
    manager = TaskManager.new()
    manager = TaskManager.add_task(manager, "Test task", "medium")
    result = TaskManager.complete_task(manager, 1)
    assert result == true
  end
end
```

Run the tests:
```bash
mix test
```

## Step 9: Add a CLI Interface

Let's create a command-line interface. Create `src_haxe/CLI.hx`:

```haxe
package;

import elixir.IO;
import elixir.System;

/**
 * Command-line interface for Task Manager
 */
@:module
class CLI {
    private var manager: TaskManager;
    
    public function new() {
        this.manager = new TaskManager();
    }
    
    public function start(): Void {
        IO.puts("Welcome to Task Manager CLI!");
        IO.puts("Commands: add, list, complete, exit");
        
        loop();
    }
    
    private function loop(): Void {
        while (true) {
            var input = IO.gets("> ");
            var parts = input.trim().split(" ");
            var command = parts[0];
            
            switch (command) {
                case "add":
                    if (parts.length < 3) {
                        IO.puts("Usage: add <title> <priority>");
                        continue;
                    }
                    var title = parts.slice(1, parts.length - 1).join(" ");
                    var priority = parts[parts.length - 1];
                    manager.addTask(title, priority);
                    
                case "list":
                    manager.listTasks();
                    
                case "complete":
                    if (parts.length < 2) {
                        IO.puts("Usage: complete <id>");
                        continue;
                    }
                    var id = Std.parseInt(parts[1]);
                    manager.completeTask(id);
                    
                case "exit":
                    IO.puts("Goodbye!");
                    System.halt(0);
                    break;
                    
                default:
                    IO.puts('Unknown command: $command');
            }
        }
    }
}
```

## Step 10: Build and Package

Finally, let's prepare for distribution:

```bash
# Run all tests
mix test

# Compile with optimizations
npx haxe build.hxml -D analyzer-optimize

# Create a release
mix release
```

## Next Steps

Congratulations! You've built your first Reflaxe.Elixir application. Here's what you can explore next:

### 1. **Add a Phoenix Web Interface**
Convert your CLI app to a web application:
```bash
haxelib run reflaxe.elixir create task-manager-web --type phoenix
```

### 2. **Add Database Persistence with Ecto**
Learn how to use typed Ecto schemas:
```haxe
@:schema
class Task {
    public var id: Int;
    public var title: String;
    public var priority: String;
    public var completed: Bool;
    public var insertedAt: Date;
    public var updatedAt: Date;
}
```

### 3. **Create LiveView Components**
Build real-time UI with typed LiveView:
```haxe
@:liveview
class TaskLive {
    public function mount(params: Dynamic, session: Dynamic, socket: Socket): Socket {
        return socket.assign({
            tasks: TaskServer.getTasks()
        });
    }
    
    public function handleEvent("add_task", params: Dynamic, socket: Socket): Socket {
        // Handle real-time task addition
    }
}
```

### 4. **Explore Advanced Features**
- Pattern matching with exhaustive checks
- Typed GenServer implementations
- HXX templates for Phoenix views
- Compile-time Ecto query validation

## Troubleshooting

### Common Issues

**Compilation errors:**
```bash
# Clean and rebuild
rm -rf lib/generated
npx haxe build.hxml
```

**Missing dependencies:**
```bash
# Reinstall Haxe dependencies
npm install
npx lix download

# Reinstall Elixir dependencies
mix deps.get
```

**Runtime errors:**
Check that all modules are properly annotated:
- Use `@:module` for regular modules
- Use `@:genserver` for GenServers
- Use `@:liveview` for LiveView components

## Resources

- [Reflaxe.Elixir Documentation](../README.md)
- [API Reference](./API_REFERENCE.md)
- [Phoenix Integration Guide](./PHOENIX_GUIDE.md)
- [Examples Repository](../examples/)
- [Community Discord](#)

## Summary

In this tutorial, you learned how to:
- ✅ Install and set up Reflaxe.Elixir
- ✅ Create a new project using the generator
- ✅ Write type-safe Elixir code using Haxe
- ✅ Compile Haxe to Elixir
- ✅ Use OTP patterns like GenServer
- ✅ Create a CLI interface
- ✅ Write and run tests

You now have the foundation to build production-ready Elixir applications with the type safety and tooling of Haxe!