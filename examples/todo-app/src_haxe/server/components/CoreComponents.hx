package server.components;

import HXX.*;
import elixir.Enum;
import elixir.types.Term;
import phoenix.Component;
import phoenix.types.Slot;

/**
 * Type-safe assigns for Phoenix components
 */
typedef ComponentAssigns = {
	?id:String,
	?className:String,
	?show:Bool,
	?inner_content:String
}

typedef ModalAssigns = {
	id:String,
	show:Bool,
	?inner_content:String
}

typedef ButtonAssigns = {
	?type:String,
	?className:String,
	?disabled:Bool,
	inner_content:String
}

typedef InputAssigns = {
	field:FormField,
	?type:String,
	label:String,
	?placeholder:String,
	?required:Bool
}

typedef FormField = {
	id:String,
	name:String,
	value:String,
	?errors:Array<String>
}

/**
 * Type-safe abstract for Phoenix form targets
 * Compiles to the appropriate Elixir representation
 */
abstract FormTarget(String) {
	public function new(target:String) {
		this = target;
	}

	// @:from: enables implicit conversion from another type into this abstract/type.
	@:from public static function fromString(s:String):FormTarget {
		return new FormTarget(s);
	}

	// @:to: enables implicit conversion from this abstract/type into another type.
	@:to public function toString():String {
		return this;
	}
}

typedef ErrorAssigns = {
	field:FormField
}

typedef FormAssigns = {
	formFor:FormTarget, // Changeset or schema
	action:String,
	?method:String,
	inner_content:String
}

typedef HeaderAssigns = {
	title:String,
	?actions:String
}

typedef CardLet = {
	var title:String;
}

typedef CardActionAssigns = {
	var label:String;
	var navigate:String;
}

typedef CardAssigns = {
	var title:String;
	// @:optional: marks this field/contract member as optional in generated typing/validation.
	@:optional var className:String;
	// @:slot: marks this assigns field as a component slot contract for HEEx slot validation.
	@:slot @:optional var action:Slot<CardActionAssigns>;
	@:slot var inner_block:Slot<Term, CardLet>;
}

typedef TableColumn = {
	field:String,
	label:String
}

typedef TableRowData = Map<String, String>;

typedef TableAssigns = {
	rows:Array<TableRowData>,
	columns:Array<TableColumn>
}

typedef ListAssigns = {
	items:Array<String>
}

typedef BackAssigns = {
	navigate:String
}

typedef IconAssigns = {
	name:String,
	?className:String
}

typedef LabelAssigns = {
	?htmlFor:String,
	?className:String,
	inner_content:String
}

/**
 * Core UI components for Phoenix applications
 * 
 * Provides reusable, type-safe UI components like modals, forms, buttons, etc.
 * These components follow Phoenix LiveView conventions and compile to proper
 * Phoenix.Component functions.
 */
// @:native (class): pins the generated Elixir module name to match Phoenix/Ecto runtime expectations.
@:native("TodoAppWeb.CoreComponents")
// @:component (class): marks this module as a Phoenix component container so component functions are preserved and discoverable.
@:component
class CoreComponents {
	static function iconClass(name:String, className:Null<String>):String {
		return className != null ? "icon icon-" + name + " " + className : "icon icon-" + name;
	}

	static inline function fieldErrors(errors:Null<Array<String>>):Array<String> {
		return errors != null ? errors : [];
	}

	static inline function cellValue(row:TableRowData, key:String):String {
		var value = row.get(key);
		return value != null ? value : "";
	}

	/**
	 * Renders a modal dialog
	 */
	// @:component (function): marks this function as a typed dot-component entrypoint (props/slots can be validated).
	@:component
	public static function modal(assigns:ModalAssigns):String {
		return (<div id=${assigns.id} class="modal" phx-show=${assigns.show}>
                ${assigns.inner_content != null ? assigns.inner_content : ""}
            </div>);
	}

	/**
	 * Renders a button component
	 *
	 * NOTE
	 * - This uses Haxe inline markup (`return <button ...>`) for typed template authoring.
	 * - Inline markup is enabled by default for Phoenix-facing modules; opt out with `-D hxx_no_inline_markup`
	 *   (or `@:hxx_no_inline_markup` on the class).
	 */
	@:component
	public static function button(assigns:ButtonAssigns):String {
		return <button
            type=${assigns.type != null ? assigns.type : "button"}
            class=${assigns.className}
            disabled=${assigns.disabled}
        >
            ${assigns.inner_content}
        </button>;
	}

	/**
	 * Renders a form input field
	 */
	@:component
	public static function input(assigns:InputAssigns):String {
		return (<div class="form-group">
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
                        ${Enum.join(fieldErrors(assigns.field.errors), ", ")}
                    </span>
                </if>
            </div>);
	}

	/**
	 * Renders form error messages
	 */
	@:component
	public static function error(assigns:ErrorAssigns):String {
		return (<if {assigns.field.errors != null && assigns.field.errors.length > 0}>
                <div class="error-message">
                    ${Enum.join(fieldErrors(assigns.field.errors), ", ")}
                </div>
            </if>);
	}

	/**
	 * Renders a simple form
	 */
	@:component
	public static function simple_form(assigns:FormAssigns):String {
		return <form action=${assigns.action} method=${assigns.method != null ? assigns.method : "post"}>
			${assigns.inner_content}
		</form>;
	}

	/**
	 * Renders a header with title and actions
	 */
	@:component
	public static function header(assigns:HeaderAssigns):String {
		return (<header class="header">
                <h1>${assigns.title}</h1>
                <if {assigns.actions != null}>
                    <div class="actions">
                        ${assigns.actions != null ? assigns.actions : ""}
                    </div>
                </if>
            </header>);
	}

	/**
	 * Renders a reusable card surface with typed slots.
	 *
	 * - `:let` on <.card> binds to the value passed from `render_slot(assigns.inner_block, value)`
	 * - `<:action .../>` slot tags are type-checked against CardActionAssigns
	 */
	@:component
	public static function card(assigns:CardAssigns):String {
		return
			(<section class={["bg-white dark:bg-gray-800 rounded-xl shadow-sm border border-gray-200 dark:border-gray-700 overflow-hidden", assigns.className]}>
	                <div class="flex items-center justify-between gap-4 px-6 py-4 border-b border-gray-200 dark:border-gray-700">
	                    <h2 class="text-lg font-semibold text-gray-900 dark:text-white">${assigns.title}</h2>
	                    <if {assigns.action != null}>
								<div class="flex items-center gap-2">
									${Component.render_slot(cast assigns.action)}
								</div>
							</if>
	                </div>
	                <div class="px-6 py-4">
	                    ${Component.render_slot(assigns.inner_block, {title: assigns.title})}
	                </div>
	            </section>);
	}

	/**
	 * Renders a data table
	 */
	@:component
	public static function table(assigns:TableAssigns):String {
		return (<table class="table">
                <thead>
                    <tr>
                        <for {col in assigns.columns}>
                            <th>${col.label}</th>
                        </for>
                    </tr>
                </thead>
                <tbody>
                    <for {row in assigns.rows}>
                        <tr>
                            <for {col in assigns.columns}>
                                <td>${cellValue(row, col.field)}</td>
                            </for>
                        </tr>
                    </for>
                </tbody>
            </table>);
	}

	/**
	 * Renders a list of items
	 */
	@:component
	public static function list(assigns:ListAssigns):String {
		return (<ul class="list">
                <for {item in assigns.items}>
                    <li>${item}</li>
                </for>
            </ul>);
	}

	/**
	 * Renders a back navigation link
	 */
	@:component
	public static function back(assigns:BackAssigns):String {
		return (<div class="back-link">
                <.link navigate=${assigns.navigate}>
                    ← Back
                </.link>
            </div>);
	}

	/**
	 * Renders an icon
	 */
	@:component
	public static function icon(assigns:IconAssigns):String {
		return (<span class=${iconClass(assigns.name, assigns.className)}></span>);
	}

	/**
	 * Renders a form label
	 */
	@:component
	public static function label(assigns:LabelAssigns):String {
		return (<label for=${assigns.htmlFor} class=${assigns.className}>
                ${assigns.inner_content}
            </label>);
	}
}
