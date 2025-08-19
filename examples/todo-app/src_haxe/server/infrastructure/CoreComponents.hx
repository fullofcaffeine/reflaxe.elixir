package server.infrastructure;

import phoenix.types.HtmlComponent;

/**
 * Core UI components for Phoenix applications.
 * 
 * This module provides reusable UI components like modals, flash messages,
 * tables, and forms that are commonly used across Phoenix LiveView applications.
 * These components follow Phoenix's component patterns and conventions.
 * 
 * All components return type-safe HtmlComponent instead of Dynamic,
 * providing compile-time safety and IntelliSense support.
 */
@:native("TodoAppWeb.CoreComponents")
class CoreComponents {
    
    /**
     * Renders a modal dialog component.
     * 
     * @param id The unique identifier for the modal
     * @param show Whether the modal should be visible
     * @return Type-safe HTML component for the modal
     */
    public static function modal(id: String, show: Bool = false): HtmlComponent {
        // Phoenix will provide the actual implementation
        // This signature provides type safety and IntelliSense
        return HtmlComponent.empty();
    }
    
    /**
     * Renders flash messages for user notifications.
     * 
     * @param type The type of flash message (info, success, warning, error)
     * @param message The message content to display
     * @return Type-safe HTML component for the flash message
     */
    public static function flash(type: String, message: String): HtmlComponent {
        return HtmlComponent.empty();
    }
    
    /**
     * Renders a simple form component.
     * 
     * @param for_schema The schema or changeset for the form
     * @param action The form submission action/URL
     * @return Type-safe HTML component for the form
     */
    public static function simple_form(for_schema: String, action: String): HtmlComponent {
        return HtmlComponent.empty();
    }
    
    /**
     * Renders a button component.
     * 
     * @param label The button text
     * @param type The button type (button, submit, reset)
     * @param disabled Whether the button is disabled
     * @return Type-safe HTML component for the button
     */
    public static function button(label: String, type: String = "button", disabled: Bool = false): HtmlComponent {
        return HtmlComponent.empty();
    }
    
    /**
     * Renders an input field component.
     * 
     * @param field The form field name
     * @param label The input label
     * @param type The input type (text, email, password, etc.)
     * @param required Whether the field is required
     * @return Type-safe HTML component for the input
     */
    public static function input(field: String, label: String, type: String = "text", required: Bool = false): HtmlComponent {
        return HtmlComponent.empty();
    }
    
    /**
     * Renders a data table component.
     * 
     * @param id The table identifier
     * @param rows The data rows to display (as array of structs)
     * @return Type-safe HTML component for the table
     */
    public static function table<T>(id: String, rows: Array<T>): HtmlComponent {
        return HtmlComponent.empty();
    }
    
    /**
     * Renders a list component.
     * 
     * @param items The items to display in the list
     * @return Type-safe HTML component for the list
     */
    public static function list<T>(items: Array<T>): HtmlComponent {
        return HtmlComponent.empty();
    }
    
    /**
     * Renders a back navigation link.
     * 
     * @param navigate The navigation target path
     * @return Type-safe HTML component for the back link
     */
    public static function back(navigate: String): HtmlComponent {
        return HtmlComponent.empty();
    }
    
    /**
     * Renders an icon component.
     * 
     * @param name The icon name
     * @param className Optional CSS classes
     * @return Type-safe HTML component for the icon
     */
    public static function icon(name: String, ?className: String): HtmlComponent {
        return HtmlComponent.empty();
    }
    
    /**
     * Renders a header component.
     * 
     * @param title The header title
     * @param subtitle Optional subtitle
     * @return Type-safe HTML component for the header
     */
    public static function header(title: String, ?subtitle: String): HtmlComponent {
        return HtmlComponent.empty();
    }
    
    /**
     * Translates an error message from an Ecto changeset error.
     * Used for form validation error messages.
     * 
     * @param error The error tuple from Ecto
     * @return The translated error message string
     */
    public static function translate_error(error: {msg: String, opts: Array<{key: String, value: String}>}): String {
        // This will integrate with Gettext for translations
        // For now, return the message directly
        return error.msg;
    }
    
    /**
     * Returns a list of all error messages for a field.
     * 
     * @param field The field to get errors for
     * @return Array of error messages
     */
    public static function errors_for_field(field: String): Array<String> {
        // Phoenix will provide the actual implementation
        return [];
    }
}