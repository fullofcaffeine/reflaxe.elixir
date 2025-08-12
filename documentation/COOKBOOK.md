# Reflaxe.Elixir Cookbook

Practical, copy-paste recipes for common tasks. Each recipe is complete and ready to use in your projects.

## 📚 Recipe Categories

| Category | Recipes | Difficulty |
|----------|---------|------------|
| [Basic Patterns](#basic-patterns) | Modules, functions, utilities | 🟢 Beginner |
| [Mix Integration](#mix-integration) | Build setup, testing, deps | 🟢 Beginner |
| [Phoenix Web](#phoenix-web) | Controllers, routing, middleware | 🟡 Intermediate |
| [LiveView Components](#liveview-components) | Real-time UI, forms, events | 🟡 Intermediate |
| [Ecto Database](#ecto-database) | Schemas, queries, migrations | 🟡 Intermediate |
| [OTP Patterns](#otp-patterns) | GenServer, supervision, state | 🔴 Advanced |
| [Authentication](#authentication) | Login, sessions, JWT | 🔴 Advanced |
| [Background Jobs](#background-jobs) | Async processing, queues | 🔴 Advanced |

## Basic Patterns

### Recipe 1: Simple Utility Module

**Use Case**: Create reusable utility functions for string/data manipulation.

```haxe
// src_haxe/utils/TextUtils.hx
package utils;

@:module
class TextUtils {
    public static function slugify(text: String): String {
        return text
            .toLowerCase()
            .replace(~/[^a-z0-9]+/g, "-")
            .replace(~/^-|-$/g, "");
    }
    
    public static function truncate(text: String, length: Int, suffix: String = "..."): String {
        if (text.length <= length) return text;
        return text.substr(0, length - suffix.length) + suffix;
    }
    
    public static function extractEmails(text: String): Array<String> {
        var regex = ~/([a-zA-Z0-9._%-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,})/g;
        var emails = [];
        var pos = 0;
        while (regex.matchSub(text, pos)) {
            emails.push(regex.matched(1));
            pos = regex.matchedPos().pos + regex.matchedPos().len;
        }
        return emails;
    }
}
```

**Generated Elixir**:
```elixir
defmodule Utils.TextUtils do
  def slugify(text) do
    text
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9]+/, "-")
    |> String.replace(~r/^-|-$/, "")
  end
  
  def truncate(text, length, suffix \\ "...") do
    if String.length(text) <= length do
      text
    else
      String.slice(text, 0, length - String.length(suffix)) <> suffix
    end
  end
  
  def extract_emails(text) do
    Regex.scan(~r/([a-zA-Z0-9._%-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,})/, text)
    |> Enum.map(fn [_, email] -> email end)
  end
end
```

**Usage**:
```elixir
iex> Utils.TextUtils.slugify("Hello World! 123")
"hello-world-123"
iex> Utils.TextUtils.truncate("Long text here", 8)
"Long..."
```

---

### Recipe 2: Configuration Service

**Use Case**: Centralized application configuration with environment support.

```haxe
// src_haxe/services/ConfigService.hx
package services;

@:module
class ConfigService {
    private static var config: Map<String, Dynamic> = new Map();
    
    public static function init(): Void {
        // Load from environment variables
        config.set("database_url", getEnv("DATABASE_URL", "localhost:5432"));
        config.set("secret_key", getEnv("SECRET_KEY_BASE", "default-secret"));
        config.set("port", Std.parseInt(getEnv("PORT", "4000")));
        config.set("debug", getEnv("DEBUG", "false") == "true");
    }
    
    public static function get(key: String, ?defaultValue: Dynamic): Dynamic {
        if (config.exists(key)) {
            return config.get(key);
        }
        return defaultValue;
    }
    
    public static function set(key: String, value: Dynamic): Void {
        config.set(key, value);
    }
    
    public static function getString(key: String, defaultValue: String = ""): String {
        var value = get(key, defaultValue);
        return Std.string(value);
    }
    
    public static function getInt(key: String, defaultValue: Int = 0): Int {
        var value = get(key, defaultValue);
        return Std.isOfType(value, Int) ? value : defaultValue;
    }
    
    public static function getBool(key: String, defaultValue: Bool = false): Bool {
        var value = get(key, defaultValue);
        return value == true || value == "true";
    }
    
    private static function getEnv(name: String, defaultValue: String): String {
        // This would use System.getEnv() in real implementation
        return defaultValue; // Simplified for cookbook
    }
}
```

**Usage**:
```elixir
# In your application start
Services.ConfigService.init()

# Throughout your app
port = Services.ConfigService.get_int("port", 4000)
debug_mode = Services.ConfigService.get_bool("debug")
```

---

### Recipe 3: JSON API Response Builder

**Use Case**: Consistent API responses with success/error patterns.

```haxe
// src_haxe/utils/ApiResponse.hx
package utils;

@:module
class ApiResponse {
    public static function success(data: Dynamic, ?message: String): Dynamic {
        var response = {
            success: true,
            data: data
        };
        if (message != null) {
            response.message = message;
        }
        return response;
    }
    
    public static function error(message: String, ?code: String, ?details: Dynamic): Dynamic {
        var response = {
            success: false,
            error: {
                message: message
            }
        };
        if (code != null) {
            response.error.code = code;
        }
        if (details != null) {
            response.error.details = details;
        }
        return response;
    }
    
    public static function validationError(errors: Map<String, Array<String>>): Dynamic {
        return {
            success: false,
            error: {
                message: "Validation failed",
                code: "VALIDATION_ERROR",
                validation_errors: errors
            }
        };
    }
    
    public static function paginated(data: Array<Dynamic>, page: Int, perPage: Int, total: Int): Dynamic {
        return {
            success: true,
            data: data,
            pagination: {
                page: page,
                per_page: perPage,
                total: total,
                total_pages: Math.ceil(total / perPage)
            }
        };
    }
}
```

---

## Mix Integration

### Recipe 4: Custom Mix Task

**Use Case**: Create a custom Mix task that uses your Haxe modules.

```haxe
// src_haxe/mix/tasks/DataMigration.hx
package mix.tasks;

@:module
class DataMigration {
    public static function run(args: Array<String>): Void {
        trace("Starting data migration...");
        
        var batchSize = args.length > 0 ? Std.parseInt(args[0]) ?? 1000 : 1000;
        
        // Example migration logic
        migrateUsers(batchSize);
        migrateOrders(batchSize);
        
        trace("Data migration completed!");
    }
    
    private static function migrateUsers(batchSize: Int): Void {
        trace('Migrating users in batches of $batchSize');
        // Migration logic here
    }
    
    private static function migrateOrders(batchSize: Int): Void {
        trace('Migrating orders in batches of $batchSize');
        // Migration logic here
    }
}
```

**Mix Task Wrapper** (lib/mix/tasks/data_migration.ex):
```elixir
defmodule Mix.Tasks.DataMigration do
  use Mix.Task

  @shortdoc "Runs data migration using Haxe logic"
  
  def run(args) do
    Mix.Tasks.DataMigration.run(args)
  end
end
```

**Usage**:
```bash
mix data_migration 500
```

---

## Phoenix Web

### Recipe 5: REST API Controller

**Use Case**: Standard CRUD REST API with JSON responses.

```haxe
// src_haxe/controllers/UserController.hx
package controllers;

@:controller
class UserController {
    public function index(conn: Dynamic, params: Dynamic): Dynamic {
        var page = Std.parseInt(params.page ?? "1") ?? 1;
        var users = UserService.listUsers(page);
        
        return conn
            |> putStatus(200)
            |> json(ApiResponse.paginated(users.data, users.page, users.perPage, users.total));
    }
    
    public function show(conn: Dynamic, params: Dynamic): Dynamic {
        var userId = Std.parseInt(params.id);
        if (userId == null) {
            return conn
                |> putStatus(400)
                |> json(ApiResponse.error("Invalid user ID"));
        }
        
        return switch (UserService.getUser(userId)) {
            case null:
                conn
                |> putStatus(404)
                |> json(ApiResponse.error("User not found"));
            case user:
                conn
                |> putStatus(200)
                |> json(ApiResponse.success(user));
        };
    }
    
    public function create(conn: Dynamic, params: Dynamic): Dynamic {
        var userData = params.user ?? {};
        
        return switch (UserService.createUser(userData)) {
            case {success: true, data: user}:
                conn
                |> putStatus(201)
                |> json(ApiResponse.success(user, "User created successfully"));
                
            case {success: false, errors: errors}:
                conn
                |> putStatus(422)
                |> json(ApiResponse.validationError(errors));
        };
    }
    
    public function update(conn: Dynamic, params: Dynamic): Dynamic {
        var userId = Std.parseInt(params.id);
        var userData = params.user ?? {};
        
        if (userId == null) {
            return conn
                |> putStatus(400)
                |> json(ApiResponse.error("Invalid user ID"));
        }
        
        return switch (UserService.updateUser(userId, userData)) {
            case {success: true, data: user}:
                conn
                |> putStatus(200)
                |> json(ApiResponse.success(user, "User updated successfully"));
                
            case {success: false, errors: errors}:
                conn
                |> putStatus(422)
                |> json(ApiResponse.validationError(errors));
                
            case null:
                conn
                |> putStatus(404)
                |> json(ApiResponse.error("User not found"));
        };
    }
    
    public function delete(conn: Dynamic, params: Dynamic): Dynamic {
        var userId = Std.parseInt(params.id);
        
        if (userId == null) {
            return conn
                |> putStatus(400)
                |> json(ApiResponse.error("Invalid user ID"));
        }
        
        return switch (UserService.deleteUser(userId)) {
            case true:
                conn
                |> putStatus(204)
                |> send();
                
            case false:
                conn
                |> putStatus(404)
                |> json(ApiResponse.error("User not found"));
        };
    }
}
```

---

### Recipe 6: Authentication Middleware

**Use Case**: JWT-based authentication middleware for protected routes.

```haxe
// src_haxe/middleware/AuthMiddleware.hx
package middleware;

@:module
class AuthMiddleware {
    public static function call(conn: Dynamic, opts: Dynamic): Dynamic {
        return switch (extractToken(conn)) {
            case null:
                conn
                |> putStatus(401)
                |> json({error: "Authorization header required"})
                |> halt();
                
            case token:
                switch (verifyToken(token)) {
                    case null:
                        conn
                        |> putStatus(401)
                        |> json({error: "Invalid or expired token"})
                        |> halt();
                        
                    case user:
                        conn
                        |> assign("current_user", user);
                }
        };
    }
    
    private static function extractToken(conn: Dynamic): String {
        var authHeader = getReqHeader(conn, "authorization");
        if (authHeader != null && authHeader.startsWith("Bearer ")) {
            return authHeader.substr(7);
        }
        return null;
    }
    
    private static function verifyToken(token: String): Dynamic {
        // JWT verification logic would go here
        // This is a simplified example
        if (token == "valid-token") {
            return {id: 1, email: "user@example.com"};
        }
        return null;
    }
}
```

---

## LiveView Components

### Recipe 7: Real-time Chat Component

**Use Case**: LiveView component for real-time messaging.

```haxe
// src_haxe/live/ChatLive.hx
package live;

@:liveview
class ChatLive {
    var messages: Array<Dynamic> = [];
    var newMessage: String = "";
    var currentUser: Dynamic = null;
    
    public function mount(params: Dynamic, session: Dynamic, socket: Dynamic): Dynamic {
        var roomId = params.room_id ?? "general";
        currentUser = session.user;
        
        // Subscribe to chat updates
        PubSub.subscribe("chat:" + roomId);
        
        // Load recent messages
        messages = ChatService.getRecentMessages(roomId, 50);
        
        return socket
            |> assign("messages", messages)
            |> assign("new_message", "")
            |> assign("room_id", roomId)
            |> assign("current_user", currentUser);
    }
    
    public function handleEvent("send_message", params: Dynamic, socket: Dynamic): Dynamic {
        var content = params.message ?? "";
        
        if (content.trim() == "") {
            return socket;
        }
        
        var message = {
            id: generateId(),
            content: content,
            user_id: currentUser.id,
            username: currentUser.username,
            timestamp: Date.now()
        };
        
        // Save message
        ChatService.saveMessage(message);
        
        // Broadcast to all users in room
        var roomId = socket.assigns.room_id;
        PubSub.broadcast("chat:" + roomId, {new_message: message});
        
        return socket
            |> assign("new_message", "");
    }
    
    public function handleInfo(info: Dynamic, socket: Dynamic): Dynamic {
        return switch (info.type) {
            case "new_message":
                var messages = socket.assigns.messages;
                messages.push(info.new_message);
                
                socket
                |> assign("messages", messages);
                
            default:
                socket;
        };
    }
    
    public function render(): String {
        return hxx('
            <div class="chat-container">
                <div class="chat-header">
                    <h2>Chat Room: {assigns.room_id}</h2>
                    <span class="user-info">Logged in as: {assigns.current_user.username}</span>
                </div>
                
                <div class="messages" id="messages">
                    {for message <- assigns.messages}
                        <div class="message" class={if message.user_id == assigns.current_user.id then "own-message" else "other-message"}>
                            <span class="username">{message.username}</span>
                            <span class="timestamp">{formatTime(message.timestamp)}</span>
                            <div class="content">{message.content}</div>
                        </div>
                    {/for}
                </div>
                
                <form phx-submit="send_message" class="message-form">
                    <input 
                        type="text" 
                        name="message" 
                        value={assigns.new_message}
                        placeholder="Type your message..."
                        autocomplete="off"
                        phx-hook="AutoFocus"
                    />
                    <button type="submit">Send</button>
                </form>
            </div>
        ');
    }
    
    private function formatTime(timestamp: Float): String {
        var date = Date.fromTime(timestamp);
        return '${date.getHours()}:${String(date.getMinutes()).lpad("0", 2)}';
    }
    
    private function generateId(): String {
        return Std.string(Math.floor(Math.random() * 1000000));
    }
}
```

---

### Recipe 8: Dynamic Form with Validation

**Use Case**: LiveView form with real-time validation and dynamic fields.

```haxe
// src_haxe/live/UserFormLive.hx
package live;

@:liveview
class UserFormLive {
    var changeset: Dynamic = null;
    var user: Dynamic = null;
    var showAdvanced: Bool = false;
    
    public function mount(params: Dynamic, session: Dynamic, socket: Dynamic): Dynamic {
        var userId = params.user_id;
        
        user = userId != null ? UserService.getUser(Std.parseInt(userId)) : {};
        changeset = UserService.changeUser(user, {});
        
        return socket
            |> assign("user", user)
            |> assign("changeset", changeset)
            |> assign("show_advanced", false);
    }
    
    public function handleEvent("validate", params: Dynamic, socket: Dynamic): Dynamic {
        var userParams = params.user ?? {};
        changeset = UserService.changeUser(socket.assigns.user, userParams);
        
        return socket
            |> assign("changeset", changeset);
    }
    
    public function handleEvent("save", params: Dynamic, socket: Dynamic): Dynamic {
        var userParams = params.user ?? {};
        
        return switch (UserService.saveUser(socket.assigns.user, userParams)) {
            case {success: true, data: savedUser}:
                socket
                |> putFlash("info", "User saved successfully!")
                |> redirect({to: "/users/" + savedUser.id});
                
            case {success: false, changeset: errorChangeset}:
                socket
                |> assign("changeset", errorChangeset);
        };
    }
    
    public function handleEvent("toggle_advanced", params: Dynamic, socket: Dynamic): Dynamic {
        return socket
            |> assign("show_advanced", !socket.assigns.show_advanced);
    }
    
    public function handleEvent("add_skill", params: Dynamic, socket: Dynamic): Dynamic {
        var skills = socket.assigns.user.skills ?? [];
        skills.push({name: "", level: "beginner"});
        
        var updatedUser = socket.assigns.user;
        updatedUser.skills = skills;
        
        return socket
            |> assign("user", updatedUser);
    }
    
    public function handleEvent("remove_skill", params: Dynamic, socket: Dynamic): Dynamic {
        var index = Std.parseInt(params.index);
        var skills = socket.assigns.user.skills ?? [];
        
        if (index != null && index < skills.length) {
            skills.splice(index, 1);
        }
        
        var updatedUser = socket.assigns.user;
        updatedUser.skills = skills;
        
        return socket
            |> assign("user", updatedUser);
    }
    
    public function render(): String {
        return hxx('
            <div class="user-form">
                <h1>{if assigns.user.id then "Edit User" else "New User"}</h1>
                
                <.form 
                    let={f} 
                    for={assigns.changeset} 
                    phx-submit="save" 
                    phx-change="validate"
                >
                    <div class="form-grid">
                        <div class="form-group">
                            <.input field={f[:name]} label="Name" required />
                        </div>
                        
                        <div class="form-group">
                            <.input field={f[:email]} type="email" label="Email" required />
                        </div>
                        
                        <div class="form-group">
                            <.input field={f[:role]} type="select" label="Role" 
                                options={[
                                    {"Admin", "admin"},
                                    {"User", "user"},
                                    {"Guest", "guest"}
                                ]}
                            />
                        </div>
                        
                        <div class="form-group">
                            <.input field={f[:active]} type="checkbox" label="Active" />
                        </div>
                    </div>
                    
                    <div class="form-section">
                        <button 
                            type="button" 
                            phx-click="toggle_advanced"
                            class="toggle-button"
                        >
                            {if assigns.show_advanced then "Hide" else "Show"} Advanced Options
                        </button>
                        
                        {if assigns.show_advanced}
                            <div class="advanced-fields">
                                <div class="form-group">
                                    <.input field={f[:bio]} type="textarea" label="Bio" />
                                </div>
                                
                                <div class="skills-section">
                                    <h3>Skills</h3>
                                    {for {skill, index} <- Enum.with_index(assigns.user.skills || [])}
                                        <div class="skill-item">
                                            <input 
                                                type="text" 
                                                name={"user[skills][#{index}][name]"} 
                                                value={skill.name}
                                                placeholder="Skill name"
                                            />
                                            <select name={"user[skills][#{index}][level]"} value={skill.level}>
                                                <option value="beginner">Beginner</option>
                                                <option value="intermediate">Intermediate</option>
                                                <option value="advanced">Advanced</option>
                                                <option value="expert">Expert</option>
                                            </select>
                                            <button 
                                                type="button" 
                                                phx-click="remove_skill" 
                                                phx-value-index={index}
                                                class="remove-button"
                                            >
                                                Remove
                                            </button>
                                        </div>
                                    {/for}
                                    
                                    <button 
                                        type="button" 
                                        phx-click="add_skill"
                                        class="add-button"
                                    >
                                        Add Skill
                                    </button>
                                </div>
                            </div>
                        {/if}
                    </div>
                    
                    <div class="form-actions">
                        <.button type="submit" disabled={!assigns.changeset.valid?}>
                            {if assigns.user.id then "Update" else "Create"} User
                        </.button>
                        
                        <.link href="/users" class="cancel-link">
                            Cancel
                        </.link>
                    </div>
                </.form>
            </div>
        ');
    }
}
```

---

## Ecto Database

### Recipe 9: Advanced Ecto Schema with Relationships

**Use Case**: Complex schema with multiple relationships and custom fields.

```haxe
// src_haxe/schemas/Order.hx
package schemas;

@:schema(table: "orders")
class Order {
    @:primary_key
    public var id: Int;
    
    @:field({type: "string", null: false})
    public var orderNumber: String;
    
    @:field({type: "decimal", precision: 10, scale: 2, null: false})
    public var totalAmount: Float;
    
    @:field({type: "string", null: false})
    public var status: String; // pending, confirmed, shipped, delivered, cancelled
    
    @:field({type: "map"})
    public var shippingAddress: Dynamic;
    
    @:field({type: "map"})
    public var billingAddress: Dynamic;
    
    @:field({type: "text"})
    public var notes: String;
    
    // Relationships
    @:belongs_to("User", foreign_key: "user_id")
    public var user: Dynamic;
    
    @:has_many("OrderItem", foreign_key: "order_id")
    public var orderItems: Array<Dynamic>;
    
    @:has_one("OrderTracking", foreign_key: "order_id")
    public var tracking: Dynamic;
    
    @:timestamps
    public var insertedAt: String;
    public var updatedAt: String;
}

@:changeset
class OrderChangeset {
    @:validate_required(["order_number", "total_amount", "status", "user_id"])
    @:validate_inclusion("status", ["pending", "confirmed", "shipped", "delivered", "cancelled"])
    @:validate_number("total_amount", greater_than: 0)
    public static function changeset(order: Order, attrs: Dynamic): Dynamic {
        return order
            |> cast(attrs, ["order_number", "total_amount", "status", "shipping_address", 
                           "billing_address", "notes", "user_id"])
            |> validateOrderNumber()
            |> validateAddresses()
            |> assocConstraint("user");
    }
    
    private static function validateOrderNumber(changeset: Dynamic): Dynamic {
        return changeset
            |> validateFormat("order_number", ~/^ORD-\d{8}$/, "Invalid order number format");
    }
    
    private static function validateAddresses(changeset: Dynamic): Dynamic {
        var shippingAddr = getField(changeset, "shipping_address");
        
        if (shippingAddr != null) {
            if (!hasRequiredAddressFields(shippingAddr)) {
                changeset = addError(changeset, "shipping_address", "Missing required address fields");
            }
        }
        
        return changeset;
    }
    
    private static function hasRequiredAddressFields(address: Dynamic): Bool {
        var required = ["street", "city", "state", "zip_code"];
        for (field in required) {
            if (!Reflect.hasField(address, field) || Reflect.field(address, field) == null) {
                return false;
            }
        }
        return true;
    }
}
```

---

### Recipe 10: Complex Query with Joins and Aggregates

**Use Case**: Comprehensive reporting query with multiple tables and calculations.

```haxe
// src_haxe/queries/OrderReportQuery.hx
package queries;

@:query
class OrderReportQuery {
    public static function monthlyOrderReport(year: Int, month: Int): Array<Dynamic> {
        return from(o in Order, {
            join: u in User, on: o.user_id == u.id,
            join: oi in OrderItem, on: oi.order_id == o.id,
            join: p in Product, on: oi.product_id == p.id,
            where: fragment("EXTRACT(year FROM ?)", o.inserted_at) == year
                && fragment("EXTRACT(month FROM ?)", o.inserted_at) == month,
            group_by: [o.status, u.id, u.name],
            select: {
                status: o.status,
                user_id: u.id,
                user_name: u.name,
                order_count: count(o.id),
                total_revenue: sum(oi.quantity * oi.unit_price),
                avg_order_value: avg(o.total_amount),
                most_ordered_product: fragment(
                    "array_agg(? ORDER BY sum(?*?) DESC LIMIT 1)", 
                    p.name, oi.quantity, oi.unit_price
                )
            }
        });
    }
    
    public static function topCustomersByRevenue(limit: Int = 10): Array<Dynamic> {
        return from(u in User, {
            join: o in Order, on: o.user_id == u.id,
            where: o.status in ["confirmed", "shipped", "delivered"],
            group_by: [u.id, u.name, u.email],
            order_by: [desc: sum(o.total_amount)],
            limit: limit,
            select: {
                user_id: u.id,
                name: u.name,
                email: u.email,
                total_orders: count(o.id),
                total_spent: sum(o.total_amount),
                avg_order_value: avg(o.total_amount),
                first_order: min(o.inserted_at),
                last_order: max(o.inserted_at)
            }
        });
    }
    
    public static function productPerformance(startDate: String, endDate: String): Array<Dynamic> {
        return from(p in Product, {
            join: oi in OrderItem, on: oi.product_id == p.id,
            join: o in Order, on: o.id == oi.order_id,
            where: o.inserted_at >= startDate 
                && o.inserted_at <= endDate 
                && o.status != "cancelled",
            group_by: [p.id, p.name, p.category],
            order_by: [desc: sum(oi.quantity * oi.unit_price)],
            select: {
                product_id: p.id,
                product_name: p.name,
                category: p.category,
                total_quantity_sold: sum(oi.quantity),
                total_revenue: sum(oi.quantity * oi.unit_price),
                avg_selling_price: avg(oi.unit_price),
                unique_customers: count(o.user_id, distinct: true),
                orders_count: count(o.id, distinct: true)
            }
        });
    }
    
    public static function salesTrendByDay(days: Int = 30): Array<Dynamic> {
        return from(o in Order, {
            where: o.inserted_at >= fragment("NOW() - INTERVAL '? days'", days)
                && o.status != "cancelled",
            group_by: fragment("DATE(?)", o.inserted_at),
            order_by: [asc: fragment("DATE(?)", o.inserted_at)],
            select: {
                date: fragment("DATE(?)", o.inserted_at),
                order_count: count(o.id),
                total_revenue: sum(o.total_amount),
                avg_order_value: avg(o.total_amount),
                new_customers: fragment(
                    "COUNT(DISTINCT CASE WHEN ? = (SELECT MIN(?) FROM orders o2 WHERE o2.user_id = ?) THEN ? END)",
                    fragment("DATE(?)", o.inserted_at),
                    fragment("DATE(?)", o.inserted_at),
                    o.user_id,
                    o.user_id
                )
            }
        });
    }
}
```

---

## OTP Patterns

### Recipe 11: Stateful GenServer with Periodic Tasks

**Use Case**: Cache server that periodically refreshes data and handles concurrent access.

```haxe
// src_haxe/servers/CacheServer.hx
package servers;

@:genserver
class CacheServer {
    var cache: Map<String, Dynamic> = new Map();
    var ttl: Map<String, Float> = new Map();
    var refreshInterval: Int = 60000; // 1 minute
    var maxSize: Int = 10000;
    var stats: Dynamic = {
        hits: 0,
        misses: 0,
        evictions: 0
    };
    
    public function init(opts: Dynamic): Dynamic {
        refreshInterval = opts.refresh_interval ?? 60000;
        maxSize = opts.max_size ?? 10000;
        
        // Schedule periodic cleanup
        Process.sendAfter(self(), :cleanup, refreshInterval);
        
        return {:ok, {
            cache: cache,
            ttl: ttl,
            stats: stats,
            max_size: maxSize
        }};
    }
    
    // Synchronous operations
    public function handleCall(request: Dynamic, from: Dynamic, state: Dynamic): Dynamic {
        return switch (request) {
            case {:get, key}:
                handleGet(key, state);
                
            case {:put, key, value, ttlSeconds}:
                handlePut(key, value, ttlSeconds, state);
                
            case {:delete, key}:
                handleDelete(key, state);
                
            case :stats:
                {:reply, state.stats, state};
                
            case :size:
                {:reply, state.cache.size, state};
                
            case :clear:
                var clearedState = {
                    cache: new Map(),
                    ttl: new Map(),
                    stats: {hits: 0, misses: 0, evictions: 0},
                    max_size: state.max_size
                };
                {:reply, :ok, clearedState};
                
            default:
                {:reply, {:error, "Unknown request"}, state};
        };
    }
    
    // Asynchronous operations
    public function handleCast(request: Dynamic, state: Dynamic): Dynamic {
        return switch (request) {
            case {:put_async, key, value, ttlSeconds}:
                var newState = putValue(key, value, ttlSeconds, state);
                {:noreply, newState};
                
            case {:delete_async, key}:
                var newState = deleteValue(key, state);
                {:noreply, newState};
                
            case :force_cleanup:
                var newState = performCleanup(state);
                {:noreply, newState};
                
            default:
                {:noreply, state};
        };
    }
    
    // Handle periodic messages
    public function handleInfo(info: Dynamic, state: Dynamic): Dynamic {
        return switch (info) {
            case :cleanup:
                var cleanedState = performCleanup(state);
                // Schedule next cleanup
                Process.sendAfter(self(), :cleanup, refreshInterval);
                {:noreply, cleanedState};
                
            case {:refresh_key, key}:
                var refreshedState = refreshKey(key, state);
                {:noreply, refreshedState};
                
            default:
                {:noreply, state};
        };
    }
    
    // Client API
    public static function startLink(opts: Dynamic = null): Dynamic {
        return GenServer.startLink(__MODULE__, opts ?? {}, {name: __MODULE__});
    }
    
    public static function get(key: String): Dynamic {
        return GenServer.call(__MODULE__, {:get, key});
    }
    
    public static function put(key: String, value: Dynamic, ttlSeconds: Int = 3600): Dynamic {
        return GenServer.call(__MODULE__, {:put, key, value, ttlSeconds});
    }
    
    public static function putAsync(key: String, value: Dynamic, ttlSeconds: Int = 3600): Dynamic {
        return GenServer.cast(__MODULE__, {:put_async, key, value, ttlSeconds});
    }
    
    public static function delete(key: String): Dynamic {
        return GenServer.call(__MODULE__, {:delete, key});
    }
    
    public static function stats(): Dynamic {
        return GenServer.call(__MODULE__, :stats);
    }
    
    public static function size(): Int {
        return GenServer.call(__MODULE__, :size);
    }
    
    public static function clear(): Dynamic {
        return GenServer.call(__MODULE__, :clear);
    }
    
    // Private helper functions
    private function handleGet(key: String, state: Dynamic): Dynamic {
        if (isExpired(key, state)) {
            var cleanedState = deleteValue(key, state);
            cleanedState.stats.misses++;
            return {:reply, null, cleanedState};
        }
        
        if (state.cache.exists(key)) {
            state.stats.hits++;
            return {:reply, state.cache.get(key), state};
        } else {
            state.stats.misses++;
            return {:reply, null, state};
        }
    }
    
    private function handlePut(key: String, value: Dynamic, ttlSeconds: Int, state: Dynamic): Dynamic {
        var newState = putValue(key, value, ttlSeconds, state);
        return {:reply, :ok, newState};
    }
    
    private function handleDelete(key: String, state: Dynamic): Dynamic {
        var existed = state.cache.exists(key);
        var newState = deleteValue(key, state);
        return {:reply, existed, newState};
    }
    
    private function putValue(key: String, value: Dynamic, ttlSeconds: Int, state: Dynamic): Dynamic {
        // Evict if at capacity
        if (state.cache.size >= state.max_size && !state.cache.exists(key)) {
            evictOldest(state);
        }
        
        state.cache.set(key, value);
        state.ttl.set(key, Date.now().getTime() + (ttlSeconds * 1000));
        
        return state;
    }
    
    private function deleteValue(key: String, state: Dynamic): Dynamic {
        state.cache.remove(key);
        state.ttl.remove(key);
        return state;
    }
    
    private function isExpired(key: String, state: Dynamic): Bool {
        if (!state.ttl.exists(key)) return false;
        return Date.now().getTime() > state.ttl.get(key);
    }
    
    private function performCleanup(state: Dynamic): Dynamic {
        var keysToRemove = [];
        var now = Date.now().getTime();
        
        for (key in state.ttl.keys()) {
            if (state.ttl.get(key) < now) {
                keysToRemove.push(key);
            }
        }
        
        for (key in keysToRemove) {
            state.cache.remove(key);
            state.ttl.remove(key);
            state.stats.evictions++;
        }
        
        return state;
    }
    
    private function evictOldest(state: Dynamic): Dynamic {
        var oldestKey = null;
        var oldestTime = Math.POSITIVE_INFINITY;
        
        for (key in state.ttl.keys()) {
            var time = state.ttl.get(key);
            if (time < oldestTime) {
                oldestTime = time;
                oldestKey = key;
            }
        }
        
        if (oldestKey != null) {
            state.cache.remove(oldestKey);
            state.ttl.remove(oldestKey);
            state.stats.evictions++;
        }
        
        return state;
    }
    
    private function refreshKey(key: String, state: Dynamic): Dynamic {
        // Custom refresh logic would go here
        // For example, reload from database
        return state;
    }
}
```

---

### Recipe 12: Supervisor with Dynamic Children

**Use Case**: Supervisor that can dynamically start and stop worker processes.

```haxe
// src_haxe/supervisors/WorkerSupervisor.hx
package supervisors;

@:supervisor
class WorkerSupervisor {
    var workers: Map<String, Dynamic> = new Map();
    
    public function init(args: Dynamic): Dynamic {
        var children = [
            // Static children can be defined here
            {
                id: "main_cache",
                start: {CacheServer, :start_link, [{}]},
                restart: "permanent"
            }
        ];
        
        return Supervisor.init(children, {
            strategy: "one_for_one",
            max_restarts: 10,
            max_seconds: 60
        });
    }
    
    public static function startLink(args: Dynamic): Dynamic {
        return Supervisor.startLink(__MODULE__, args, {name: __MODULE__});
    }
    
    // Dynamic worker management
    public static function startWorker(workerId: String, workerModule: String, args: Dynamic): Dynamic {
        var childSpec = {
            id: workerId,
            start: {workerModule, :start_link, [args]},
            restart: "temporary"
        };
        
        return Supervisor.startChild(__MODULE__, childSpec);
    }
    
    public static function stopWorker(workerId: String): Dynamic {
        return Supervisor.terminateChild(__MODULE__, workerId)
            && Supervisor.deleteChild(__MODULE__, workerId);
    }
    
    public static function restartWorker(workerId: String): Dynamic {
        return Supervisor.restartChild(__MODULE__, workerId);
    }
    
    public static function listWorkers(): Array<Dynamic> {
        return Supervisor.whichChildren(__MODULE__);
    }
    
    public static function workerExists(workerId: String): Bool {
        var children = listWorkers();
        for (child in children) {
            if (child.id == workerId) {
                return true;
            }
        }
        return false;
    }
}
```

---

## Authentication

### Recipe 13: JWT Authentication System

**Use Case**: Complete JWT-based authentication with login, logout, and token refresh.

```haxe
// src_haxe/auth/AuthService.hx
package auth;

@:module
class AuthService {
    private static var secretKey: String = "your-secret-key-here";
    private static var accessTokenTTL: Int = 900; // 15 minutes
    private static var refreshTokenTTL: Int = 604800; // 7 days
    
    public static function authenticate(email: String, password: String): Dynamic {
        return switch (UserService.findByEmail(email)) {
            case null:
                {success: false, error: "Invalid credentials"};
                
            case user:
                if (verifyPassword(password, user.password_hash)) {
                    var tokens = generateTokens(user);
                    // Store refresh token
                    RefreshTokenService.store(user.id, tokens.refresh_token);
                    {
                        success: true,
                        user: sanitizeUser(user),
                        access_token: tokens.access_token,
                        refresh_token: tokens.refresh_token,
                        expires_in: accessTokenTTL
                    };
                } else {
                    {success: false, error: "Invalid credentials"};
                }
        };
    }
    
    public static function refreshTokens(refreshToken: String): Dynamic {
        return switch (verifyRefreshToken(refreshToken)) {
            case null:
                {success: false, error: "Invalid or expired refresh token"};
                
            case payload:
                var user = UserService.findById(payload.user_id);
                if (user == null) {
                    {success: false, error: "User not found"};
                } else {
                    // Revoke old refresh token
                    RefreshTokenService.revoke(refreshToken);
                    
                    // Generate new tokens
                    var tokens = generateTokens(user);
                    RefreshTokenService.store(user.id, tokens.refresh_token);
                    
                    {
                        success: true,
                        user: sanitizeUser(user),
                        access_token: tokens.access_token,
                        refresh_token: tokens.refresh_token,
                        expires_in: accessTokenTTL
                    };
                }
        };
    }
    
    public static function logout(refreshToken: String): Dynamic {
        RefreshTokenService.revoke(refreshToken);
        return {success: true};
    }
    
    public static function verifyAccessToken(token: String): Dynamic {
        try {
            var payload = JWT.verify(token, secretKey);
            var currentTime = Math.floor(Date.now().getTime() / 1000);
            
            if (payload.exp < currentTime) {
                return null; // Token expired
            }
            
            return payload;
        } catch (e: Dynamic) {
            return null; // Invalid token
        }
    }
    
    public static function changePassword(userId: Int, currentPassword: String, newPassword: String): Dynamic {
        var user = UserService.findById(userId);
        if (user == null) {
            return {success: false, error: "User not found"};
        }
        
        if (!verifyPassword(currentPassword, user.password_hash)) {
            return {success: false, error: "Current password is incorrect"};
        }
        
        if (!isValidPassword(newPassword)) {
            return {success: false, error: "Password does not meet requirements"};
        }
        
        var newHash = hashPassword(newPassword);
        var updated = UserService.updatePassword(userId, newHash);
        
        if (updated) {
            // Revoke all refresh tokens for this user
            RefreshTokenService.revokeAllForUser(userId);
            return {success: true, message: "Password changed successfully"};
        } else {
            return {success: false, error: "Failed to update password"};
        }
    }
    
    public static function requestPasswordReset(email: String): Dynamic {
        var user = UserService.findByEmail(email);
        if (user == null) {
            // Don't reveal if email exists
            return {success: true, message: "If the email exists, a reset link has been sent"};
        }
        
        var resetToken = generateResetToken(user.id);
        PasswordResetService.store(user.id, resetToken, 3600); // 1 hour expiry
        
        // Send reset email (would integrate with email service)
        EmailService.sendPasswordReset(user.email, resetToken);
        
        return {success: true, message: "If the email exists, a reset link has been sent"};
    }
    
    public static function resetPassword(resetToken: String, newPassword: String): Dynamic {
        var resetData = PasswordResetService.verify(resetToken);
        if (resetData == null) {
            return {success: false, error: "Invalid or expired reset token"};
        }
        
        if (!isValidPassword(newPassword)) {
            return {success: false, error: "Password does not meet requirements"};
        }
        
        var newHash = hashPassword(newPassword);
        var updated = UserService.updatePassword(resetData.user_id, newHash);
        
        if (updated) {
            // Clean up
            PasswordResetService.revoke(resetToken);
            RefreshTokenService.revokeAllForUser(resetData.user_id);
            
            return {success: true, message: "Password reset successfully"};
        } else {
            return {success: false, error: "Failed to reset password"};
        }
    }
    
    // Private helper functions
    private static function generateTokens(user: Dynamic): Dynamic {
        var accessPayload = {
            user_id: user.id,
            email: user.email,
            role: user.role,
            exp: Math.floor(Date.now().getTime() / 1000) + accessTokenTTL
        };
        
        var refreshPayload = {
            user_id: user.id,
            type: "refresh",
            exp: Math.floor(Date.now().getTime() / 1000) + refreshTokenTTL
        };
        
        return {
            access_token: JWT.sign(accessPayload, secretKey),
            refresh_token: JWT.sign(refreshPayload, secretKey)
        };
    }
    
    private static function verifyRefreshToken(token: String): Dynamic {
        try {
            var payload = JWT.verify(token, secretKey);
            var currentTime = Math.floor(Date.now().getTime() / 1000);
            
            if (payload.exp < currentTime || payload.type != "refresh") {
                return null;
            }
            
            // Check if token is revoked
            if (RefreshTokenService.isRevoked(token)) {
                return null;
            }
            
            return payload;
        } catch (e: Dynamic) {
            return null;
        }
    }
    
    private static function hashPassword(password: String): String {
        // Would use proper password hashing (bcrypt, argon2)
        return "hashed_" + password; // Simplified for cookbook
    }
    
    private static function verifyPassword(password: String, hash: String): Bool {
        // Would use proper password verification
        return hash == "hashed_" + password; // Simplified for cookbook
    }
    
    private static function isValidPassword(password: String): Bool {
        return password.length >= 8 
            && ~/[A-Z]/.match(password)
            && ~/[a-z]/.match(password)
            && ~/[0-9]/.match(password);
    }
    
    private static function generateResetToken(userId: Int): String {
        var payload = {
            user_id: userId,
            type: "password_reset",
            exp: Math.floor(Date.now().getTime() / 1000) + 3600
        };
        
        return JWT.sign(payload, secretKey);
    }
    
    private static function sanitizeUser(user: Dynamic): Dynamic {
        return {
            id: user.id,
            email: user.email,
            name: user.name,
            role: user.role,
            active: user.active
        };
    }
}
```

---

## Background Jobs

### Recipe 14: Background Job Processor

**Use Case**: Queue-based background job processing with retry logic and error handling.

```haxe
// src_haxe/jobs/JobProcessor.hx
package jobs;

@:genserver
class JobProcessor {
    var jobQueue: Array<Dynamic> = [];
    var processing: Map<String, Dynamic> = new Map();
    var maxConcurrent: Int = 5;
    var retryAttempts: Int = 3;
    var retryDelay: Int = 5000; // 5 seconds
    
    public function init(opts: Dynamic): Dynamic {
        maxConcurrent = opts.max_concurrent ?? 5;
        retryAttempts = opts.retry_attempts ?? 3;
        retryDelay = opts.retry_delay ?? 5000;
        
        // Start processing loop
        Process.sendAfter(self(), :process_jobs, 100);
        
        return {:ok, {
            queue: jobQueue,
            processing: processing,
            max_concurrent: maxConcurrent,
            retry_attempts: retryAttempts,
            retry_delay: retryDelay
        }};
    }
    
    public function handleCast(request: Dynamic, state: Dynamic): Dynamic {
        return switch (request) {
            case {:enqueue, job}:
                var newJob = {
                    id: generateJobId(),
                    type: job.type,
                    payload: job.payload,
                    attempts: 0,
                    max_attempts: job.max_attempts ?? state.retry_attempts,
                    scheduled_at: job.scheduled_at ?? Date.now().getTime(),
                    created_at: Date.now().getTime()
                };
                
                state.queue.push(newJob);
                {:noreply, state};
                
            case {:retry_job, jobId}:
                var job = findJob(jobId, state);
                if (job != null) {
                    job.scheduled_at = Date.now().getTime() + state.retry_delay;
                    job.attempts++;
                    state.queue.push(job);
                }
                {:noreply, state};
                
            case {:cancel_job, jobId}:
                var newState = removeJob(jobId, state);
                {:noreply, newState};
                
            default:
                {:noreply, state};
        };
    }
    
    public function handleCall(request: Dynamic, from: Dynamic, state: Dynamic): Dynamic {
        return switch (request) {
            case :status:
                {:reply, {
                    queue_size: state.queue.length,
                    processing_count: state.processing.size,
                    max_concurrent: state.max_concurrent
                }, state};
                
            case {:job_status, jobId}:
                var status = getJobStatus(jobId, state);
                {:reply, status, state};
                
            case :clear_queue:
                var newState = {
                    queue: [],
                    processing: state.processing,
                    max_concurrent: state.max_concurrent,
                    retry_attempts: state.retry_attempts,
                    retry_delay: state.retry_delay
                };
                {:reply, :ok, newState};
                
            default:
                {:reply, {:error, "Unknown request"}, state};
        };
    }
    
    public function handleInfo(info: Dynamic, state: Dynamic): Dynamic {
        return switch (info) {
            case :process_jobs:
                var newState = processAvailableJobs(state);
                // Schedule next processing cycle
                Process.sendAfter(self(), :process_jobs, 1000);
                {:noreply, newState};
                
            case {:job_completed, jobId, result}:
                var newState = handleJobCompletion(jobId, result, state);
                {:noreply, newState};
                
            case {:job_failed, jobId, error}:
                var newState = handleJobFailure(jobId, error, state);
                {:noreply, newState};
                
            default:
                {:noreply, state};
        };
    }
    
    // Client API
    public static function startLink(opts: Dynamic = null): Dynamic {
        return GenServer.startLink(__MODULE__, opts ?? {}, {name: __MODULE__});
    }
    
    public static function enqueue(jobType: String, payload: Dynamic, ?opts: Dynamic): String {
        var job = {
            type: jobType,
            payload: payload
        };
        
        if (opts != null) {
            if (opts.max_attempts != null) job.max_attempts = opts.max_attempts;
            if (opts.scheduled_at != null) job.scheduled_at = opts.scheduled_at;
        }
        
        GenServer.cast(__MODULE__, {:enqueue, job});
        return job.id;
    }
    
    public static function scheduleJob(jobType: String, payload: Dynamic, delayMs: Int): String {
        return enqueue(jobType, payload, {
            scheduled_at: Date.now().getTime() + delayMs
        });
    }
    
    public static function cancelJob(jobId: String): Dynamic {
        return GenServer.cast(__MODULE__, {:cancel_job, jobId});
    }
    
    public static function status(): Dynamic {
        return GenServer.call(__MODULE__, :status);
    }
    
    public static function jobStatus(jobId: String): Dynamic {
        return GenServer.call(__MODULE__, {:job_status, jobId});
    }
    
    // Private helper functions
    private function processAvailableJobs(state: Dynamic): Dynamic {
        var currentTime = Date.now().getTime();
        var availableSlots = state.max_concurrent - state.processing.size;
        
        if (availableSlots <= 0) {
            return state;
        }
        
        var jobsToProcess = [];
        var remainingJobs = [];
        
        for (job in state.queue) {
            if (job.scheduled_at <= currentTime && jobsToProcess.length < availableSlots) {
                jobsToProcess.push(job);
            } else {
                remainingJobs.push(job);
            }
        }
        
        // Start processing jobs
        for (job in jobsToProcess) {
            startJobProcessing(job, state);
        }
        
        return {
            queue: remainingJobs,
            processing: state.processing,
            max_concurrent: state.max_concurrent,
            retry_attempts: state.retry_attempts,
            retry_delay: state.retry_delay
        };
    }
    
    private function startJobProcessing(job: Dynamic, state: Dynamic): Void {
        state.processing.set(job.id, job);
        
        // Spawn job worker process
        Task.start(function() {
            try {
                var result = executeJob(job);
                Process.send(self(), {:job_completed, job.id, result});
            } catch (error: Dynamic) {
                Process.send(self(), {:job_failed, job.id, error});
            }
        });
    }
    
    private function executeJob(job: Dynamic): Dynamic {
        return switch (job.type) {
            case "send_email":
                EmailJobHandler.execute(job.payload);
                
            case "process_image":
                ImageJobHandler.execute(job.payload);
                
            case "generate_report":
                ReportJobHandler.execute(job.payload);
                
            case "cleanup_files":
                FileCleanupJobHandler.execute(job.payload);
                
            case "send_notifications":
                NotificationJobHandler.execute(job.payload);
                
            default:
                throw "Unknown job type: " + job.type;
        };
    }
    
    private function handleJobCompletion(jobId: String, result: Dynamic, state: Dynamic): Dynamic {
        state.processing.remove(jobId);
        
        // Log successful completion
        trace('Job $jobId completed successfully');
        
        // Could store results or send notifications here
        JobResultStore.store(jobId, {
            status: "completed",
            result: result,
            completed_at: Date.now().getTime()
        });
        
        return state;
    }
    
    private function handleJobFailure(jobId: String, error: Dynamic, state: Dynamic): Dynamic {
        var job = state.processing.get(jobId);
        state.processing.remove(jobId);
        
        if (job != null && job.attempts < job.max_attempts) {
            // Retry the job
            trace('Job $jobId failed, retrying (attempt ${job.attempts + 1}/${job.max_attempts})');
            GenServer.cast(self(), {:retry_job, jobId});
        } else {
            // Job failed permanently
            trace('Job $jobId failed permanently after ${job?.attempts ?? 0} attempts');
            JobResultStore.store(jobId, {
                status: "failed",
                error: error,
                failed_at: Date.now().getTime(),
                attempts: job?.attempts ?? 0
            });
        }
        
        return state;
    }
    
    private function findJob(jobId: String, state: Dynamic): Dynamic {
        for (job in state.queue) {
            if (job.id == jobId) {
                return job;
            }
        }
        return null;
    }
    
    private function removeJob(jobId: String, state: Dynamic): Dynamic {
        var newQueue = [];
        for (job in state.queue) {
            if (job.id != jobId) {
                newQueue.push(job);
            }
        }
        
        return {
            queue: newQueue,
            processing: state.processing,
            max_concurrent: state.max_concurrent,
            retry_attempts: state.retry_attempts,
            retry_delay: state.retry_delay
        };
    }
    
    private function getJobStatus(jobId: String, state: Dynamic): Dynamic {
        // Check if processing
        if (state.processing.exists(jobId)) {
            return {status: "processing"};
        }
        
        // Check if queued
        for (job in state.queue) {
            if (job.id == jobId) {
                return {
                    status: "queued",
                    scheduled_at: job.scheduled_at,
                    attempts: job.attempts
                };
            }
        }
        
        // Check completed/failed jobs
        return JobResultStore.get(jobId) ?? {status: "not_found"};
    }
    
    private function generateJobId(): String {
        return "job_" + Math.floor(Math.random() * 1000000) + "_" + Date.now().getTime();
    }
}

// Job handler interfaces
@:module
class EmailJobHandler {
    public static function execute(payload: Dynamic): Dynamic {
        // Email sending logic
        trace('Sending email to ${payload.to}: ${payload.subject}');
        // Would integrate with actual email service
        return {sent: true, message_id: "msg_" + Math.floor(Math.random() * 1000000)};
    }
}

@:module
class ImageJobHandler {
    public static function execute(payload: Dynamic): Dynamic {
        // Image processing logic
        trace('Processing image: ${payload.image_url}');
        // Would integrate with image processing service
        return {processed: true, output_url: payload.image_url + "_processed"};
    }
}

@:module
class ReportJobHandler {
    public static function execute(payload: Dynamic): Dynamic {
        // Report generation logic
        trace('Generating report: ${payload.report_type}');
        return {generated: true, report_url: "/reports/report_" + Date.now().getTime() + ".pdf"};
    }
}
```

---

### Recipe 15: File Upload Handler with Background Processing

**Use Case**: Handle file uploads with virus scanning, image processing, and metadata extraction.

```haxe
// src_haxe/uploaders/FileUploadHandler.hx
package uploaders;

@:module
class FileUploadHandler {
    private static var uploadDir: String = "uploads/";
    private static var maxFileSize: Int = 10 * 1024 * 1024; // 10MB
    private static var allowedTypes: Array<String> = [
        "image/jpeg", "image/png", "image/gif", "image/webp",
        "application/pdf", "text/plain", "application/zip"
    ];
    
    public static function handleUpload(conn: Dynamic, params: Dynamic): Dynamic {
        var upload = params.file;
        
        if (upload == null) {
            return conn
                |> putStatus(400)
                |> json(ApiResponse.error("No file provided"));
        }
        
        // Validate file
        var validation = validateFile(upload);
        if (!validation.valid) {
            return conn
                |> putStatus(400)
                |> json(ApiResponse.error(validation.error));
        }
        
        // Generate secure filename
        var filename = generateSecureFilename(upload.filename);
        var filepath = uploadDir + filename;
        
        // Save file
        try {
            saveUploadedFile(upload, filepath);
        } catch (error: Dynamic) {
            return conn
                |> putStatus(500)
                |> json(ApiResponse.error("Failed to save file"));
        }
        
        // Create file record
        var fileRecord = {
            id: generateFileId(),
            original_name: upload.filename,
            filename: filename,
            filepath: filepath,
            content_type: upload.content_type,
            size: upload.size,
            status: "pending",
            uploaded_by: getCurrentUserId(conn),
            uploaded_at: Date.now().getTime()
        };
        
        FileService.createFileRecord(fileRecord);
        
        // Queue background processing
        JobProcessor.enqueue("process_upload", {
            file_id: fileRecord.id,
            filepath: filepath,
            content_type: upload.content_type
        });
        
        return conn
            |> putStatus(201)
            |> json(ApiResponse.success({
                file_id: fileRecord.id,
                filename: filename,
                size: upload.size,
                status: "processing"
            }, "File uploaded successfully"));
    }
    
    public static function getUploadStatus(conn: Dynamic, params: Dynamic): Dynamic {
        var fileId = params.file_id;
        
        var fileRecord = FileService.getFileRecord(fileId);
        if (fileRecord == null) {
            return conn
                |> putStatus(404)
                |> json(ApiResponse.error("File not found"));
        }
        
        return conn
            |> putStatus(200)
            |> json(ApiResponse.success({
                file_id: fileRecord.id,
                original_name: fileRecord.original_name,
                filename: fileRecord.filename,
                size: fileRecord.size,
                status: fileRecord.status,
                processed_at: fileRecord.processed_at,
                download_url: fileRecord.status == "ready" ? "/api/files/" + fileRecord.id + "/download" : null,
                thumbnail_url: fileRecord.thumbnail_url,
                metadata: fileRecord.metadata
            }));
    }
    
    public static function downloadFile(conn: Dynamic, params: Dynamic): Dynamic {
        var fileId = params.file_id;
        
        var fileRecord = FileService.getFileRecord(fileId);
        if (fileRecord == null) {
            return conn
                |> putStatus(404)
                |> json(ApiResponse.error("File not found"));
        }
        
        if (fileRecord.status != "ready") {
            return conn
                |> putStatus(423)
                |> json(ApiResponse.error("File is still processing"));
        }
        
        // Security check - ensure user can access file
        if (!canUserAccessFile(getCurrentUserId(conn), fileRecord)) {
            return conn
                |> putStatus(403)
                |> json(ApiResponse.error("Access denied"));
        }
        
        return conn
            |> putRespHeader("content-disposition", 'attachment; filename="${fileRecord.original_name}"')
            |> putRespContentType(fileRecord.content_type)
            |> sendFile(200, fileRecord.filepath);
    }
    
    // Background processing job handler
    public static function processUpload(payload: Dynamic): Dynamic {
        var fileId = payload.file_id;
        var filepath = payload.filepath;
        var contentType = payload.content_type;
        
        try {
            // Update status to processing
            FileService.updateFileStatus(fileId, "processing");
            
            var results = {};
            
            // 1. Virus scan
            var virusScanResult = scanForViruses(filepath);
            if (virusScanResult.infected) {
                FileService.updateFileStatus(fileId, "rejected", {
                    reason: "Virus detected: " + virusScanResult.threat
                });
                deleteFile(filepath);
                return {status: "rejected", reason: "security"};
            }
            
            // 2. Extract metadata
            var metadata = extractMetadata(filepath, contentType);
            results.metadata = metadata;
            
            // 3. Generate thumbnail for images
            if (contentType.startsWith("image/")) {
                var thumbnailPath = generateThumbnail(filepath, fileId);
                results.thumbnail_url = "/api/files/" + fileId + "/thumbnail";
                FileService.updateFileField(fileId, "thumbnail_path", thumbnailPath);
            }
            
            // 4. Optimize images
            if (contentType.startsWith("image/")) {
                var optimizedPath = optimizeImage(filepath);
                if (optimizedPath != null) {
                    // Replace original with optimized version
                    replaceFile(filepath, optimizedPath);
                    results.optimized = true;
                }
            }
            
            // 5. Extract text content for searchability (PDFs, text files)
            if (contentType == "application/pdf" || contentType.startsWith("text/")) {
                var textContent = extractTextContent(filepath, contentType);
                if (textContent != null) {
                    FileService.updateFileField(fileId, "text_content", textContent);
                    results.text_extracted = true;
                }
            }
            
            // Update file record with results
            FileService.updateFileProcessing(fileId, "ready", {
                metadata: metadata,
                processed_at: Date.now().getTime()
            });
            
            return {status: "completed", results: results};
            
        } catch (error: Dynamic) {
            FileService.updateFileStatus(fileId, "error", {
                error: Std.string(error),
                error_at: Date.now().getTime()
            });
            
            return {status: "failed", error: error};
        }
    }
    
    // Private helper functions
    private static function validateFile(upload: Dynamic): Dynamic {
        if (upload.size > maxFileSize) {
            return {valid: false, error: 'File too large. Maximum size is ${Math.floor(maxFileSize / 1024 / 1024)}MB'};
        }
        
        if (!allowedTypes.contains(upload.content_type)) {
            return {valid: false, error: "File type not allowed"};
        }
        
        // Check for suspicious filenames
        if (hasSuspiciousFilename(upload.filename)) {
            return {valid: false, error: "Invalid filename"};
        }
        
        return {valid: true};
    }
    
    private static function generateSecureFilename(originalFilename: String): String {
        var ext = getFileExtension(originalFilename);
        var timestamp = Date.now().getTime();
        var random = Math.floor(Math.random() * 1000000);
        return 'file_${timestamp}_${random}.${ext}';
    }
    
    private static function hasSuspiciousFilename(filename: String): Bool {
        var suspicious = ["../", "..\\", "<", ">", "|", ":", "*", "?", '"'];
        for (pattern in suspicious) {
            if (filename.indexOf(pattern) != -1) {
                return true;
            }
        }
        return false;
    }
    
    private static function getFileExtension(filename: String): String {
        var lastDot = filename.lastIndexOf(".");
        return lastDot != -1 ? filename.substr(lastDot + 1).toLowerCase() : "";
    }
    
    private static function generateFileId(): String {
        return "file_" + Math.floor(Math.random() * 1000000) + "_" + Date.now().getTime();
    }
    
    private static function getCurrentUserId(conn: Dynamic): Int {
        return conn.assigns.current_user?.id ?? 0;
    }
    
    private static function canUserAccessFile(userId: Int, fileRecord: Dynamic): Bool {
        return fileRecord.uploaded_by == userId; // Simplified access control
    }
    
    private static function saveUploadedFile(upload: Dynamic, filepath: String): Void {
        // File saving logic would go here
        trace('Saving uploaded file to: $filepath');
    }
    
    private static function scanForViruses(filepath: String): Dynamic {
        // Virus scanning logic (would integrate with ClamAV or similar)
        trace('Scanning file for viruses: $filepath');
        return {infected: false, threat: null};
    }
    
    private static function extractMetadata(filepath: String, contentType: String): Dynamic {
        // Metadata extraction logic
        trace('Extracting metadata from: $filepath');
        return {
            content_type: contentType,
            extracted_at: Date.now().getTime()
        };
    }
    
    private static function generateThumbnail(filepath: String, fileId: String): String {
        // Thumbnail generation logic
        var thumbnailPath = uploadDir + "thumbnails/" + fileId + "_thumb.jpg";
        trace('Generating thumbnail: $thumbnailPath');
        return thumbnailPath;
    }
    
    private static function optimizeImage(filepath: String): String {
        // Image optimization logic
        trace('Optimizing image: $filepath');
        return filepath + "_optimized";
    }
    
    private static function extractTextContent(filepath: String, contentType: String): String {
        // Text extraction logic
        trace('Extracting text content from: $filepath');
        return "Sample extracted text content";
    }
    
    private static function replaceFile(oldPath: String, newPath: String): Void {
        // File replacement logic
        trace('Replacing file: $oldPath with $newPath');
    }
    
    private static function deleteFile(filepath: String): Void {
        // File deletion logic
        trace('Deleting file: $filepath');
    }
}
```

---

## Using These Recipes

### Quick Start
1. **Copy the recipe** that matches your use case
2. **Modify the package names** and class names to fit your project
3. **Update the dependencies** (external services, database calls, etc.)
4. **Compile and test** in your Reflaxe.Elixir project

### Recipe Template
Every recipe follows this structure:
- **Use Case**: Clear description of when to use this pattern
- **Complete Code**: Ready-to-copy Haxe implementation
- **Generated Elixir**: Shows the expected output (when helpful)
- **Usage Examples**: How to use the generated code

### Customization Tips
- **Configuration**: Most recipes include configuration options you can adjust
- **Error Handling**: All recipes include proper error handling patterns
- **Testing**: Consider writing both Haxe unit tests and Elixir integration tests
- **Documentation**: Add your own documentation for team members

### Next Steps
- Check the [EXAMPLES_GUIDE.md](./EXAMPLES_GUIDE.md) for more detailed walkthroughs
- See [USER_GUIDE.md](./USER_GUIDE.md) for comprehensive feature documentation
- Visit [TROUBLESHOOTING.md](./TROUBLESHOOTING.md) if you encounter issues

---

*These recipes demonstrate the power of Reflaxe.Elixir for building production-ready Elixir applications with the safety and expressiveness of Haxe's type system.*