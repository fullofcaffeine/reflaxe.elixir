# API Quick Reference

*Auto-generated from Reflaxe.Elixir compiler*

## Common Annotations

```haxe
@:module         // Define Elixir module
@:liveview       // Phoenix LiveView component
@:schema         // Ecto schema
@:changeset      // Ecto changeset
@:genserver      // GenServer behavior
@:template       // Phoenix template
@:migration      // Ecto migration
```

## Quick Examples

### LiveView Component
```haxe
@:liveview
class MyLive {
    public static function mount(params, session, socket) {
        return socket.assign(counter: 0);
    }
}
```

