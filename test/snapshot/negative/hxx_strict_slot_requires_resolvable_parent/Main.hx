package;

import HXX;

typedef Assigns = {
    var ok: Bool;
}

/**
 * Negative test:
 * - Under -D hxx_strict_slots, slot tags require a resolvable parent component definition
 *   so slot existence/props can be type-checked.
 */
class Main {
    public static function render(assigns: Assigns): String {
        return HXX.hxx('<.unknown>
          <:header>Hi</:header>
        </.unknown>');
    }

    public static function main() {}
}

