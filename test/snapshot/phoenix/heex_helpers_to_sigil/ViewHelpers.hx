package;

/**
 * Heex helpers migration test
 *
 * WHAT
 * - Ensure helper functions that return string HTML are converted to ~H and
 *   no Phoenix.HTML.raw wrapper is applied.
 */
class ViewHelpers {
    public static function panel(assigns: Dynamic): String {
        return "<div class=\"panel\"><h1>Static</h1></div>";
    }
}

