package server.infrastructure;

import server.infrastructure.Gettext;
import server.infrastructure.TranslationBindings;

/**
 * Common UI message translations for the application.
 * 
 * This class provides pre-defined UI messages using Gettext
 * for internationalization. These messages are commonly used
 * throughout the application's user interface.
 */
@:native("TodoAppWeb.Gettext.UIMessages")
class GettextUIMessages {
    /**
     * Returns a welcome message with the user's name.
     * @param name The name to include in the welcome message
     * @return Translated welcome message with name interpolation
     */
    public static function welcome(name: String): String {
        var bindings = TranslationBindings.create()
            .set("name", name);
        return WebGettext.gettext("Welcome %{name}!", bindings);
    }
    
    /**
     * Returns a generic success message.
     * @return Translated success message
     */
    public static function success(): String {
        return WebGettext.gettext("Operation completed successfully");
    }
    
    /**
     * Returns a loading message.
     * @return Translated loading message
     */
    public static function loading(): String {
        return WebGettext.gettext("Loading...");
    }
    
    /**
     * Returns the "Save" button label.
     * @return Translated save label
     */
    public static function save(): String {
        return WebGettext.gettext("Save");
    }
    
    /**
     * Returns the "Cancel" button label.
     * @return Translated cancel label
     */
    public static function cancel(): String {
        return WebGettext.gettext("Cancel");
    }
    
    /**
     * Returns the "Delete" button label.
     * @return Translated delete label
     */
    public static function delete(): String {
        return WebGettext.gettext("Delete");
    }
    
    /**
     * Returns the "Edit" button label.
     * @return Translated edit label
     */
    public static function edit(): String {
        return WebGettext.gettext("Edit");
    }
    
    /**
     * Returns a confirmation message for delete actions.
     * @return Translated delete confirmation message
     */
    public static function confirm_delete(): String {
        return WebGettext.gettext("Are you sure you want to delete this item?");
    }
}
