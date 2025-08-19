package server.infrastructure;

import server.infrastructure.Gettext;
import server.infrastructure.TranslationBindings;

/**
 * Common error message translations for the application.
 * 
 * This class provides pre-defined error messages using Gettext
 * for internationalization. All messages are in the "errors" domain
 * and can be translated to different languages.
 */
@:native("TodoAppWeb.Gettext.ErrorMessages")
class GettextErrorMessages {
    /**
     * Returns the "required field" error message.
     * @return Translated error message for required fields
     */
    public static function required_field(): String {
        return Gettext.dgettext("errors", "can't be blank");
    }
    
    /**
     * Returns the "invalid format" error message.
     * @return Translated error message for invalid format
     */
    public static function invalid_format(): String {
        return Gettext.dgettext("errors", "has invalid format");
    }
    
    /**
     * Returns the "too short" error message with minimum length.
     * @param min The minimum required length
     * @return Translated error message with count interpolation
     */
    public static function too_short(min: Int): String {
        var bindings = TranslationBindings.create()
            .setInt("count", min);
        return Gettext.dgettext("errors", "should be at least %{count} character(s)", bindings);
    }
    
    /**
     * Returns the "too long" error message with maximum length.
     * @param max The maximum allowed length
     * @return Translated error message with count interpolation
     */
    public static function too_long(max: Int): String {
        var bindings = TranslationBindings.create()
            .setInt("count", max);
        return Gettext.dgettext("errors", "should be at most %{count} character(s)", bindings);
    }
    
    /**
     * Returns the "not found" error message.
     * @return Translated error message for not found resources
     */
    public static function not_found(): String {
        return Gettext.dgettext("errors", "not found");
    }
    
    /**
     * Returns the "unauthorized" error message.
     * @return Translated error message for unauthorized access
     */
    public static function unauthorized(): String {
        return Gettext.dgettext("errors", "unauthorized");
    }
}