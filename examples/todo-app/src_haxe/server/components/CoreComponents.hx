package server.components;

/**
 * Type-safe assigns for Phoenix components
 */
typedef ComponentAssigns = {
    ?id: String,
    ?class: String,
    ?show: Bool,
    ?inner_content: String
}

typedef ModalAssigns = {
    id: String,
    show: Bool,
    ?inner_content: String
}

typedef ButtonAssigns = {
    ?type: String,
    ?class: String,
    ?disabled: Bool,
    inner_content: String
}

typedef InputAssigns = {
    field: FormField,
    ?type: String,
    label: String,
    ?placeholder: String,
    ?required: Bool
}

typedef FormField = {
    id: String,
    name: String,
    value: String,
    ?errors: Array<String>
}

typedef ErrorAssigns = {
    field: FormField
}

typedef FormAssigns = {
    for: Any, // This would be a changeset or schema
    action: String,
    ?method: String,
    inner_content: String
}

typedef HeaderAssigns = {
    title: String,
    ?actions: String
}

typedef TableColumn = {
    field: String,
    label: String
}

typedef TableAssigns = {
    rows: Array<Map<String, Any>>,
    columns: Array<TableColumn>
}

typedef ListAssigns = {
    items: Array<String>
}

typedef BackAssigns = {
    navigate: String
}

typedef IconAssigns = {
    name: String,
    ?class: String
}

/**
 * Core UI components for Phoenix applications
 * 
 * Provides reusable, type-safe UI components like modals, forms, buttons, etc.
 * These components follow Phoenix LiveView conventions and compile to proper
 * Phoenix.Component functions.
 */
@:native("TodoAppWeb.CoreComponents")
@:component
class CoreComponents {
    
    /**
     * Renders a modal dialog
     */
    @:component
    public static function modal(assigns: ModalAssigns): String {
        // The actual HEEx template would be handled by HXX compiler
        // For now, return a placeholder that the compiler will transform
        return '<div id={assigns.id} class="modal" phx-show={assigns.show}>
            <%= assigns.inner_content %>
        </div>';
    }
    
    /**
     * Renders a button component
     */
    @:component
    public static function button(assigns: ButtonAssigns): String {
        var type = assigns.type != null ? assigns.type : "button";
        var disabled = assigns.disabled != null && assigns.disabled ? "disabled" : "";
        return '<button type={type} class={assigns.class} {disabled}>
            <%= assigns.inner_content %>
        </button>';
    }
    
    /**
     * Renders a form input field
     */
    @:component
    public static function input(assigns: InputAssigns): String {
        var type = assigns.type != null ? assigns.type : "text";
        var required = assigns.required != null && assigns.required ? "required" : "";
        return '<div class="form-group">
            <label for={assigns.field.id}><%= assigns.label %></label>
            <input 
                type={type} 
                id={assigns.field.id}
                name={assigns.field.name}
                value={assigns.field.value}
                placeholder={assigns.placeholder}
                class="form-control"
                {required}
            />
            <%= if assigns.field.errors != null && assigns.field.errors.length > 0 do %>
                <span class="error"><%= Enum.join(assigns.field.errors, ", ") %></span>
            <% end %>
        </div>';
    }
    
    /**
     * Renders form error messages
     */
    @:component
    public static function error(assigns: ErrorAssigns): String {
        return '<%= if assigns.field != null && assigns.field.errors != null && assigns.field.errors.length > 0 do %>
            <div class="error-message">
                <%= Enum.join(assigns.field.errors, ", ") %>
            </div>
        <% end %>';
    }
    
    /**
     * Renders a simple form
     */
    @:component  
    public static function simpleForm(assigns: FormAssigns): String {
        var method = assigns.method != null ? assigns.method : "post";
        return '<.form :let={f} for={assigns.for} action={assigns.action} method={method}>
            <%= assigns.inner_content %>
        </.form>';
    }
    
    /**
     * Renders a header with title and actions
     */
    @:component
    public static function header(assigns: HeaderAssigns): String {
        return '<header class="header">
            <h1><%= assigns.title %></h1>
            <%= if assigns.actions != null do %>
                <div class="actions">
                    <%= assigns.actions %>
                </div>
            <% end %>
        </header>';
    }
    
    /**
     * Renders a data table
     */
    @:component
    public static function table(assigns: TableAssigns): String {
        return '<table class="table">
            <thead>
                <tr>
                    <%= for col <- assigns.columns do %>
                        <th><%= col.label %></th>
                    <% end %>
                </tr>
            </thead>
            <tbody>
                <%= for row <- assigns.rows do %>
                    <tr>
                        <%= for col <- assigns.columns do %>
                            <td><%= Map.get(row, col.field) %></td>
                        <% end %>
                    </tr>
                <% end %>
            </tbody>
        </table>';
    }
    
    /**
     * Renders a list of items
     */
    @:component
    public static function list(assigns: ListAssigns): String {
        return '<ul class="list">
            <%= for item <- assigns.items do %>
                <li><%= item %></li>
            <% end %>
        </ul>';
    }
    
    /**
     * Renders a back navigation link
     */
    @:component
    public static function back(assigns: BackAssigns): String {
        return '<div class="back-link">
            <.link navigate={assigns.navigate}>
                ← Back
            </.link>
        </div>';
    }
    
    /**
     * Renders an icon
     */
    @:component
    public static function icon(assigns: IconAssigns): String {
        var className = "icon icon-" + assigns.name;
        if (assigns.class != null) {
            className += " " + assigns.class;
        }
        return '<span class={className}></span>';
    }
}