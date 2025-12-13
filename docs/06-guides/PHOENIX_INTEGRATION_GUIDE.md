# Phoenix Integration Guide

This guide covers how to integrate Reflaxe.Elixir with Phoenix Framework to build type-safe web applications with LiveView, Ecto, and real-time features.

> 💡 **Quick Start**: See [examples/03-phoenix-app](../examples/03-phoenix-app/), [examples/06-user-management](../examples/06-user-management/), and [examples/09-phoenix-router](../examples/09-phoenix-router/) for working Phoenix applications.

> 📚 **Related Guides**: 
> - [COOKBOOK.md](./COOKBOOK.md) - Ready-to-use Phoenix recipes
> - [EXAMPLES_GUIDE.md](./EXAMPLES_GUIDE.md) - Step-by-step example walkthroughs

## Table of Contents
- [Creating a Phoenix Project](#creating-a-phoenix-project)
- [Application Setup](#application-setup)
- [Controllers and Routes](#controllers-and-routes)
- [LiveView Components](#liveview-components)
- [HXX Templates](#hxx-templates)
- [Ecto Schemas and Queries](#ecto-schemas-and-queries)
- [Changesets and Validation](#changesets-and-validation)
- [Channels and PubSub](#channels-and-pubsub)
- [Authentication](#authentication)
- [Testing Phoenix Applications](#testing-phoenix-applications)
- [Deployment](#deployment)

## Creating a Phoenix Project

### Option 1: Start from Example

The fastest way is to copy and modify an existing example:

```bash
# Copy a complete Phoenix example
cp -r examples/03-phoenix-app my-phoenix-app
cd my-phoenix-app

# Install dependencies
mix deps.get

# Compile Haxe source to Elixir
npx haxe build.hxml

# Start Phoenix server
mix phx.server
```

### Option 2: New Phoenix Project with Haxe

Create a Phoenix project and add Haxe support:

```bash
# Create standard Phoenix project
mix phx.new my_phoenix_app
cd my_phoenix_app

# Add Haxe source directory
mkdir -p src_haxe/phoenix

# Create build.hxml
echo "-cp src_haxe" > build.hxml
echo "-lib reflaxe.elixir" >> build.hxml
echo "-D reflaxe_runtime" >> build.hxml
echo "-D elixir_output=lib" >> build.hxml
echo "phoenix.Application" >> build.hxml
```

This creates a Phoenix project with:
- `src_haxe/` - Haxe source files for controllers, LiveViews, schemas
- `lib/` - Generated Elixir code (compiled from Haxe)
- `build.hxml` - Haxe compilation configuration
- Standard Phoenix directories (assets, config, priv, test)

## Application Setup

### Basic Phoenix Application

Create a simple Phoenix application entry point:

```haxe
// src_haxe/phoenix/Application.hx
package phoenix;

/**
 * Phoenix Application entry point compiled from Haxe
 * Based on examples/03-phoenix-app/src_haxe/phoenix/Application.hx
 */
class Application {
    public static function main() {
        trace("Phoenix Haxe Example starting...");
    }
    
    /**
     * Application callback for Phoenix startup
     */
    public static function start(type: String, args: Array<Dynamic>): {status: String, pid: Dynamic} {
        var children = [
            // Add your supervised processes here
            // Example: {UserServer, []}
        ];
        
        var opts = ["strategy" => "one_for_one", "name" => "PhoenixHaxeExample.Supervisor"];
        
        // In real implementation, this would call Supervisor.start_link
        return {status: "ok", pid: null};
    }
}
```

**Generated Elixir**:
```elixir
defmodule Phoenix.Application do
  def start(type, args) do
    children = [
      # Add your supervised processes here
    ]
    
    opts = [strategy: :one_for_one, name: PhoenixHaxeExample.Supervisor]
    {:ok, pid} = Supervisor.start_link(children, opts)
  end
end
```

## Controllers and Routes

### Creating a Controller

Based on examples/09-phoenix-router, create a simple controller with @:controller annotation:

```haxe
// src_haxe/controllers/UserController.hx
package controllers;

/**
 * Phoenix controller with @:route annotations
 * Based on examples/09-phoenix-router/src_haxe/controllers/UserController.hx
 */
@:controller
class UserController {
    
    @:route({method: "GET", path: "/users"})
    public function index(): String {
        return "List all users";
    }
    
    @:route({method: "GET", path: "/users/:id"})
    public function show(id: Int): String {
        return "Show user " + id;
    }
    
    @:route({method: "POST", path: "/users"})
    public function create(user: Dynamic): String {
        return "Create new user";
    }
    
    @:route({method: "PUT", path: "/users/:id"})
    public function update(id: Int, user: Dynamic): String {
        return "Update user " + id;
    }
    
    @:route({method: "DELETE", path: "/users/:id"})
    public function delete(id: Int): String {
        return "Delete user " + id;
    }
    
    public static function main() {
        trace("Phoenix Router DSL Example - User Controller");
    }
}
    
    /**
     * GET /products/:id
     */
    public static function show(conn: Conn, params: {id: String}): Conn {
        var product = Catalog.getProduct(params.id);
        
        return switch (product) {
            case Some(p):
                conn
                    .assign("product", p)
                    .render("show.html");
            case None:
                conn
                    .putStatus(404)
                    .putView(ErrorView)
                    .render("404.html");
        };
    }
    
    /**
     * POST /products
     */
    public static function create(conn: Conn, params: {product: ProductParams}): Conn {
        var result = Catalog.createProduct(params.product);
        
        return switch (result) {
            case Ok(product):
                conn
                    .putFlash("info", "Product created successfully")
                    .redirect(to: Routes.productPath(conn, "show", product));
                    
            case Error(changeset):
                conn
                    .assign("changeset", changeset)
                    .render("new.html");
        };
    }
    
    /**
     * PUT /products/:id
     */
    public static function update(conn: Conn, params: {id: String, product: ProductParams}): Conn {
        var existing = Catalog.getProduct(params.id);
        
        return switch (existing) {
            case Some(product):
                var result = Catalog.updateProduct(product, params.product);
                handleUpdateResult(conn, result);
                
            case None:
                conn.sendResp(404, "Not found");
        };
    }
    
    /**
     * DELETE /products/:id
     */
    public static function delete(conn: Conn, params: {id: String}): Conn {
        var product = Catalog.getProduct(params.id);
        
        switch (product) {
            case Some(p):
                Catalog.deleteProduct(p);
                conn
                    .putFlash("info", "Product deleted")
                    .redirect(to: Routes.productPath(conn, "index"));
                    
            case None:
                conn.sendResp(404, "Not found");
        }
    }
}

typedef ProductParams = {
    name: String,
    price: Float,
    description: String,
    ?categoryId: Int
}
```

### Router Configuration

Based on examples/09-phoenix-router, create a simple router:

```haxe
// src_haxe/AppRouter.hx
package;

/**
 * Main Phoenix router configuration
 * Based on examples/09-phoenix-router/src_haxe/AppRouter.hx
 */
@:router
class AppRouter {
    
    @:pipeline("browser", ["fetch_session", "protect_from_forgery"])
    @:pipeline("api", ["accept_json"])
    
    @:include_controller("UserController")
    @:include_controller("ProductController")
    
    // Router configuration is automatically generated
    // from controller @:route annotations
    public static function main() {
        trace("Phoenix Router DSL Example - App Router");
    }
}
```

## LiveView Components

### Basic LiveView with Counter

Based on examples/03-phoenix-app, here's a simple LiveView:

```haxe
// src_haxe/phoenix/Application.hx (CounterLive class)
@:liveview
class CounterLive {
    var count = 0;
    
    function mount(_params: Dynamic, _session: Dynamic, socket: Dynamic): {status: String, socket: Dynamic} {
        return {status: "ok", socket: assign(socket, "count", count)};
    }
    
    function handle_event(event: String, params: Dynamic, socket: Dynamic): {status: String, socket: Dynamic} {
        switch(event) {
            case "increment":
                count++;
                return {status: "noreply", socket: assign(socket, "count", count)};
            case "decrement":
                count--;
                return {status: "noreply", socket: assign(socket, "count", count)};
            default:
                return {status: "noreply", socket: socket};
        }
    }
    
    function render(assigns: Dynamic): String {
        return '
        <div>
            <h1>Counter: <%= @count %></h1>
            <button phx-click="increment">+</button>
            <button phx-click="decrement">-</button>
        </div>';
    }
    
    static function assign(socket: Dynamic, key: String, value: Dynamic): Dynamic {
        // This would be implemented by the Reflaxe.Elixir compiler
        return socket;
    }
}
    
    // Handle events from the client
    public function handleEvent(event: String, params: Dynamic, socket: Socket): Socket {
        return switch (event) {
            case "search":
                performSearch(params.query, socket);
                
            case "sort":
                updateSort(params.field, socket);
                
            case "select_product":
                selectProduct(params.id, socket);
                
            case "update_product":
                updateProduct(params, socket);
                
            default:
                socket;
        };
    }
    
    // Handle messages from other processes
    public function handleInfo(message: Dynamic, socket: Socket): Socket {
        return switch (message) {
            case {:product_updated, product}:
                updateProductInList(product, socket);
                
            case {:product_deleted, id}:
                removeProductFromList(id, socket);
                
            default:
                socket;
        };
    }
    
    // Private helper functions
    private function performSearch(query: String, socket: Socket): Socket {
        var products = Catalog.searchProducts(query);
        
        return socket
            .assign("products", products)
            .assign("searchQuery", query);
    }
    
    private function updateSort(field: String, socket: Socket): Socket {
        var products = sortProducts(socket.assigns.products, field);
        
        return socket
            .assign("products", products)
            .assign("sortBy", field);
    }
    
    private function selectProduct(id: String, socket: Socket): Socket {
        var product = Catalog.getProduct(id);
        
        return socket.assign("selectedProduct", product);
    }
}
```

### Advanced LiveView with User Management

Based on examples/06-user-management, here's a comprehensive LiveView:

```haxe
// src_haxe/live/UserLive.hx
package live;

import contexts.Users;
import contexts.Users.User;

// Import HXX function for template processing
import HXX.*;

/**
 * Phoenix LiveView for user management
 * Based on examples/06-user-management/src_haxe/live/UserLive.hx
 */
@:liveview
class UserLive {
    var users: Array<User> = [];
    var selectedUser: Null<User> = null;
    var changeset: Dynamic = null;
    var searchTerm: String = "";
    var showForm: Bool = false;
    
    function mount(_params: Dynamic, _session: Dynamic, socket: Dynamic): {status: String, socket: Dynamic} {
        users = Users.list_users();
        
        return {
            status: "ok", 
            socket: assign_multiple(socket, {
                users: users,
                selectedUser: null,
                changeset: Users.change_user(null),
                searchTerm: "",
                showForm: false
            })
        };
    }
    
    function handle_event(event: String, params: Dynamic, socket: Dynamic): {status: String, socket: Dynamic} {
        return switch(event) {
            case "new_user":
                handleNewUser(params, socket);
                
            case "edit_user":
                handleEditUser(params, socket);
                
            case "save_user":
                handleSaveUser(params, socket);
                
            case "search":
                handleSearch(params, socket);
                
            default:
                {status: "noreply", socket: socket};
        };
    }
    
    function handleSearch(params: Dynamic, socket: Dynamic): {status: String, socket: Dynamic} {
        searchTerm = params.search;
        
        users = searchTerm.length > 0 
            ? Users.search_users(searchTerm)
            : Users.list_users();
            
        return {
            status: "noreply",
            socket: assign_multiple(socket, {
                users: users,
                searchTerm: searchTerm
            })
        };
    }
}
```

## HXX Templates

### Template Processing with HXX

Reflaxe.Elixir supports HXX templates for generating HTML. Based on examples/06-user-management:

```haxe
// src_haxe/HXX.hx  
package;

/**
 * HXX template processing for Phoenix templates
 * Based on examples/06-user-management/src_haxe/HXX.hx
 */
class HXX {
    /**
     * Main HXX template processing function
     * Converts HXX syntax to Phoenix.HTML output
     */
    public static function hxx(template: String): String {
        // Template processing logic
        // Converts {variable} to <%= @variable %>
        // Handles control flow like {if condition}
        return processTemplate(template);
    }
    
    private static function processTemplate(template: String): String {
        // Simplified template processing
        var result = template;
        
        // Replace {variable} with <%= @variable %>
        result = result.replace(~/{([^}]+)}/g, "<%= @$1 %>");
        
        // Handle conditionals {if condition} ... {/if}
        result = result.replace(~/{if\s+([^}]+)}([\s\S]*?){/if}/g, 
            "<%= if @$1 do %>$2<% end %>");
            
        // Handle loops {for item in items} ... {/for}
        result = result.replace(~/{for\s+([^}]+)}([\s\S]*?){/for}/g,
            "<%= for $1 do %>$2<% end %>");
            
        return result;
    }
    
    public static function main(): Void {
        trace("HXX template processor compiled successfully!");
    }
}
```

### Using HXX in LiveView

```haxe
function render(assigns: Dynamic): String {
    return hxx('
    <div class="user-management">
        <div class="header">
            <h1>User Management</h1>
            <.button phx-click="new_user" class="btn-primary">
                <.icon name="plus" /> New User
            </.button>
        </div>
        
        <div class="search-bar">
            <.form phx-change="search">
                <.input 
                    name="search" 
                    value={@searchTerm}
                    placeholder="Search users..."
                    type="search"
                />
            </.form>
        </div>
        
        {if @showForm}
            <div class="user-form">
                <!-- User form content -->
            </div>
        {/if}
    </div>
    ');
}
```

### LiveView with Forms

Create `src_haxe/live/UserFormLive.hx`:

```haxe
package live;

import phoenix.LiveView;
import phoenix.Socket;
import schemas.Product;
import changesets.ProductChangeset;

@:liveview
class ProductFormLive {
    public function mount(params: {?id: String}, session: Dynamic, socket: Socket): Socket {
        var product = params.id != null 
            ? Catalog.getProduct(params.id)
            : Product.new();
            
        var changeset = ProductChangeset.change(product);
        
        return socket
            .assign({
                product: product,
                changeset: changeset,
                action: params.id != null ? "edit" : "new"
            });
    }
    
    public function handleEvent("validate", params: {product: Dynamic}, socket: Socket): Socket {
        var changeset = socket.assigns.product
            |> ProductChangeset.change(params.product)
            |> ElixirMap.put("action", "validate");
            
        return socket.assign("changeset", changeset);
    }
    
    public function handleEvent("save", params: {product: Dynamic}, socket: Socket): Socket {
        var result = saveProduct(socket.assigns.product, params.product);
        
        return switch (result) {
            case {:ok, product}:
                socket
                    .putFlash("info", "Product saved successfully")
                    .redirect(to: Routes.productPath(socket, "show", product));
                    
            case {:error, changeset}:
                socket.assign("changeset", changeset);
        };
    }
    
    private function saveProduct(product: Product, params: Dynamic): Dynamic {
        return socket.assigns.action == "new"
            ? Catalog.createProduct(params)
            : Catalog.updateProduct(product, params);
    }
}
```

## Ecto Schemas and Queries

### Defining Schemas

Based on examples/06-user-management, here's how to define Ecto schemas:

```haxe
// src_haxe/contexts/Users.hx
package contexts;

/**
 * Complete user management context with Ecto integration
 * Based on examples/06-user-management/src_haxe/contexts/Users.hx
 */

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
```

Create a more complex product schema:

```haxe
// src_haxe/schemas/Product.hx

```haxe
package schemas;

import ecto.Schema;
import ecto.Query;
import ecto.Changeset;

@:schema("products")
class Product {
    public var id: Int;
    public var name: String;
    public var description: String;
    public var price: Float;
    public var stock: Int;
    public var categoryId: Int;
    public var active: Bool = true;
    
    // Associations
    @:belongsTo("categories")
    public var category: Category;
    
    @:hasMany("reviews")
    public var reviews: Array<Review>;
    
    // Virtual fields
    @:virtual
    public var averageRating: Float;
    
    // Timestamps  
    @:timestamps
    public var insertedAt: String;
    public var updatedAt: String;
}
```

### Query Building

Create `src_haxe/contexts/Catalog.hx`:

```haxe
package contexts;

import ecto.Query;
import ecto.Repo;
import schemas.Product;

@:module
class Catalog {
    /**
     * List all active products with preloaded associations
     */
    public static function listProducts(): Array<Product> {
        return Query.from(p in Product)
            .where(p.active == true)
            .preload([:category, :reviews])
            .orderBy([desc: p.insertedAt])
            .all();
    }
    
    /**
     * Search products by name or description
     */
    public static function searchProducts(query: String): Array<Product> {
        var searchTerm = '%$query%';
        
        return Query.from(p in Product)
            .where(p.active == true)
            .where(like(p.name, searchTerm) || like(p.description, searchTerm))
            .orderBy([asc: p.name])
            .all();
    }
    
    /**
     * Get products in price range
     */
    public static function getProductsInPriceRange(min: Float, max: Float): Array<Product> {
        return Query.from(p in Product)
            .where(p.price >= min && p.price <= max)
            .where(p.stock > 0)
            .all();
    }
    
    /**
     * Complex query with joins and aggregations
     */
    public static function getProductStats(categoryId: Int): ProductStats {
        return Query.from(p in Product)
            .join(:inner, [p], c in Category, on: p.categoryId == c.id)
            .where([p, c], c.id == categoryId)
            .groupBy([c], c.id)
            .select([p, c], %{
                category: c.name,
                totalProducts: count(p.id),
                averagePrice: avg(p.price),
                totalStock: sum(p.stock),
                minPrice: min(p.price),
                maxPrice: max(p.price)
            })
            .one();
    }
    
    /**
     * Batch update with Ecto.Multi
     */
    public static function batchUpdatePrices(percentage: Float): Result<BatchResult, String> {
        var multi = Multi.new()
            .updateAll("increase_prices", 
                Query.from(p in Product).where(p.active == true),
                [inc: [price: p.price * percentage]]
            )
            .run("log_update", function(repo, changes) {
                AuditLog.log("Price update", changes);
                {:ok, changes};
            });
            
        return Repo.transaction(multi);
    }
}

typedef ProductStats = {
    category: String,
    totalProducts: Int,
    averagePrice: Float,
    totalStock: Int,
    minPrice: Float,
    maxPrice: Float
}
```

## Changesets and Validation

### User Context and Operations

Based on examples/06-user-management, here's the complete user context:

```haxe
class Users {
    /**
     * Create changeset for user (required by LiveView example)
     */
    public static function change_user(?user: User): Dynamic {
        // Would create Ecto changeset - simplified for compilation
        return {valid: true};
    }
    
    /**
     * Get all users with optional filtering
     */
    public static function list_users(?filter: UserFilter): Array<User> {
        // Query DSL implementation will be handled by future @:query annotation
        return [];
    }
    
    /**
     * Create a new user
     */
    public static function create_user(attrs: Dynamic): {status: String, ?user: User, ?changeset: Dynamic} {
        var changeset = UserChangeset.changeset(null, attrs);
        
        if (changeset != null) {
            // Would call Repo.insert
            return {status: "ok", user: null};
        } else {
            return {status: "error", changeset: changeset};
        }
    }
    
    /**
     * Search users by name or email
     */
    public static function search_users(term: String): Array<User> {
        // Query DSL implementation will be handled by future @:query annotation
        return [];
    }
}

@:changeset
class UserChangeset {
    @:validate_required(["name", "email"])
    @:validate_format("email", "email_regex")
    @:validate_length("name", {min: 2, max: 100})
    @:validate_number("age", {greater_than: 0, less_than: 150})
    public static function changeset(user: User, attrs: Dynamic): Dynamic {
        // Changeset pipeline will be generated
        return null;
    }
}

// Supporting types from the example
typedef UserFilter = {
    ?active: Bool,
    ?minAge: Int,
    ?maxAge: Int
}

typedef UserStats = {
    total: Int,
    active: Int,
    inactive: Int
}
```

### Advanced Product Changesets

For more complex validation scenarios:

```haxe
package changesets;

import ecto.Changeset;
import schemas.Product;

@:changeset
class ProductChangeset {
    static var REQUIRED_FIELDS = ["name", "price", "stock"];
    static var OPTIONAL_FIELDS = ["description", "categoryId", "active"];
    
    public static function change(product: Product, ?attrs: Dynamic): Changeset {
        return product
            |> cast(attrs, REQUIRED_FIELDS ++ OPTIONAL_FIELDS)
            |> validateRequired(REQUIRED_FIELDS)
            |> validateLength("name", min: 3, max: 100)
            |> validateLength("description", max: 1000)
            |> validateNumber("price", greaterThan: 0)
            |> validateNumber("stock", greaterThanOrEqualTo: 0)
            |> validateInclusion("categoryId", getCategoryIds())
            |> uniqueConstraint("name")
            |> prepareChanges(function(changeset) {
                // Custom preparation logic
                if (changeset.changes.price != null) {
                    putChange(changeset, "priceWithTax", 
                        changeset.changes.price * 1.1);
                }
                return changeset;
            });
    }
    
    public static function validateDiscount(changeset: Changeset, maxDiscount: Float): Changeset {
        return validateChange(changeset, "price", function(field, value) {
            var original = getField(changeset, field);
            var discount = (original - value) / original;
            
            if (discount > maxDiscount) {
                addError(changeset, field, 
                    'Discount cannot exceed ${maxDiscount * 100}%');
            }
        });
    }
    
    private static function getCategoryIds(): Array<Int> {
        return Query.from(c in Category)
            .select([c], c.id)
            .all();
    }
}
```

    
    <div class="sort-controls">
        <button phx-click="sort" phx-value-field="name" 
                class={sortBy == "name" ? "active" : ""}>
            Name
        </button>
        <button phx-click="sort" phx-value-field="price"
                class={sortBy == "price" ? "active" : ""}>
            Price
        </button>
    </div>
    
    <div class="products-grid">
        {for product in products}
            <div class="product-card" phx-click="select_product" phx-value-id={product.id}>
                <img src={product.imageUrl} alt={product.name} />
                <h3>{product.name}</h3>
                <p class="price">${product.price}</p>
                <p class="stock">
                    {if product.stock > 0}
                        <span class="in-stock">In Stock ({product.stock})</span>
                    {else}
                        <span class="out-of-stock">Out of Stock</span>
                    {/if}
                </p>
            </div>
        {/for}
    </div>
    
    {if selectedProduct != null}
        <div class="product-modal" phx-click-away="close_modal">
            <ProductDetails product={selectedProduct} />
        </div>
    {/if}
</div>
```

### Form Template

Create `src_haxe/templates/ProductForm.hxx`:

```hxx
<.form let={f} for={changeset} phx-change="validate" phx-submit="save">
    <div class="form-group">
        <label for="name">Product Name</label>
        <input type="text" 
               id="name" 
               name="product[name]" 
               value={f.data.name}
               class={errorClass(f, "name")} />
        <.error field={f["name"]} />
    </div>
    
    <div class="form-group">
        <label for="price">Price</label>
        <input type="number" 
               id="price" 
               name="product[price]" 
               value={f.data.price}
               step="0.01"
               class={errorClass(f, "price")} />
        <.error field={f["price"]} />
    </div>
    
    <div class="form-group">
        <label for="category">Category</label>
        <select id="category" name="product[categoryId]">
            <option value="">Select a category</option>
            {for category in categories}
                <option value={category.id} 
                        selected={f.data.categoryId == category.id}>
                    {category.name}
                </option>
            {/for}
        </select>
        <.error field={f["categoryId"]} />
    </div>
    
    <div class="form-group">
        <label for="description">Description</label>
        <textarea id="description" 
                  name="product[description]"
                  rows="5">{f.data.description}</textarea>
        <.error field={f["description"]} />
    </div>
    
    <div class="form-actions">
        <button type="submit" disabled={!changeset.valid}>
            {action == "new" ? "Create Product" : "Update Product"}
        </button>
        <.link navigate={Routes.productPath(@socket, :index)}>Cancel</.link>
    </div>
</.form>
```

## Channels and PubSub

### Channel Implementation

Create `src_haxe/channels/ProductChannel.hx`:

```haxe
package channels;

import phoenix.Channel;
import phoenix.Socket;
import phoenix.PubSub;

@:channel("products:*")
class ProductChannel {
    public function join(topic: String, params: Dynamic, socket: Socket): JoinResult {
        var productId = topic.split(":")[1];
        
        if (authorized(params.token, productId)) {
            // Subscribe to product updates
            PubSub.subscribe("product_updates:" + productId);
            
            return {:ok, socket};
        } else {
            return {:error, %{reason: "unauthorized"}};
        }
    }
    
    public function handleIn("update_stock", payload: {stock: Int}, socket: Socket): Dynamic {
        var productId = socket.topic.split(":")[1];
        var product = Catalog.getProduct(productId);
        
        switch (product) {
            case Some(p):
                var result = Catalog.updateStock(p, payload.stock);
                broadcast(socket, "stock_updated", %{
                    productId: productId,
                    newStock: payload.stock
                });
                return {:reply, {:ok, %{message: "Stock updated"}}, socket};
                
            case None:
                return {:reply, {:error, %{message: "Product not found"}}, socket};
        }
    }
    
    public function handleIn("bid", payload: {amount: Float}, socket: Socket): Dynamic {
        var productId = socket.topic.split(":")[1];
        
        // Validate bid
        if (payload.amount <= 0) {
            return {:reply, {:error, %{message: "Invalid bid amount"}}, socket};
        }
        
        // Process bid
        var result = AuctionServer.placeBid(productId, socket.userId, payload.amount);
        
        switch (result) {
            case {:ok, bid}:
                broadcastFrom(socket, "new_bid", %{
                    userId: socket.userId,
                    amount: payload.amount,
                    timestamp: Date.now()
                });
                return {:reply, {:ok, bid}, socket};
                
            case {:error, reason}:
                return {:reply, {:error, %{message: reason}}, socket};
        }
    }
    
    private function authorized(token: String, productId: String): Bool {
        // Implement authorization logic
        return TokenAuth.verify(token);
    }
}
```

### PubSub Usage

Create `src_haxe/services/NotificationService.hx`:

```haxe
package services;

import phoenix.PubSub;

@:module
class NotificationService {
    static var PUBSUB_NAME = "my_app_pubsub";
    
    public static function notifyProductUpdate(product: Product): Void {
        PubSub.broadcast(
            PUBSUB_NAME,
            'product_updates:${product.id}',
            {:product_updated, product}
        );
    }
    
    public static function notifyPriceChange(product: Product, oldPrice: Float): Void {
        PubSub.broadcast(
            PUBSUB_NAME,
            "price_alerts",
            {
                type: "price_change",
                productId: product.id,
                productName: product.name,
                oldPrice: oldPrice,
                newPrice: product.price,
                changePercent: ((product.price - oldPrice) / oldPrice) * 100
            }
        );
    }
    
    public static function subscribeToProduct(productId: Int): Void {
        PubSub.subscribe(PUBSUB_NAME, 'product_updates:$productId');
    }
    
    public static function subscribeToPriceAlerts(): Void {
        PubSub.subscribe(PUBSUB_NAME, "price_alerts");
    }
}
```

## Authentication

### Authentication Context

Create `src_haxe/contexts/Auth.hx`:

```haxe
package contexts;

import schemas.User;
import phoenix.Token;
import comeonin.Bcrypt;

@:module
class Auth {
    static var TOKEN_SALT = "user auth";
    static var TOKEN_MAX_AGE = 86400; // 24 hours
    
    public static function authenticate(email: String, password: String): Result<User, String> {
        var user = getUserByEmail(email);
        
        return switch (user) {
            case Some(u) if Bcrypt.checkPass(password, u.hashedPassword):
                Ok(u);
            case _:
                Error("Invalid email or password");
        };
    }
    
    public static function createUser(params: UserParams): Result<User, Changeset> {
        var changeset = User.new()
            |> UserChangeset.registration(params)
            |> putPasswordHash();
            
        return Repo.insert(changeset);
    }
    
    public static function generateToken(user: User): String {
        return Token.sign(MyAppWeb.Endpoint, TOKEN_SALT, user.id);
    }
    
    public static function verifyToken(token: String): Result<User, String> {
        var result = Token.verify(
            MyAppWeb.Endpoint, 
            TOKEN_SALT, 
            token,
            maxAge: TOKEN_MAX_AGE
        );
        
        return switch (result) {
            case {:ok, userId}:
                var user = Repo.get(User, userId);
                user != null ? Ok(user) : Error("User not found");
                
            case {:error, reason}:
                Error(Std.string(reason));
        };
    }
    
    private static function putPasswordHash(changeset: Changeset): Changeset {
        return switch (changeset.valid) {
            case true:
                var password = getChange(changeset, "password");
                putChange(changeset, "hashedPassword", 
                    Bcrypt.hashPwdSalt(password));
                    
            case false:
                changeset;
        };
    }
}

typedef UserParams = {
    email: String,
    password: String,
    passwordConfirmation: String,
    ?name: String
}
```

### Authentication Plug

Create `src_haxe/plugs/AuthPlug.hx`:

```haxe
package plugs;

import phoenix.Conn;
import phoenix.Controller;
import contexts.Auth;

@:plug
class AuthPlug {
    public static function init(opts: Dynamic): Dynamic {
        return opts;
    }
    
    public static function call(conn: Conn, _opts: Dynamic): Conn {
        var userId = getSession(conn, "user_id");
        
        if (userId != null) {
            var user = Repo.get(User, userId);
            if (user != null) {
                return assignCurrentUser(conn, user);
            }
        }
        
        return conn;
    }
    
    public static function requireAuthenticated(conn: Conn, _opts: Dynamic): Conn {
        if (conn.assigns.currentUser != null) {
            return conn;
        } else {
            return conn
                |> putFlash("error", "You must be logged in to access that page")
                |> redirect(to: Routes.sessionPath(conn, "new"))
                |> halt();
        }
    }
    
    private static function assignCurrentUser(conn: Conn, user: User): Conn {
        return conn
            |> assign("currentUser", user)
            |> assign("userSignedIn", true);
    }
}
```

## Testing Phoenix Applications

### Controller Tests

Create `test/controllers/product_controller_test.exs`:

```elixir
defmodule MyAppWeb.ProductControllerTest do
  use MyAppWeb.ConnCase
  
  describe "index" do
    test "lists all products", %{conn: conn} do
      product1 = insert(:product, name: "Product 1")
      product2 = insert(:product, name: "Product 2")
      
      conn = get(conn, Routes.product_path(conn, :index))
      
      assert html_response(conn, 200) =~ "Products"
      assert html_response(conn, 200) =~ product1.name
      assert html_response(conn, 200) =~ product2.name
    end
  end
  
  describe "create product" do
    test "creates product with valid data", %{conn: conn} do
      valid_attrs = %{
        name: "New Product",
        price: 99.99,
        description: "A great product"
      }
      
      conn = post(conn, Routes.product_path(conn, :create), product: valid_attrs)
      
      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == Routes.product_path(conn, :show, id)
      
      conn = get(conn, Routes.product_path(conn, :show, id))
      assert html_response(conn, 200) =~ "New Product"
    end
    
    test "renders errors with invalid data", %{conn: conn} do
      invalid_attrs = %{name: nil, price: -10}
      
      conn = post(conn, Routes.product_path(conn, :create), product: invalid_attrs)
      
      assert html_response(conn, 200) =~ "can't be blank"
      assert html_response(conn, 200) =~ "must be greater than 0"
    end
  end
end
```

### LiveView Tests

Create `test/live/product_live_test.exs`:

```elixir
defmodule MyAppWeb.ProductLiveTest do
  use MyAppWeb.ConnCase
  import Phoenix.LiveViewTest
  
  test "displays products", %{conn: conn} do
    product = insert(:product, name: "Test Product")
    
    {:ok, view, html} = live(conn, "/products")
    
    assert html =~ "Products"
    assert html =~ product.name
  end
  
  test "searches products", %{conn: conn} do
    product1 = insert(:product, name: "Apple")
    product2 = insert(:product, name: "Banana")
    
    {:ok, view, _html} = live(conn, "/products")
    
    # Perform search
    html = view
           |> form(".search-bar form", %{query: "Apple"})
           |> render_change()
    
    assert html =~ "Apple"
    refute html =~ "Banana"
  end
  
  test "updates product in real-time", %{conn: conn} do
    product = insert(:product, name: "Original Name")
    
    {:ok, view, _html} = live(conn, "/products")
    
    # Simulate product update from another process
    send(view.pid, {:product_updated, %{product | name: "Updated Name"}})
    
    assert render(view) =~ "Updated Name"
    refute render(view) =~ "Original Name"
  end
end
```

## Deployment

### Release Configuration

Update `mix.exs`:

```elixir
def project do
  [
    # ...
    releases: [
      my_app: [
        include_executables_for: [:unix],
        applications: [runtime_tools: :permanent]
      ]
    ]
  ]
end
```

### Docker Deployment

Create `Dockerfile`:

```dockerfile
# Build stage
FROM elixir:1.14-alpine AS build

# Install build dependencies
RUN apk add --no-cache build-base npm git

# Install Haxe
RUN npm install -g lix
RUN lix install haxe 4.3.6

# Prepare build dir
WORKDIR /app

# Install hex + rebar
RUN mix local.hex --force && \
    mix local.rebar --force

# Set build ENV
ENV MIX_ENV=prod

# Install mix dependencies
COPY mix.exs mix.lock ./
COPY config config
RUN mix do deps.get, deps.compile

# Install npm dependencies
COPY package.json package-lock.json ./
RUN npm ci --only=production

# Copy Haxe source and compile
COPY src_haxe src_haxe
COPY build.hxml ./
RUN npx haxe build.hxml

# Build assets
COPY assets/package.json assets/package-lock.json ./assets/
RUN npm --prefix ./assets ci --only=production

COPY priv priv
COPY assets assets
RUN npm run --prefix ./assets deploy
RUN mix phx.digest

# Compile Elixir
COPY lib lib
RUN mix do compile, release

# Runtime stage
FROM alpine:3.16 AS runtime

RUN apk add --no-cache openssl ncurses-libs

WORKDIR /app

RUN chown nobody:nobody /app

USER nobody:nobody

COPY --from=build --chown=nobody:nobody /app/_build/prod/rel/my_app ./

ENV HOME=/app

CMD ["bin/my_app", "start"]
```

### Production Configuration

Create `config/runtime.exs`:

```elixir
import Config

if config_env() == :prod do
  database_url =
    System.get_env("DATABASE_URL") ||
      raise "DATABASE_URL environment variable is missing"
      
  config :my_app, MyApp.Repo,
    url: database_url,
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10"),
    ssl: true,
    ssl_opts: [verify: :verify_none]
    
  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise "SECRET_KEY_BASE environment variable is missing"
      
  config :my_app, MyAppWeb.Endpoint,
    http: [
      port: String.to_integer(System.get_env("PORT") || "4000"),
      transport_options: [socket_opts: [:inet6]]
    ],
    secret_key_base: secret_key_base,
    server: true
end
```

## Best Practices

### 1. Type Safety
- Always define types for function parameters and returns
- Use typedefs for complex data structures
- Leverage Haxe's type inference where appropriate

### 2. Error Handling
- Use Result types for operations that can fail
- Pattern match on results explicitly
- Provide meaningful error messages

### 3. Performance
- Preload associations to avoid N+1 queries
- Use database indexes on frequently queried fields
- Leverage LiveView's optimized diff algorithm

### 4. Testing
- Write controller tests for HTTP endpoints
- Write LiveView tests for real-time features
- Test channels for WebSocket functionality
- Use factories for test data generation

### 5. Security
- Always validate and sanitize user input
- Use changesets for data validation
- Implement proper authentication and authorization
- Use CSRF tokens for forms
- Sanitize HTML output to prevent XSS

## Resources

- [Phoenix Framework Documentation](https://hexdocs.pm/phoenix)
- [LiveView Documentation](https://hexdocs.pm/phoenix_live_view)
- [Ecto Documentation](https://hexdocs.pm/ecto)
- [Reflaxe.Elixir Examples](../examples/)
  - [examples/03-phoenix-app](../examples/03-phoenix-app/) - Basic Phoenix application
  - [examples/06-user-management](../examples/06-user-management/) - LiveView with CRUD
  - [examples/09-phoenix-router](../examples/09-phoenix-router/) - Router configuration
- [COOKBOOK.md](./COOKBOOK.md) - Ready-to-use Phoenix recipes
- [EXAMPLES_GUIDE.md](./EXAMPLES_GUIDE.md) - Step-by-step walkthroughs

## Summary

This guide covered:
- ✅ Setting up Phoenix with Reflaxe.Elixir
- ✅ Creating controllers and routes
- ✅ Building LiveView components
- ✅ Working with Ecto schemas and queries
- ✅ Implementing changesets and validation
- ✅ Using HXX templates
- ✅ Real-time features with Channels and PubSub
- ✅ Authentication and authorization
- ✅ Testing Phoenix applications
- ✅ Deployment strategies

You now have the knowledge to build full-featured Phoenix applications with the type safety and tooling of Haxe!
