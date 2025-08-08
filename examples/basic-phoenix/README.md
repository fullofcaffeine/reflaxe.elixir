# Basic Phoenix Integration Example

This example demonstrates how to integrate Reflaxe.Elixir into a Phoenix application, showcasing core features like @:module syntax, clean Elixir generation, and basic Phoenix patterns.

## 🎯 What You'll Learn

- Setting up Reflaxe.Elixir in a Phoenix project
- Using @:module syntax sugar for clean code
- Pipe operator usage within modules
- Basic Phoenix controller integration
- Simple HXX template usage

## 🏗️ Project Structure

```
basic-phoenix/
├── lib/
│   ├── my_app/
│   │   ├── user_service.hx          # @:module service class
│   │   ├── text_utils.hx            # Utility functions
│   │   └── math_helper.hx           # Mathematical operations
│   └── my_app_web/
│       ├── controllers/
│       │   └── user_controller.hx   # Phoenix controller
│       └── live/
│           └── user_live.hx         # LiveView module
├── test/
│   ├── my_app/
│   │   └── user_service_test.exs
│   └── integration/
│       └── basic_phoenix_test.hx
├── mix.exs                          # Phoenix project configuration
├── haxe_build.json                 # Haxe compilation config
└── README.md
```

## 🚀 Getting Started

### 1. Prerequisites
- Elixir 1.14+
- Phoenix 1.7+
- Haxe 4.3.6+
- Reflaxe.Elixir

### 2. Setup
```bash
# Clone and setup
cd examples/basic-phoenix
mix deps.get
mix compile

# Start the application
mix phx.server
```

Visit `http://localhost:4000` to see the application.

## 📝 Code Examples

### User Service (@:module syntax)

```haxe
// lib/my_app/user_service.hx
package lib.my_app;

@:module
class UserService {
    
    /**
     * Create user with validation pipeline
     */
    function createUser(name: String, email: String): Dynamic {
        return {name: name, email: email}
               |> validateUserData()
               |> formatUserData()
               |> saveUser();
    }
    
    /**
     * Find users by email pattern
     */
    function findByEmailPattern(pattern: String): Array<Dynamic> {
        return pattern
               |> validatePattern()
               |> buildSearchQuery()
               |> executeQuery();
    }
    
    @:private
    function validateUserData(userData: Dynamic): Dynamic {
        // Private function - generates defp in Elixir
        if (userData.name == null || userData.name == "") {
            throw "Name is required";
        }
        if (userData.email == null || !isValidEmail(userData.email)) {
            throw "Valid email is required";
        }
        return userData;
    }
    
    @:private
    function isValidEmail(email: String): Bool {
        return email.indexOf("@") > 0 && email.indexOf(".") > 0;
    }
}
```

**Generated Elixir:**
```elixir
defmodule MyApp.UserService do
  @doc "Create user with validation pipeline"
  @spec create_user(String.t(), String.t()) :: any()
  def create_user(name, email) do
    %{name: name, email: email}
    |> validate_user_data()
    |> format_user_data()  
    |> save_user()
  end
  
  @doc "Find users by email pattern"  
  @spec find_by_email_pattern(String.t()) :: list(any())
  def find_by_email_pattern(pattern) do
    pattern
    |> validate_pattern()
    |> build_search_query()
    |> execute_query()
  end
  
  defp validate_user_data(user_data) do
    # Private function implementation
    user_data
  end
  
  defp is_valid_email(email) do
    # Email validation implementation
    String.contains?(email, "@") and String.contains?(email, ".")
  end
end
```

### Phoenix Controller Integration

```haxe
// lib/my_app_web/controllers/user_controller.hx
package lib.my_app_web.controllers;

@:module 
class UserController {
    
    /**
     * List all users with search functionality
     */
    function index(conn: Dynamic, params: Dynamic): Dynamic {
        var users = if (params.search != null) {
            UserService.findByEmailPattern(params.search);
        } else {
            UserService.getAllUsers();
        };
        
        return conn
               |> assign("users", users)
               |> assign("search", params.search)
               |> render("index");
    }
    
    /**
     * Create new user
     */
    function create(conn: Dynamic, params: Dynamic): Dynamic {
        var userParams = params.user;
        
        return userParams
               |> UserService.createUser(userParams.name, userParams.email)
               |> handleUserCreation(conn);
    }
    
    @:private
    function handleUserCreation(result: Dynamic, conn: Dynamic): Dynamic {
        if (result.success) {
            return conn
                   |> putFlash("info", "User created successfully")
                   |> redirect("/users");
        } else {
            return conn
                   |> putFlash("error", result.error)
                   |> render("new");
        }
    }
}
```

### Utility Module

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
               |> replaceSpaces("_")
               |> removeSpecialChars()
               |> trimUnderscores();
    }
    
    /**
     * Truncate text with ellipsis
     */
    function truncate(text: String, maxLength: Int): String {
        if (text.length <= maxLength) {
            return text;
        }
        return text.substring(0, maxLength - 3) + "...";
    }
    
    /**
     * Capitalize first letter of each word
     */
    function titleCase(text: String): String {
        return text
               |> splitWords()
               |> capitalizeWords()
               |> joinWords();
    }
    
    @:private
    function toLowerCase(text: String): String {
        return text.toLowerCase();
    }
    
    @:private
    function replaceSpaces(text: String, replacement: String): String {
        return text.split(" ").join(replacement);
    }
}
```

## 🧪 Testing

### Integration Test
```haxe
// test/integration/basic_phoenix_test.hx
package integration;

class BasicPhoenixTest {
    
    public static function testUserServiceIntegration(): Bool {
        try {
            // Test user creation pipeline
            var result = UserService.createUser("John Doe", "john@example.com");
            
            return result != null && 
                   result.name == "John Doe" && 
                   result.email == "john@example.com";
        } catch (e: Dynamic) {
            trace("User service integration error: " + e);
            return false;
        }
    }
    
    public static function testTextUtilsIntegration(): Bool {
        try {
            var slug = TextUtils.slugify("Hello World");
            var truncated = TextUtils.truncate("This is a long text", 10);
            var titled = TextUtils.titleCase("hello world");
            
            return slug == "hello_world" &&
                   truncated == "This is..." &&
                   titled == "Hello World";
        } catch (e: Dynamic) {
            trace("Text utils integration error: " + e);
            return false;
        }
    }
    
    public static function main(): Void {
        trace("🧪 Basic Phoenix Integration Tests");
        
        var tests = [
            testUserServiceIntegration,
            testTextUtilsIntegration
        ];
        
        var testNames = [
            "User Service Integration",
            "Text Utils Integration"
        ];
        
        var passed = 0;
        for (i in 0...tests.length) {
            if (tests[i]()) {
                trace('✅ PASS: ${testNames[i]}');
                passed++;
            } else {
                trace('❌ FAIL: ${testNames[i]}');
            }
        }
        
        trace('Results: ${passed}/${tests.length} tests passing');
    }
}
```

### Elixir Integration Test
```elixir
# test/my_app/user_service_test.exs
defmodule MyApp.UserServiceTest do
  use ExUnit.Case
  
  describe "user creation" do
    test "creates user with valid data" do
      # Test Haxe-generated function from Elixir
      result = MyApp.UserService.create_user("John Doe", "john@example.com")
      
      assert result.name == "John Doe"
      assert result.email == "john@example.com"
    end
    
    test "validates email format" do
      assert_raise RuntimeError, fn ->
        MyApp.UserService.create_user("John", "invalid-email")
      end
    end
  end
  
  describe "search functionality" do
    test "finds users by email pattern" do
      users = MyApp.UserService.find_by_email_pattern("@example.com")
      assert is_list(users)
    end
  end
end
```

## 📊 Performance Benchmarks

```bash
# Run performance tests
haxe test/performance/BasicPhoenixBenchmarks.hxml
```

**Expected Results:**
- Module compilation: <5ms
- Template processing: <10ms  
- End-to-end pipeline: <15ms

## 🔧 Configuration Files

### mix.exs
```elixir
defmodule MyApp.MixProject do
  use Mix.Project

  def project do
    [
      app: :my_app,
      version: "0.1.0",
      elixir: "~> 1.14",
      compilers: [:haxe] ++ Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      mod: {MyApp.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  defp deps do
    [
      {:phoenix, "~> 1.7.0"},
      {:phoenix_live_view, "~> 0.20.0"},
      {:haxe_compiler, "~> 0.1.0"}
    ]
  end
end
```

### haxe_build.json
```json
{
  "targets": ["elixir"],
  "output": "lib/",
  "sources": ["lib/"],
  "libraries": ["reflaxe-elixir"],
  "defines": ["reflaxe_runtime"],
  "performance": {
    "compilation_target_ms": 15,
    "template_processing_target_ms": 100
  }
}
```

## 🎉 Key Takeaways

After completing this example, you should understand:

1. **@:module Syntax** - How to write clean Elixir modules without boilerplate
2. **Pipe Operators** - Using |> for functional programming patterns
3. **Private Functions** - @:private annotation for defp generation
4. **Phoenix Integration** - How Haxe modules work with Phoenix controllers
5. **Testing Strategy** - Both Haxe and Elixir testing approaches
6. **Performance** - Expected compilation and runtime performance

## 📚 Next Steps

- Try the [User Management Example](../user-management/) for more advanced features
- Explore [HXX Templates](../user-management/) for reactive UI components
- Learn about [Migration Strategies](../migration/) for existing projects

## 💡 Tips and Best Practices

1. **Start Simple** - Begin with utility modules and services
2. **Use Types** - Add type annotations for better tooling and safety
3. **Test Integration** - Verify Haxe modules work with existing Elixir code
4. **Monitor Performance** - Use benchmarks to ensure targets are met
5. **Follow Conventions** - Maintain Phoenix and Elixir naming conventions

---

**Happy coding with Reflaxe.Elixir!** 🚀