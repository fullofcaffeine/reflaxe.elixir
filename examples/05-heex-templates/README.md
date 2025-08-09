# HEEx Templates from Haxe

This example demonstrates how to write Phoenix HEEx templates using Haxe with type-safe template compilation.

## Features

- **Type-Safe Templates**: Compile-time validation of template structure and data
- **HEEx Syntax**: Full support for Phoenix's HEEx template syntax  
- **Component Integration**: Works with Phoenix.Component and LiveView
- **Form Helpers**: Integration with Phoenix.HTML.Form helpers
- **Template Functions**: Reusable template components and partials

## Quick Start

```bash
cd examples/05-heex-templates

# Compile Haxe templates to HEEx
npx haxe build.hxml
```

## Template Examples

### User Profile Template

**Haxe Source:**
```haxe
@:template("user_profile.html.heex")
class UserProfile {
    public static function render(assigns: UserAssigns): String {
        return hxx('
        <div class="user-profile">
            <h1>Welcome, ${assigns.user.name}!</h1>
            <span class="${assigns.user.active ? "online" : "offline"}">
                ${assigns.user.active ? "Online" : "Offline"}
            </span>
        </div>
        ');
    }
}
```

**Generated HEEx:**
```heex
<div class="user-profile">
  <h1>Welcome, <%= @user.name %>!</h1>
  <span class={@user.active && "online" || "offline"}>
    <%= if @user.active, do: "Online", else: "Offline" %>
  </span>
</div>
```

### Form Components

**Phoenix Form Integration:**
```haxe
<.form for={@changeset} phx-submit="save">
  <.input field={@changeset[:name]} type="text" required />
  <.error field={@changeset[:name]} />
  
  <.button type="submit" disabled={!@changeset.valid?}>
    Save Changes  
  </.button>
</.form>
```

## Type Safety Features

### Compile-Time Validation
```haxe
typedef UserAssigns = {
    user: User,
    posts: Array<Post>
}

// Compile error if template tries to access non-existent fields
assigns.user.invalidField // ❌ Compilation error
assigns.user.name        // ✅ Type-safe access
```

### Template Functions
```haxe
static function renderPost(post: Post): String {
    return hxx('<div class="post">${post.title}</div>');
}

// Reusable across multiple templates
${posts.map(renderPost).join("")}
```

## Integration Patterns  

### With LiveView
```haxe
@:liveview
class UserLive {
    function render(assigns: Dynamic): String {
        return UserProfile.render(assigns);
    }
}
```

### With Phoenix Controllers
```elixir
def show(conn, %{"id" => id}) do
  user = Users.get_user!(id)
  assigns = %{user: user, posts: user.posts}
  
  render(conn, "show.html", assigns)
end
```

## Benefits

- **Type Safety**: Catch template errors at compile time
- **Code Reuse**: Share template logic across projects
- **Performance**: Compiled templates with minimal runtime overhead
- **Developer Experience**: IDE support with autocompletion and error highlighting

## Advanced Features

### Conditional Rendering
```haxe
${user.active ? renderActiveUser(user) : renderInactiveUser(user)}
```

### Component Composition
```haxe
static function userCard(user: User): String {
    return hxx('
    <div class="user-card">
        ${UserProfile.render({user: user, posts: []})}
        ${renderUserActions(user)}
    </div>
    ');
}
```

### Form Validation
```haxe
<.input field={@changeset[:email]} type="email" required />
<.error field={@changeset[:email]} />

// Generates proper Phoenix form helpers with validation
```