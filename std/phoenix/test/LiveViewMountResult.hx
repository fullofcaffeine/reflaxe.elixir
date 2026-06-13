package phoenix.test;

import elixir.Tuple;
import elixir.types.Term;
import phoenix.test.LiveView;

/**
 * Typed wrapper for Phoenix.LiveViewTest mount results.
 *
 * Phoenix.LiveViewTest.live/2 returns the canonical Elixir tuple:
 *
 * ```elixir
 * {:ok, view, html}
 * ```
 *
 * This abstract keeps that raw tuple representation (`from Term` / `to Term`) while
 * giving Haxe-authored ExUnit tests named accessors instead of tuple-position reads.
 */
abstract LiveViewMountResult(Term) from Term to Term {
	public inline function view():LiveView {
		return cast Tuple.elem(this, 1);
	}

	public inline function initialHtml():String {
		return cast Tuple.elem(this, 2);
	}

	public inline function raw():Term {
		return this;
	}
}
