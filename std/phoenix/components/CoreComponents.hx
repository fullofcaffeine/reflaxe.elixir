package phoenix.components;

import HXX;

import phoenix.types.Assigns;

/**
 * Type-safe Phoenix CoreComponents implementation in Haxe
 * 
 * Provides essential UI components (button, input, label, error, form, icon)
 * that compile to idiomatic Phoenix.Component function definitions.
 * 
 * This maintains the Haxe-first philosophy while generating standard Phoenix
 * component patterns that integrate seamlessly with LiveView and HEEx templates.
 * 
 * Architecture:
 * - Components defined using @:component annotation
 * - Type-safe assigns with proper validation
 * - HXX templates compile to ~H sigils
 * - Automatic attr/slot metadata generation
 * 
 * Usage in HXX templates:
 * ```haxe
 * HXX.hxx('<.button type="submit" variant="primary">Save</.button>')
 * HXX.hxx('<.input field={@form[:email]} type="email" required />')
 * ```
 * 
 * Generated Output:
 * ```elixir
 * defmodule TodoAppWeb.CoreComponents do
 *   use Phoenix.Component
 *   
 *   attr :type, :string, default: "button"
 *   slot :inner_block, required: true
 *   def button(assigns), do: ~H"..."
 * end
 * ```
 * 
 * @see /docs/02-user-guide/PHOENIX_INTEGRATION.md - Complete usage guide
 */
@:native("TodoAppWeb.CoreComponents")
@:phoenix.components
class CoreComponents {
    
    /**
     * Button component with type-safe variants and accessibility
     * 
     * Generates a styled button element with proper ARIA attributes
     * and consistent styling based on variant and state.
     * 
     * Attributes:
     * - type: Button type (button, submit, reset)
     * - variant: Visual style (primary, secondary, danger, ghost)
     * - size: Button size (sm, md, lg)
     * - disabled: Disabled state
     * - class: Additional CSS classes
     * 
     * Slots:
     * - inner_block: Button content (text, icons, etc.)
     * 
     * @param assigns Component assigns with type-safe access
     * @return String Generated HEEx template
     */
    @:component
    @:attr("type", "string", {default: "button"})
    @:attr("variant", "string", {default: "primary"})
    @:attr("size", "string", {default: "md"})
    @:attr("disabled", "boolean", {default: false})
    @:attr("class", "string", {default: ""})
    @:slot("inner_block", {required: true})
    public static function button(assigns: Assigns<Dynamic>): String {
        return HXX.hxx('
        <button
            type={@type}
            disabled={@disabled}
            class={"btn btn-#{@variant} btn-#{@size} #{@class}"}
        >
            {render_slot(@inner_block)}
        </button>
        ');
    }
    
    /**
     * Input field component with validation and error handling
     * 
     * Supports various input types with consistent styling, validation
     * states, and accessibility features. Integrates with Phoenix forms
     * and changesets for seamless validation feedback.
     * 
     * Attributes:
     * - field: Phoenix.HTML.FormField for form integration
     * - type: Input type (text, email, password, number, etc.)
     * - label: Field label text
     * - placeholder: Input placeholder text
     * - required: Required field indicator
     * - disabled: Disabled state
     * - class: Additional CSS classes
     * 
     * @param assigns Component assigns with form field data
     * @return String Generated HEEx template with label and validation
     */
    @:component
    @:attr("field", "Phoenix.HTML.FormField", {required: true})
    @:attr("type", "string", {default: "text"})
    @:attr("label", "string")
    @:attr("placeholder", "string")
    @:attr("required", "boolean", {default: false})
    @:attr("disabled", "boolean", {default: false})
    @:attr("class", "string", {default: ""})
    public static function input(assigns: Assigns<Dynamic>): String {
        return HXX.hxx('
        <div class="form-field">
            <%= if @label do %>
                <.label for={@field.id}>{@label}</.label>
            <% end %>
            <input
                id={@field.id}
                name={@field.name}
                type={@type}
                value={@field.value}
                placeholder={@placeholder}
                required={@required}
                disabled={@disabled}
                class={"input #{if @field.errors != [], do: "input-error"} #{@class}"}
            />
            <.error field={@field} />
        </div>
        ');
    }
    
    /**
     * Label component for form fields
     * 
     * Provides accessible labeling for form inputs with consistent
     * styling and proper association via the 'for' attribute.
     * 
     * Attributes:
     * - for: Target input ID for accessibility
     * - class: Additional CSS classes
     * 
     * Slots:
     * - inner_block: Label content
     * 
     * @param assigns Component assigns
     * @return String Generated label element
     */
    @:component
    @:attr("for", "string")
    @:attr("class", "string", {default: ""})
    @:slot("inner_block", {required: true})
    public static function label(assigns: Assigns<Dynamic>): String {
        return HXX.hxx('
        <label for={@for} class={"label #{@class}"}>
            {render_slot(@inner_block)}
        </label>
        ');
    }
    
    /**
     * Error display component for form validation
     * 
     * Shows validation errors for form fields with consistent styling
     * and proper accessibility attributes. Integrates with Phoenix
     * changeset errors for automatic error display.
     * 
     * Attributes:
     * - field: Phoenix.HTML.FormField with error data
     * - class: Additional CSS classes
     * 
     * @param assigns Component assigns with field error data
     * @return String Generated error message HTML
     */
    @:component
    @:attr("field", "Phoenix.HTML.FormField", {required: true})
    @:attr("class", "string", {default: ""})
    public static function error(assigns: Assigns<Dynamic>): String {
        return HXX.hxx('
        <%= for error <- @field.errors do %>
            <div class={"error-message #{@class}"} role="alert">
                {error}
            </div>
        <% end %>
        ');
    }
    
    /**
     * Form wrapper component with CSRF protection
     * 
     * Provides a form element with automatic CSRF token injection,
     * proper form handling attributes, and integration with Phoenix
     * form helpers and changesets.
     * 
     * Attributes:
     * - for: Form data (changeset or params)
     * - action: Form action URL
     * - method: HTTP method (post, put, patch, delete)
     * - class: Additional CSS classes
     * 
     * Slots:
     * - inner_block: Form content (inputs, buttons, etc.)
     * 
     * @param assigns Component assigns with form data
     * @return String Generated form element with CSRF protection
     */
    @:component
    @:attr("for", "Dynamic", {required: true})
    @:attr("action", "string")
    @:attr("method", "string", {default: "post"})
    @:attr("class", "string", {default: ""})
    @:slot("inner_block", {required: true})
    public static function form(assigns: Assigns<Dynamic>): String {
        return HXX.hxx('
        <.form_component for={@for} action={@action} method={@method} class={@class}>
            {render_slot(@inner_block)}
        </.form_component>
        ');
    }
    
    /**
     * Icon component with Heroicons integration
     * 
     * Renders SVG icons from the Heroicons library with consistent
     * sizing, styling, and accessibility attributes. Supports both
     * outline and solid icon variants.
     * 
     * Attributes:
     * - name: Icon name (e.g., "user", "home", "chevron-down")
     * - variant: Icon style (outline, solid)
     * - size: Icon size (sm, md, lg)
     * - class: Additional CSS classes
     * 
     * @param assigns Component assigns with icon configuration
     * @return String Generated SVG icon element
     */
    @:component
    @:attr("name", "string", {required: true})
    @:attr("variant", "string", {default: "outline"})
    @:attr("size", "string", {default: "md"})
    @:attr("class", "string", {default: ""})
    public static function icon(assigns: Assigns<Dynamic>): String {
        return HXX.hxx('
        <svg 
            class={"icon icon-#{@size} #{@class}"} 
            aria-hidden="true"
            data-icon="{@name}"
            data-variant="{@variant}"
        >
            <use href={"#icon-#{@name}"}></use>
        </svg>
        ');
    }
    
    /**
     * Modal component for overlays and dialogs
     * 
     * Provides a accessible modal dialog with backdrop, focus management,
     * and keyboard navigation. Integrates with Phoenix LiveView for
     * dynamic show/hide behavior.
     * 
     * Attributes:
     * - id: Modal ID for JavaScript interaction
     * - show: Whether modal is visible
     * - title: Modal title for accessibility
     * - size: Modal size (sm, md, lg, xl)
     * - class: Additional CSS classes
     * 
     * Slots:
     * - inner_block: Modal content
     * 
     * @param assigns Component assigns with modal configuration
     * @return String Generated modal HTML with accessibility features
     */
    @:component
    @:attr("id", "string", {required: true})
    @:attr("show", "boolean", {default: false})
    @:attr("title", "string")
    @:attr("size", "string", {default: "md"})
    @:attr("class", "string", {default: ""})
    @:slot("inner_block", {required: true})
    public static function modal(assigns: Assigns<Dynamic>): String {
        return HXX.hxx('
        <div
            id={@id}
            class={"modal modal-#{@size} #{@class}"}
            style={"display: #{if @show, do: "block", else: "none"}"}
            role="dialog"
            aria-modal="true"
            aria-labelledby={@id <> "-title"}
        >
            <div class="modal-backdrop" phx-click="close-modal" phx-target={@myself}></div>
            <div class="modal-content">
                <%= if @title do %>
                    <div class="modal-header">
                        <h2 id={@id <> "-title"} class="modal-title">{@title}</h2>
                        <.button variant="ghost" size="sm" phx-click="close-modal" phx-target={@myself}>
                            <.icon name="x-mark" />
                        </.button>
                    </div>
                <% end %>
                <div class="modal-body">
                    {render_slot(@inner_block)}
                </div>
            </div>
        </div>
        ');
    }
}
