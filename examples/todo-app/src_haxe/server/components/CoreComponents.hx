package server.components;

import HXX;

/**
 * Type-safe assigns for Phoenix components
 */
typedef ComponentAssigns = {
    ?id: String,
    ?className: String,
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
    ?className: String,
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

/**
 * Type-safe abstract for Phoenix form targets
 * Compiles to the appropriate Elixir representation
 */
abstract FormTarget(String) {
    public function new(target: String) {
        this = target;
    }
    
    @:from public static function fromString(s: String): FormTarget {
        return new FormTarget(s);
    }
    
    @:to public function toString(): String {
        return this;
    }
}

typedef ErrorAssigns = {
    field: FormField
}

typedef FormAssigns = {
    formFor: FormTarget, // Changeset or schema
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

typedef TableRowData = Map<String, String>;

typedef TableAssigns = {
    rows: Array<TableRowData>,
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
    ?className: String
}

typedef LabelAssigns = {
    ?htmlFor: String,
    ?className: String,
    inner_content: String
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
@:keep
class CoreComponents {
    
    /**
     * Renders a modal dialog
     */
    @:component
    public static function modal(assigns: ModalAssigns): String {
        return HXX.hxx('<div id={@id} class="modal" phx-show={@show}>
            <%= @inner_content %>
        </div>');
    }
    
    /**
     * Renders a button component
     */
    @:component
    public static function button(assigns: ButtonAssigns): String {
        return HXX.hxx('<button type={@type || "button"} class={@className} disabled={@disabled}>
            <%= @inner_content %>
        </button>');
    }
    
    /**
     * Renders a form input field
     */
    @:component
    public static function input(assigns: InputAssigns): String {
        return HXX.hxx('<div class="form-group">
            <label for={@field.id}><%= @label %></label>
            <input 
                type={@type || "text"} 
                id={@field.id}
                name={@field.name}
                value={@field.value}
                placeholder={@placeholder}
                class="form-control"
                required={@required}
            />
            <%= if @field.errors && length(@field.errors) > 0 do %>
                <span class="error"><%= Enum.join(@field.errors, ", ") %></span>
            <% end %>
        </div>');
    }
    
    /**
     * Renders form error messages
     */
    @:component
    public static function error(assigns: ErrorAssigns): String {
        return HXX.hxx('<%= if @field && @field.errors && length(@field.errors) > 0 do %>
            <div class="error-message">
                <%= Enum.join(@field.errors, ", ") %>
            </div>
        <% end %>');
    }
    
    /**
     * Renders a simple form
     */
    @:component  
    public static function simple_form(assigns: FormAssigns): String {
        // Use `_f` to avoid unused variable warnings when slot variable is not referenced
        return HXX.hxx('<.form :let={_f} for={@formFor} action={@action} method={@method || "post"}>
            <%= @inner_content %>
        </.form>');
    }
    
    /**
     * Renders a header with title and actions
     */
    @:component
    public static function header(assigns: HeaderAssigns): String {
        return HXX.hxx('<header class="header">
            <h1><%= @title %></h1>
            <%= if @actions do %>
                <div class="actions">
                    <%= @actions %>
                </div>
            <% end %>
        </header>');
    }
    
    /**
     * Renders a data table
     */
    @:component
    public static function table(assigns: TableAssigns): String {
        return HXX.hxx('<table class="table">
            <thead>
                <tr>
                    <%= for col <- @columns do %>
                        <th><%= col.label %></th>
                    <% end %>
                </tr>
            </thead>
            <tbody>
                <%= for row <- @rows do %>
                    <tr>
                        <%= for col <- @columns do %>
                            <td><%= Map.get(row, col.field) %></td>
                        <% end %>
                    </tr>
                <% end %>
            </tbody>
        </table>');
    }
    
    /**
     * Renders a list of items
     */
    @:component
    public static function list(assigns: ListAssigns): String {
        return HXX.hxx('<ul class="list">
            <%= for item <- @items do %>
                <li><%= item %></li>
            <% end %>
        </ul>');
    }
    
    /**
     * Renders a back navigation link
     */
    @:component
    public static function back(assigns: BackAssigns): String {
        return HXX.hxx('<div class="back-link">
            <.link navigate={@navigate}>
                ← Back
            </.link>
        </div>');
    }
    
    /**
     * Renders an icon
     */
    @:component
    public static function icon(assigns: IconAssigns): String {
        return HXX.hxx('<%= if @className do %>
            <span class={"icon icon-" <> @name <> " " <> @className}></span>
        <% else %>
            <span class={"icon icon-" <> @name}></span>
        <% end %>');
    }
    
    /**
     * Renders a form label
     */
    @:component
    public static function label(assigns: LabelAssigns): String {
        return HXX.hxx('<%= if @htmlFor do %>
            <label for={@htmlFor} class={@className}><%= @inner_content %></label>
        <% else %>
            <label class={@className}><%= @inner_content %></label>
        <% end %>');
    }
}
