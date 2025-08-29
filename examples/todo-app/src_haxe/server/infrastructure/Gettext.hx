package server.infrastructure;

import server.infrastructure.TranslationBindings;

/**
 * Internationalization support module using Phoenix's Gettext.
 * 
 * This module provides translation and localization functionality
 * for the TodoApp application. It wraps Phoenix's Gettext system
 * to provide compile-time type safety for translations.
 */
@:native("TodoAppWeb.Gettext")
class Gettext {
    
    /**
     * Default locale for the application.
     */
    public static final DEFAULT_LOCALE: String = "en";
    
    /**
     * Translates a message in the default domain.
     * 
     * @param msgid The message identifier to translate
     * @param bindings Optional variable bindings for interpolation
     * @return The translated string
     */
    public static function gettext(msgid: String, ?bindings: TranslationBindings): String {
        // This will be handled by Phoenix's Gettext at runtime
        return msgid;
    }
    
    /**
     * Translates a message in a specific domain.
     * 
     * @param domain The translation domain (e.g., "errors", "forms")
     * @param msgid The message identifier to translate
     * @param bindings Optional variable bindings for interpolation
     * @return The translated string
     */
    public static function dgettext(domain: String, msgid: String, ?bindings: TranslationBindings): String {
        // Domain-specific translation
        return msgid;
    }
    
    /**
     * Translates a plural message based on count.
     * 
     * @param msgid The singular message identifier
     * @param msgid_plural The plural message identifier
     * @param count The count for determining singular/plural
     * @param bindings Optional variable bindings for interpolation
     * @return The translated string
     */
    public static function ngettext(msgid: String, msgid_plural: String, count: Int, ?bindings: TranslationBindings): String {
        // Plural translation based on count
        return count == 1 ? msgid : msgid_plural;
    }
    
    /**
     * Translates a plural message in a specific domain.
     * 
     * @param domain The translation domain
     * @param msgid The singular message identifier
     * @param msgid_plural The plural message identifier
     * @param count The count for determining singular/plural
     * @param bindings Optional variable bindings for interpolation
     * @return The translated string
     */
    public static function dngettext(domain: String, msgid: String, msgid_plural: String, count: Int, ?bindings: TranslationBindings): String {
        // Domain-specific plural translation
        return count == 1 ? msgid : msgid_plural;
    }
    
    /**
     * Gets the current locale.
     * 
     * @return The current locale string (e.g., "en", "es", "fr")
     */
    public static function get_locale(): String {
        return "en";
    }
    
    /**
     * Sets the current locale for translations.
     * 
     * @param locale The locale to set (e.g., "en", "es", "fr")
     */
    public static function put_locale(locale: String): Void {
        // This will be handled by Phoenix's Gettext
    }
    
    /**
     * Returns all available locales for the application.
     * 
     * @return Array of available locale codes
     */
    public static function known_locales(): Array<String> {
        return ["en", "es", "fr", "de", "pt", "ja", "zh"];
    }
    
}