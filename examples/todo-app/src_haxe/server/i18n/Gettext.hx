package server.i18n;

/**
 * Gettext module for internationalization
 * 
 * Provides translation and localization support for the Phoenix application.
 * This module wraps the Elixir Gettext functionality with type-safe Haxe interfaces.
 */
@:native("TodoAppWeb.Gettext")
@:gettext
class Gettext {
    /**
     * Default locale for the application
     */
    public static inline var DEFAULT_LOCALE = "en";
    
    /**
     * Translate a message
     * 
     * @param msgid The message ID to translate
     * @return Translated string
     */
    public static extern function gettext(msgid: String): String;
    
    /**
     * Translate a message with pluralization
     * 
     * @param msgid Singular message ID
     * @param msgid_plural Plural message ID
     * @param count Count for pluralization
     * @return Translated string
     */
    public static extern function ngettext(msgid: String, msgid_plural: String, count: Int): String;
    
    /**
     * Translate within a specific domain
     * 
     * @param domain Translation domain
     * @param msgid Message ID
     * @return Translated string
     */
    public static extern function dgettext(domain: String, msgid: String): String;
    
    /**
     * Translate with domain and pluralization
     * 
     * @param domain Translation domain
     * @param msgid Singular message ID
     * @param msgid_plural Plural message ID
     * @param count Count for pluralization
     * @return Translated string
     */
    public static extern function dngettext(domain: String, msgid: String, msgid_plural: String, count: Int): String;
    
    /**
     * Get the current locale
     * 
     * @return Current locale string
     */
    public static extern function getLocale(): String;
    
    /**
     * Set the current locale
     * 
     * @param locale Locale to set
     */
    public static extern function putLocale(locale: String): Void;
    
    /**
     * Helper function for error messages
     * 
     * @param msgid Error message ID
     * @param bindings Variable bindings for interpolation
     * @return Translated error message
     */
    public static function error(msgid: String, ?bindings: Map<String, String>): String {
        // This would handle error message translation with variable interpolation
        return gettext(msgid);
    }
}
