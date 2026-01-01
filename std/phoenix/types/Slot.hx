package phoenix.types;

import elixir.types.Term;

/**
 * Slot<EntryProps, Let>
 *
 * WHAT
 * - Compile-time marker type for Phoenix function component slots.
 *
 * WHY
 * - Slots are provided via HEEx slot tags (e.g. `<:header ...>...</:header>`) rather than
 *   normal component attributes.
 * - Having a dedicated marker type lets the compiler/linter discover declared slots from
 *   Haxe component assigns typedefs and provide TSX-like static checks.
 *
 * HOW
 * - In a `@:component` assigns type, declare slots like:
 *   `@:slot var header: Slot<HeaderSlotProps>;`
 * - `HeaderSlotProps` describes the slot entry attributes (the props allowed on `<:header ...>`).
 * - To enable TSX-like typing for `:let` bindings inside the slot content, add a second type parameter:
 *   `@:slot var header: Slot<HeaderSlotProps, HeaderLet>;`
 *   and the compiler will lint `headerLetVar.some_field` accesses within `<:header :let={headerLetVar}>...</:header>`.
 *
 * EXAMPLES
 * Haxe:
 *   typedef CardAssigns = {
 *     @:prop var title: String;
 *     @:slot var header: Slot<{ label: String }>;
 *   }
 * HEEx (HXX):
 *   <.card title="Hello">
 *     <:header label="Welcome!">
 *       <span>...</span>
 *     </:header>
 *   </.card>
 */
abstract Slot<TEntryProps, TLet = Term>(Term) from Term to Term {}
