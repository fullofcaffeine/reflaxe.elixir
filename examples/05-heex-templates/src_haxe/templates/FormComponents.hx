package templates;

import HXX.*;

/**
 * Phoenix form component examples with HEEx templates
 * Demonstrates form helpers and validation integration
 */
@:template("form_components.html.heex") 
class FormComponents {
    
    /**
     * User registration form
     */
    public static function userForm(assigns: FormAssigns): String {
        return hxx('
        <div class="form-container">
            <h2>User Registration</h2>
            
            <.form for={@changeset} phx-submit="save" phx-change="validate">
                <div class="form-group">
                    <.label for="name">Full Name</.label>
                    <.input 
                        field={@changeset[:name]} 
                        type="text"
                        placeholder="Enter your full name"
                        required
                    />
                    <.error field={@changeset[:name]} />
                </div>
                
                <div class="form-group">
                    <.label for="email">Email Address</.label>  
                    <.input
                        field={@changeset[:email]}
                        type="email" 
                        placeholder="user@example.com"
                        required
                    />
                    <.error field={@changeset[:email]} />
                </div>
                
                <div class="form-group">
                    <.label for="age">Age</.label>
                    <.input
                        field={@changeset[:age]} 
                        type="number"
                        min="13"
                        max="120"
                    />
                    <.error field={@changeset[:age]} />
                </div>
                
                <div class="form-group checkbox">
                    <.input
                        field={@changeset[:active]}
                        type="checkbox"
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
    public static function searchForm(assigns: SearchAssigns): String {
        return hxx('
        <form phx-change="search" phx-submit="search" class="search-form">
            <div class="search-group">
                <.input 
                    name="q"
                    type="search"
                    value={@query}
                    placeholder="Search users..."
                    autocomplete="off"
                />
                
                <.select name="filter" value={@filter}>
                    <option value="all">All Users</option>
                    <option value="active">Active Only</option>
                    <option value="inactive">Inactive Only</option>
                </.select>
                
                <.button type="submit">
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
    static function renderFilters(filters: Array<String>): String {
        if (filters.length == 0) return "";
        
        return hxx('
        <div class="active-filters">
            <span class="label">Active filters:</span>
            ${filters.map(renderFilterTag).join("")}
            <.button variant="link" phx-click="clear_filters">
                Clear all
            </.button>
        </div>
        ');
    }
    
    static function renderFilterTag(filter: String): String {
        return hxx('
        <span class="filter-tag">
            ${filter}
            <button type="button" phx-click="remove_filter" phx-value-filter="${filter}">
                ×
            </button>
        </span>
        ');
    }
    
    // Main function for compilation
    public static function main(): Void {
        trace("FormComponents template compiled successfully!");
    }
}

// Type definitions
typedef FormAssigns = {
    changeset: ecto.Changeset<elixir.types.Term, elixir.types.Term>
}

typedef SearchAssigns = {
    query: String,
    filter: String,
    activeFilters: Array<String>
}
