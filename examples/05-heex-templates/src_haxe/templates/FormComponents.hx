package templates;

import HXX.*;
import elixir.types.Term;
import phoenix.Component;
import phoenix.types.Slot;

/**
 * Phoenix form component examples with HEEx templates
 * Demonstrates form helpers and validation integration
 */
// @:template: binds this class to an external HEEx template resource.

@:template("form_components.html.heex")
class FormComponents {
	/**
	 * User registration form
	 */
	public static function userForm(assigns:FormAssigns):String {
		return hxx('
        <div class="form-container">
            <h2>User Registration</h2>
            
            <.form for={@changeset} phx-submit="save" phx-change="validate">
                <div class="form-group">
                    <.label for="name">Full Name</.label>
                    <.input 
                        field={@changeset[:name]} 
                        name="name"
                        type="text"
                        value=""
                        placeholder="Enter your full name"
                        autocomplete=""
                        required
                        min=""
                        max=""
                    />
                    <.error field={@changeset[:name]} />
                </div>
                
                <div class="form-group">
                    <.label for="email">Email Address</.label>  
                    <.input
                        field={@changeset[:email]}
                        name="email"
                        type="email" 
                        value=""
                        placeholder="user@example.com"
                        autocomplete=""
                        required
                        min=""
                        max=""
                    />
                    <.error field={@changeset[:email]} />
                </div>
                
                <div class="form-group">
                    <.label for="age">Age</.label>
                    <.input
                        field={@changeset[:age]} 
                        name="age"
                        type="number"
                        value=""
                        placeholder=""
                        autocomplete=""
                        required={false}
                        min="13"
                        max="120"
                    />
                    <.error field={@changeset[:age]} />
                </div>
                
                <div class="form-group checkbox">
                    <.input
                        field={@changeset[:active]}
                        name="active"
                        type="checkbox"
                        value=""
                        placeholder=""
                        autocomplete=""
                        required={false}
                        min=""
                        max=""
                        label="Active account"
                    />
                </div>
                
                <div class="form-actions">
                    <.button type="submit" disabled={!@changeset.valid?}>
                        Create Account
                    </.button>
                    
                    <.button type="reset" variant="secondary">
                        Clear Form
                    </.button>
                </div>
            </.form>
        </div>
        ');
	}

	/**
	 * Search form component
	 */
	public static function searchForm(assigns:SearchAssigns):String {
		return hxx('
        <form phx-change="search" phx-submit="search" class="search-form">
            <div class="search-group">
                <.input 
                    name="q"
                    type="search"
                    value={@query}
                    placeholder="Search users..."
                    autocomplete="off"
                    required={false}
                    min=""
                    max=""
                />
                
                <.select name="filter" value={@filter}>
                    <option value="all">All Users</option>
                    <option value="active">Active Only</option>
                    <option value="inactive">Inactive Only</option>
                </.select>
                
                <.button type="submit" disabled={false}>
                    <.icon name="search" /> Search
                </.button>
            </div>
            
            ${renderFilters(assigns.activeFilters)}
        </form>
        ');
	}

	/**
	 * Active filters display
	 */
	static function renderFilters(filters:Array<String>):String {
		if (filters.length == 0)
			return "";

		return hxx('
        <div class="active-filters">
            <span class="label">Active filters:</span>
            <for {filter in filters}>
                #{render_filter_tag(filter)}
            </for>
            <.button type="button" disabled={false} variant="link" phx-click="clear_filters">
                Clear all
            </.button>
        </div>
        ');
	}

	static function renderFilterTag(filter:String):String {
		return hxx('
        <span class="filter-tag">
            ${filter}
            <button type="button" phx-click="remove_filter" phx-value-filter="${filter}">
                ×
            </button>
        </span>
        ');
	}

	/**
	 * Minimal local component stubs so this example compiles standalone.
	 *
	 * In real Phoenix apps these are typically provided by your `CoreComponents` module.
	 */
	// @:component (function): marks this function as a typed dot-component entrypoint (props/slots can be validated).

	@:component
	public static function button(assigns:ButtonAssigns):String {
		return hxx('
        <button
            type=${assigns.type != null ? assigns.type : "button"}
            disabled=${assigns.disabled}
        >
            ${Component.render_slot(assigns.inner_block)}
        </button>
        ');
	}

	@:component
	public static function input(assigns:InputAssigns):String {
		return hxx('
        <input
            name=${assigns.name}
            type=${assigns.type != null ? assigns.type : "text"}
            value=${assigns.value}
            placeholder=${assigns.placeholder}
            autocomplete=${assigns.autocomplete}
            required=${assigns.required}
            min=${assigns.min}
            max=${assigns.max}
        />
        ');
	}

	@:component
	public static function label(assigns:LabelAssigns):String {
		return hxx('<label>${Component.render_slot(assigns.inner_block)}</label>');
	}

	@:component
	public static function error(assigns:ErrorAssigns):String {
		return hxx('<span class="error"></span>');
	}

	@:component
	public static function select(assigns:SelectAssigns):String {
		return hxx('
        <select name=${assigns.name}>
            ${Component.render_slot(assigns.inner_block)}
        </select>
        ');
	}

	@:component
	public static function icon(assigns:IconAssigns):String {
		return hxx('<span class="icon">${assigns.name}</span>');
	}

	// Main function for compilation
	public static function main():Void {
		trace("FormComponents template compiled successfully!");
	}
}

// Type definitions
typedef FormAssigns = {
	changeset:ecto.Changeset<elixir.types.Term, elixir.types.Term>
}

typedef SearchAssigns = {
	query:String,
	filter:String,
	activeFilters:Array<String>
}

typedef ButtonAssigns = {
	?type:String,
	?disabled:Bool,
	inner_block:Slot<Term>
}

typedef InputAssigns = {
	?name:String,
	?type:String,
	?value:elixir.types.Term,
	?placeholder:String,
	?autocomplete:String,
	?required:Bool,
	?min:String,
	?max:String
}

typedef LabelAssigns = {
	inner_block:Slot<Term>
}

typedef ErrorAssigns = {
	?field:elixir.types.Term
}

typedef SelectAssigns = {
	?name:String,
	inner_block:Slot<Term>
}

typedef IconAssigns = {
	name:String
}
