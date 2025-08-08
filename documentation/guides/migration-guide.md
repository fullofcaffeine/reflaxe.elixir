# Gradual Migration Guide

This guide walks you through migrating an existing Phoenix application to use Reflaxe.Elixir gradually, allowing you to adopt Haxe benefits without rewriting your entire application.

## 🎯 Migration Philosophy

Reflaxe.Elixir is designed for **gradual adoption**:

- ✅ **Start Small** - Migrate individual modules one at a time
- ✅ **Maintain Compatibility** - Existing Elixir code continues working
- ✅ **Incremental Benefits** - Get type safety and tooling improvements immediately
- ✅ **Risk Mitigation** - No big-bang rewrites required

## 📋 Migration Checklist

### Phase 1: Project Setup (30 minutes)

- [ ] Install Haxe and Reflaxe.Elixir
- [ ] Configure Mix compilation
- [ ] Add VS Code support
- [ ] Verify basic compilation

### Phase 2: First Module Migration (1-2 hours)

- [ ] Choose low-risk utility module
- [ ] Convert to @:module syntax
- [ ] Add type annotations
- [ ] Test integration with existing code

### Phase 3: Template Migration (2-4 hours)

- [ ] Convert simple templates to HXX
- [ ] Migrate LiveView templates
- [ ] Add LiveView directives
- [ ] Test user interactions

### Phase 4: Business Logic Migration (ongoing)

- [ ] Migrate core business modules
- [ ] Add Ecto query macros
- [ ] Implement Phoenix contexts
- [ ] Add comprehensive testing

## 🚀 Step-by-Step Migration

### Step 1: Environment Setup

First, add Reflaxe.Elixir to your existing Phoenix project:

```elixir
# mix.exs
defp deps do
  [
    # Your existing dependencies
    {:phoenix, "~> 1.7.0"},
    {:phoenix_live_view, "~> 0.20.0"},
    
    # Add Haxe support
    {:haxe_compiler, "~> 0.1.0"}
  ]
end

def project do
  [
    # ...
    compilers: [:haxe] ++ Mix.compilers(),
    # ...
  ]
end
```

Create `haxe_build.json`:

```json
{
  "targets": ["elixir"],
  "output": "lib/",
  "sources": ["lib/"],
  "libraries": ["reflaxe-elixir"],
  "defines": ["reflaxe_runtime"]
}
```

### Step 2: Choose Your First Module

**Best candidates for first migration:**

✅ **Utility modules** - Pure functions, minimal dependencies  
✅ **Data transformers** - Input validation, formatting  
✅ **Business logic** - Core domain functions  
✅ **Service modules** - Well-defined interfaces  

❌ **Avoid initially:**  
❌ Controllers (too many Phoenix dependencies)  
❌ Database modules (complex Ecto integration)  
❌ GenServers (OTP-specific patterns)  

**Example: Migrating a utility module**

**Before (Elixir):**
```elixir
# lib/my_app/text_utils.ex
defmodule MyApp.TextUtils do
  def slugify(text) when is_binary(text) do
    text
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9]+/, "-")
    |> String.trim("-")
  end
  
  def truncate(text, max_length) when is_binary(text) and is_integer(max_length) do
    if String.length(text) <= max_length do
      text
    else
      String.slice(text, 0, max_length - 3) <> "..."
    end
  end
  
  defp clean_whitespace(text) do
    String.replace(text, ~r/\s+/, " ")
  end
end
```

**After (Haxe):**
```haxe
// lib/my_app/text_utils.hx
package lib.my_app;

@:module
class TextUtils {
    
    /**
     * Convert text to URL-friendly slug
     */
    function slugify(text: String): String {
        return text
               |> toLowerCase()
               |> replaceNonAlphanumeric()
               |> trimHyphens();
    }
    
    /**
     * Truncate text with ellipsis if too long
     */
    function truncate(text: String, maxLength: Int): String {
        if (text.length <= maxLength) {
            return text;
        } else {
            return text.substr(0, maxLength - 3) + "...";
        }
    }
    
    @:private
    function cleanWhitespace(text: String): String {
        // Private function - generates defp in Elixir
        return text; // Simplified for example
    }
}
```

### Step 3: Gradual Interface Migration

Create **bridge modules** that allow gradual migration:

**Bridge Pattern Example:**

```elixir
# lib/my_app/user_service.ex (Elixir bridge)
defmodule MyApp.UserService do
  # Delegate to Haxe implementation
  defdelegate create_user(attrs), to: MyApp.UserServiceHx, as: :create_user
  defdelegate find_by_email(email), to: MyApp.UserServiceHx, as: :find_by_email
  
  # Keep complex Elixir-specific code in Elixir for now
  def send_welcome_email(user) do
    # Complex email logic stays in Elixir during migration
    MyApp.Mailer.send_welcome(user)
  end
end
```

```haxe
// lib/my_app/user_service_hx.hx
package lib.my_app;

@:module
class UserServiceHx {
    
    function createUser(attrs: Dynamic): Dynamic {
        return attrs
               |> validateUserAttrs()
               |> buildUser()
               |> saveUser();
    }
    
    function findByEmail(email: String): Dynamic {
        // Type-safe query (will be enhanced in Phase 4)
        return User.where("email = ?", email).first();
    }
    
    @:private
    function validateUserAttrs(attrs: Dynamic): Dynamic {
        // Validation logic with type safety
        return attrs;
    }
}
```

### Step 4: Template Migration Strategy

**Convert templates gradually:**

**Phase 4a: Simple templates first**

```elixir
<!-- Before: templates/user/show.html.heex -->
<div class="user-profile">
  <h1><%= @user.name %></h1>
  <p><%= @user.email %></p>
  <%= if @user.active do %>
    <span class="badge active">Active</span>
  <% else %>
    <span class="badge inactive">Inactive</span>
  <% end %>
</div>
```

```haxe
// After: templates/user/show.hxx
<div className="user-profile">
  <h1>{user.name}</h1>
  <p>{user.email}</p>
  <span className={user.active ? "badge active" : "badge inactive"}>
    {user.active ? "Active" : "Inactive"}
  </span>
</div>
```

**Phase 4b: LiveView templates**

```elixir
<!-- Before: LiveView template -->
<div class="user-list">
  <%= for user <- @users do %>
    <div class="user-item" phx-click="select_user" phx-value-id="<%= user.id %>">
      <h3><%= user.name %></h3>
      <p><%= user.email %></p>
    </div>
  <% end %>
</div>
```

```haxe
// After: HXX LiveView template  
<div className="user-list">
  {users.map(user => 
    <div className="user-item" onClick="select_user" data-id={user.id}>
      <h3>{user.name}</h3>
      <p>{user.email}</p>
    </div>
  )}
</div>
```

### Step 5: LiveView Migration

**Convert LiveViews systematically:**

**Before (Elixir LiveView):**
```elixir
defmodule MyAppWeb.UserLiveView do
  use MyAppWeb, :live_view
  
  def mount(_params, _session, socket) do
    {:ok, assign(socket, users: [], loading: false)}
  end
  
  def handle_event("search", %{"query" => query}, socket) do
    users = MyApp.UserService.search_users(query)
    {:noreply, assign(socket, users: users)}
  end
  
  def render(assigns) do
    ~H"""
    <div class="user-search">
      <!-- Template content -->
    </div>
    """
  end
end
```

**After (Haxe LiveView):**
```haxe
package lib.my_app_web;

@:liveview
class UserLiveView {
    
    function mount(params: Dynamic, session: Dynamic, socket: Dynamic): Dynamic {
        return socket
               |> assign("users", [])
               |> assign("loading", false);
    }
    
    function handleEvent(event: String, params: Dynamic, socket: Dynamic): Dynamic {
        return switch (event) {
            case "search":
                var users = UserService.searchUsers(params.query);
                socket |> assign("users", users);
            case _:
                socket;
        };
    }
    
    function render(): String {
        return hxx('<div className="user-search">
          <SearchInput onSearch="search" />
          <UserList users={users} />
        </div>');
    }
}
```

## 🧪 Testing During Migration

### Testing Strategy

**1. Parallel Testing**
Run both Elixir and Haxe versions during migration:

```elixir
# test/user_service_test.exs
defmodule MyApp.UserServiceTest do
  use MyApp.DataCase
  
  describe "user creation" do
    test "creates user with valid attributes" do
      attrs = %{name: "John Doe", email: "john@example.com"}
      
      # Test both implementations
      elixir_result = MyApp.UserService.create_user(attrs)
      haxe_result = MyApp.UserServiceHx.create_user(attrs)
      
      assert elixir_result.name == haxe_result.name
      assert elixir_result.email == haxe_result.email
    end
  end
end
```

**2. Integration Testing**
Ensure Haxe modules work with existing Elixir code:

```elixir
test "haxe module integrates with existing phoenix controller" do
  # Test that Haxe-generated functions work in Phoenix controllers
  conn = build_conn()
         |> get(Routes.user_path(conn, :index))
  
  assert html_response(conn, 200) =~ "Users"
end
```

### Migration Validation

**Create migration validation tests:**

```haxe
// test/migration/MigrationValidationTest.hx
class MigrationValidationTest {
    
    public static function validateModuleMigration(): Bool {
        // Test that migrated modules have same behavior as original
        var originalResult = OriginalElixirModule.process("test");
        var migratedResult = MigratedHaxeModule.process("test");
        
        return originalResult == migratedResult;
    }
}
```

## 📊 Migration Metrics

**Track your migration progress:**

### Code Migration Metrics
- **Lines of Code**: Haxe vs Elixir ratio
- **Function Count**: Migrated functions / Total functions  
- **Test Coverage**: Maintain >80% during migration
- **Performance**: Compare compilation and runtime performance

### Quality Metrics  
- **Type Safety**: % of functions with type annotations
- **Documentation**: % of functions with documentation
- **Static Analysis**: Zero warnings target
- **Integration**: All existing tests pass

### Example Migration Dashboard

```
Migration Progress: 45%

📊 Modules Migrated: 12/27 (44%)
   ✅ Utils: 5/5 (100%)
   🚧 Services: 4/8 (50%) 
   ⏳ Controllers: 0/7 (0%)
   ⏳ LiveViews: 3/7 (43%)

🧪 Test Coverage: 87% (↑2% from baseline)
⚡ Performance: 15% improvement in compilation
🔧 Type Safety: 78% functions typed
⚠️ Issues: 2 remaining integration warnings
```

## 🚨 Common Migration Pitfalls

### 1. **Big Bang Migration**
❌ **Don't**: Attempt to migrate entire application at once  
✅ **Do**: Migrate one module at a time with thorough testing

### 2. **Ignoring Integration Points**
❌ **Don't**: Focus only on individual modules  
✅ **Do**: Test how Haxe modules integrate with existing Elixir code

### 3. **Skipping Type Annotations**
❌ **Don't**: Migrate without adding proper types  
✅ **Do**: Add comprehensive type annotations for maximum benefit

### 4. **Template Migration Timing**
❌ **Don't**: Migrate templates before LiveViews are ready  
✅ **Do**: Migrate backend logic first, then templates

### 5. **Testing Shortcuts**
❌ **Don't**: Reduce test coverage during migration  
✅ **Do**: Maintain or improve test coverage throughout migration

## 🎉 Migration Success Criteria

Your migration is successful when:

- [ ] **All existing functionality preserved**
- [ ] **Test suite passes with >80% coverage**  
- [ ] **Performance maintained or improved**
- [ ] **Zero compilation warnings**
- [ ] **Team productivity maintained**
- [ ] **Code quality metrics improved**
- [ ] **Documentation updated**

## 📞 Getting Help

**Migration Support Resources:**

- 📖 **Documentation**: Complete guides and API reference
- 💬 **Community**: Discord server for real-time help
- 🐛 **Issues**: GitHub issues for bugs and feature requests
- 📧 **Support**: Email support for enterprise users

**Migration Consulting Available:**
- Expert guidance for complex migrations
- Custom tooling and automation
- Training and team onboarding
- Performance optimization

---

**Next Steps**: Once you've completed your first module migration, proceed to [Advanced Phoenix Integration](./phoenix-integration.md) for deeper Phoenix-specific features.