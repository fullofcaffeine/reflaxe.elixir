# Reflaxe.Elixir Best Practices

*Extracted from successful example projects*

## Project Structure

```
project/
├── src_haxe/          # Haxe source files
│   ├── schemas/       # Ecto schemas
│   ├── live/          # LiveView components
│   ├── controllers/   # Phoenix controllers
│   └── services/      # Business logic
├── lib/               # Generated Elixir
├── build.hxml         # Haxe build config
└── mix.exs            # Mix project file
```

## Common Patterns

### 1. LiveView Component
```haxe
@:liveview
class ProductLive {
    public static function mount(params, session, socket) {
        var products = ProductService.list();
        return socket.assign({
            products: products,
            loading: false
        });
    }
    
    public static function handle_event("search", params, socket) {
        var results = ProductService.search(params.query);
        return socket.assign(products: results);
    }
}
```

### 2. Ecto Schema with Changeset
```haxe
@:schema
class User {
    public var id:Int;
    public var email:String;
    public var name:String;
    
    @:changeset
    public static function changeset(user, attrs) {
        return user
            .cast(attrs, ["email", "name"])
            .validate_required(["email"])
            .validate_format("email", ~/^[^@]+@[^@]+$/);
    }
}
```

### 3. GenServer Worker
```haxe
@:genserver
class EmailWorker {
    public static function init(args) {
        return {ok: {queue: []}};
    }
    
    public static function handle_cast({send: email}, state) {
        EmailService.deliver(email);
        return {noreply: state};
    }
}
```

