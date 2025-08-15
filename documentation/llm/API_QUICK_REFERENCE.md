# Reflaxe.Elixir API Quick Reference

*Auto-generated from compiler - Always up-to-date*

Last Updated: 2025-08-12 20:58:31

## Table of Contents

- [Annotations](#annotations)
- [Core Classes](#core-classes)
- [Phoenix Integration](#phoenix-integration)
- [Ecto Integration](#ecto-integration)
- [OTP Patterns](#otp-patterns)
- [Type Mappings](#type-mappings)

## Annotations

| Annotation | Purpose | Example |
|------------|---------|---------||
| `@:module` | Define Elixir module | `@:module class MyModule` |
| `@:liveview` | Phoenix LiveView | `@:liveview class MyLive` |
| `@:schema` | Ecto schema | `@:schema class User` |
| `@:changeset` | Ecto changeset | `@:changeset function` |
| `@:genserver` | GenServer | `@:genserver class Worker` |
| `@:supervisor` | Supervisor | `@:supervisor class MySup` |
| `@:migration` | Ecto migration | `@:migration class AddUsers` |
| `@:template` | Phoenix template | `@:template class MyView` |
| `@:query` | Ecto query | `@:query function` |
| `@:router` | Phoenix router | `@:router class Router` |
| `@:controller` | Phoenix controller | `@:controller class UserController` |

## Core Classes

### Phoenix.Socket
```haxe
class Socket {
    function assign(assigns:Dynamic):Socket;
    function push_event(event:String, payload:Dynamic):Socket;
    function put_flash(kind:String, msg:String):Socket;
}
```

### Ecto.Repo
```haxe
class Repo {
    static function get(schema:Class<Dynamic>, id:Int):Dynamic;
    static function insert(changeset:Dynamic):Dynamic;
    static function update(changeset:Dynamic):Dynamic;
    static function delete(struct:Dynamic):Dynamic;
    static function all(query:Dynamic):Array<Dynamic>;
}
```

## Type Mappings

| Haxe Type | Elixir Type | Notes |
|-----------|-------------|-------|
| `Int` | `integer()` | |
| `Float` | `float()` | |
| `String` | `String.t()` | Binary string |
| `Bool` | `boolean()` | |
| `Array<T>` | `list(T)` | |
| `Map<K,V>` | `%{K => V}` | |
| `Dynamic` | `any()` | |
| `Null<T>` | `T \| nil` | Nullable |
| Class | Module | With @:module |
| Enum | Module with atoms | |

