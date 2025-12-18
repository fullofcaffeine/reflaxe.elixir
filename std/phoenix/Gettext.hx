package phoenix;

import elixir.types.Term;

/**
 * Extern definition for Phoenix Gettext internationalization
 * 
 * Gettext provides internationalization (i18n) support for Phoenix applications.
 * This extern allows Haxe code to use translated strings while the actual
 * Gettext module remains as manual Elixir infrastructure.
 * 
 * Usage:
 * ```haxe
 * import phoenix.Gettext;
 * 
 * var message = Gettext.gettext("Hello, world!");
 * var plural = Gettext.ngettext("1 item", "%{count} items", itemCount);
 * ```
 */
@:native("TodoAppWeb.Gettext")
extern class Gettext {
    /**
     * Get a translated string
     * @param msgid The message ID to translate
     * @return The translated string
     */
    static function gettext(msgid: String): String;
    
    /**
     * Get a translated string with interpolation
     * @param msgid The message ID to translate
     * @param bindings Map of variable names to values for interpolation
     * @return The translated string with interpolated values
     */
    static function gettext(msgid: String, bindings: Term): String;
    
    /**
     * Get a pluralized translated string
     * @param singular The singular form of the message
     * @param plural The plural form of the message
     * @param n The count to determine singular vs plural
     * @return The appropriate translated string based on count
     */
    static function ngettext(singular: String, plural: String, n: Int): String;
    
    /**
     * Get a pluralized translated string with interpolation
     * @param singular The singular form of the message
     * @param plural The plural form of the message
     * @param n The count to determine singular vs plural
     * @param bindings Map of variable names to values for interpolation
     * @return The appropriate translated string with interpolations
     */
    static function ngettext(singular: String, plural: String, n: Int, bindings: Term): String;
    
    /**
     * Get a domain-specific translated string
     * @param domain The translation domain (e.g., "errors", "forms")
     * @param msgid The message ID to translate
     * @return The translated string from the specified domain
     */
    static function dgettext(domain: String, msgid: String): String;
    
    /**
     * Get a domain-specific translated string with interpolation
     * @param domain The translation domain
     * @param msgid The message ID to translate
     * @param bindings Map of variable names to values for interpolation
     * @return The translated string with interpolated values
     */
    static function dgettext(domain: String, msgid: String, bindings: Term): String;
    
    /**
     * Get a domain-specific pluralized translated string
     * @param domain The translation domain
     * @param singular The singular form of the message
     * @param plural The plural form of the message
     * @param n The count to determine singular vs plural
     * @return The appropriate translated string based on count
     */
    static function dngettext(domain: String, singular: String, plural: String, n: Int): String;
    
    /**
     * Get a domain-specific pluralized translated string with interpolation
     * @param domain The translation domain
     * @param singular The singular form of the message
     * @param plural The plural form of the message
     * @param n The count to determine singular vs plural
     * @param bindings Map of variable names to values for interpolation
     * @return The appropriate translated string with interpolations
     */
    static function dngettext(domain: String, singular: String, plural: String, n: Int, bindings: Term): String;
}
