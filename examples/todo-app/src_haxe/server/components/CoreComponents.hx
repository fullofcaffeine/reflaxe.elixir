package server.components;

import HXX;
import elixir.Enum;
import elixir.types.Term;
import phoenix.Component;
import phoenix.types.Slot;

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

typedef CardLet = {
    var title: String;
}

typedef CardActionAssigns = {
    var label: String;
    var navigate: String;
}

typedef CardAssigns = {
    var title: String;
    @:optional var className: String;
    @:slot @:optional var action: Slot<CardActionAssigns>;
    @:slot var inner_block: Slot<Term, CardLet>;
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
    static function iconClass(name: String, className: Null<String>): String {
        return className != null ? "icon icon-" + name + " " + className : "icon icon-" + name;
    }

    
    /**
     * Renders a modal dialog
     */
    @:component
    public static function modal(assigns: ModalAssigns): String {
        return HXX.hxx('
            <div id=${assigns.id} class="modal" phx-show=${assigns.show}>
                ${assigns.inner_content != null ? assigns.inner_content : ""}
            </div>
        ');
    }
    
    /**
     * Renders a button component
     */
    @:component
    public static function button(assigns: ButtonAssigns): String {
        return HXX.hxx('
            <button
                type=${assigns.type != null ? assigns.type : "button"}
                class=${assigns.className}
                disabled=${assigns.disabled}
            >
                ${assigns.inner_content}
            </button>
        ');
    }
    
    /**
     * Renders a form input field
     */
    @:component
    public static function input(assigns: InputAssigns): String {
        return HXX.hxx('
            <div class="form-group">
                <label for=${assigns.field.id}>${assigns.label}</label>
                <input
                    type=${assigns.type != null ? assigns.type : "text"}
                    id=${assigns.field.id}
                    name=${assigns.field.name}
                    value=${assigns.field.value}
                    placeholder=${assigns.placeholder}
                    class="form-control"
                    required=${assigns.required}
                />
                <if {assigns.field.errors != null && assigns.field.errors.length > 0}>
                    <span class="error">
                        ${Enum.join(assigns.field.errors != null ? assigns.field.errors : [], ", ")}
                    </span>
                </if>
            </div>
        ');
    }
    
    /**
     * Renders form error messages
     */
    @:component
    public static function error(assigns: ErrorAssigns): String {
        return HXX.hxx('
            <if {assigns.field.errors != null && assigns.field.errors.length > 0}>
                <div class="error-message">
                    ${Enum.join(assigns.field.errors != null ? assigns.field.errors : [], ", ")}
                </div>
            </if>
        ');
    }
    
    /**
     * Renders a simple form
     */
    @:component  
    public static function simple_form(assigns: FormAssigns): String {
        // Use `_f` to avoid unused variable warnings when slot variable is not referenced
        return HXX.hxx('
            <.form :let={_f} for=${assigns.formFor} action=${assigns.action} method=${assigns.method != null ? assigns.method : "post"}>
                ${assigns.inner_content}
            </.form>
        ');
    }
    
    /**
     * Renders a header with title and actions
     */
    @:component
    public static function header(assigns: HeaderAssigns): String {
        return HXX.hxx('
            <header class="header">
                <h1>${assigns.title}</h1>
                <if {assigns.actions}>
                    <div class="actions">
                        ${assigns.actions != null ? assigns.actions : ""}
                    </div>
                </if>
            </header>
        ');
    }

    /**
     * Renders a reusable card surface with typed slots.
     *
     * - `:let` on <.card> binds to the value passed from `render_slot(@inner_block, value)`
     * - `<:action .../>` slot tags are type-checked against CardActionAssigns
     */
    @:component
    public static function card(assigns: CardAssigns): String {
        return HXX.hxx('
            <section class=${assigns.className != null
                ? "bg-white dark:bg-gray-800 rounded-xl shadow-sm border border-gray-200 dark:border-gray-700 overflow-hidden " + assigns.className
                : "bg-white dark:bg-gray-800 rounded-xl shadow-sm border border-gray-200 dark:border-gray-700 overflow-hidden"}>
                <div class="flex items-center justify-between gap-4 px-6 py-4 border-b border-gray-200 dark:border-gray-700">
                    <h2 class="text-lg font-semibold text-gray-900 dark:text-white">#{@title}</h2>
                    <if {assigns.action != null && assigns.action.length > 0}>
                        <div class="flex items-center gap-2">
                            <for {a in assigns.action}>
                                <.link navigate={a.navigate} class="text-sm text-blue-700 dark:text-blue-300 hover:underline">
                                    #{a.label}
                                </.link>
                            </for>
                        </div>
                    </if>
                </div>
                <div class="px-6 py-4">
                    ${Component.render_slot(assigns.inner_block, { title: assigns.title })}
                </div>
            </section>
        ');
    }
    
    /**
     * Renders a data table
     */
    @:component
    public static function table(assigns: TableAssigns): String {
        return HXX.hxx('
            <table class="table">
                <thead>
                    <tr>
                        <for {col in assigns.columns}>
                            <th>#{col.label}</th>
                        </for>
                    </tr>
                </thead>
                <tbody>
                    <for {row in assigns.rows}>
                        <tr>
                            <for {col in assigns.columns}>
                                <td>#{Map.get(row, col.field)}</td>
                            </for>
                        </tr>
                    </for>
                </tbody>
            </table>
        ');
    }
    
    /**
     * Renders a list of items
     */
    @:component
    public static function list(assigns: ListAssigns): String {
        return HXX.hxx('
            <ul class="list">
                <for {item in assigns.items}>
                    <li>#{item}</li>
                </for>
            </ul>
        ');
    }
    
    /**
     * Renders a back navigation link
     */
    @:component
    public static function back(assigns: BackAssigns): String {
        return HXX.hxx('
            <div class="back-link">
                <.link navigate=${assigns.navigate}>
                    ← Back
                </.link>
            </div>
        ');
    }
    
    /**
     * Renders an icon
     */
    @:component
    public static function icon(assigns: IconAssigns): String {
        return HXX.hxx('
            <span class=${iconClass(assigns.name, assigns.className)}></span>
        ');
    }
    
    /**
     * Renders a form label
     */
    @:component
    public static function label(assigns: LabelAssigns): String {
        return HXX.hxx('
            <label for=${assigns.htmlFor} class=${assigns.className}>
                ${assigns.inner_content}
            </label>
        ');
    }
}
