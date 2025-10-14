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
extern class Gettext {
    
    /**
     * Default locale for the application.
     */
    public static var DEFAULT_LOCALE: String;
    
    /**
     * Translates a message in the default domain.
     * 
     * @param msgid The message identifier to translate
     * @param bindings Optional variable bindings for interpolation
     * @return The translated string
     */
    public static function gettext(msgid: String, ?bindings: TranslationBindings): String;
    
    /**
     * Translates a message in a specific domain.
     * 
     * @param domain The translation domain (e.g., "errors", "forms")
     * @param msgid The message identifier to translate
     * @param bindings Optional variable bindings for interpolation
     * @return The translated string
     */
    public static function dgettext(domain: String, msgid: String, ?bindings: TranslationBindings): String;
    
    /**
     * Translates a plural message based on count.
     * 
     * @param msgid The singular message identifier
     * @param msgid_plural The plural message identifier
     * @param count The count for determining singular/plural
     * @param bindings Optional variable bindings for interpolation
     * @return The translated string
     */
    public static function ngettext(msgid: String, msgid_plural: String, count: Int, ?bindings: TranslationBindings): String;
    
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
    public static function dngettext(domain: String, msgid: String, msgid_plural: String, count: Int, ?bindings: TranslationBindings): String;
    
    /**
     * Gets the current locale.
     * 
     * @return The current locale string (e.g., "en", "es", "fr")
     */
    public static function get_locale(): String;
    
    /**
     * Sets the current locale for translations.
     * 
     * @param locale The locale to set (e.g., "en", "es", "fr")
     */
    public static function put_locale(locale: String): Void;
    
    /**
     * Returns all available locales for the application.
     * 
     * @return Array of available locale codes
     */
    public static function known_locales(): Array<String>;

}

// Explicit alias to ensure fully-qualified module printing for calls
@:native("TodoAppWeb.Gettext")
extern class WebGettext {
    public static function gettext(msgid: String, ?bindings: TranslationBindings): String;
    public static function dgettext(domain: String, msgid: String, ?bindings: TranslationBindings): String;
    public static function ngettext(msgid: String, msgid_plural: String, count: Int, ?bindings: TranslationBindings): String;
    public static function dngettext(domain: String, msgid: String, msgid_plural: String, count: Int, ?bindings: TranslationBindings): String;
}
