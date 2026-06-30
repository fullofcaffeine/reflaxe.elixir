# Tutorial: Gradual Adoption in an Existing Phoenix App

This tutorial starts with a normal Phoenix app and adds Haxe incrementally:

- keep the existing Phoenix app, router, controllers, and supervision tree
- compile Haxe modules into an isolated namespace (`MyAppHx.*`)
- call a typed Haxe domain module from existing Elixir code
- add one Haxe-authored LiveView route without rewriting the app
- verify the integration through tests

For the broader reference guide, see `docs/06-guides/PHOENIX_GRADUAL_ADOPTION.md`.

## 1) Start From a Normal Phoenix App

Create or enter an existing Phoenix project:

```bash
mix phx.new my_app
cd my_app
mix deps.get
```

If this is an existing app, make sure it already compiles before adding Haxe:

```bash
mix test
```

## 2) Add Reflaxe.Elixir and Scaffold Haxe

Add Reflaxe.Elixir as a build-time dependency:

```elixir
# mix.exs
defp deps do
  [
    {:reflaxe_elixir,
     github: "fullofcaffeine/reflaxe.elixir",
     tag: "<RELEASE_TAG>",
     runtime: false}
  ]
end
```

Fetch deps, then run the in-place Phoenix scaffold:

```bash
mix deps.get
mix haxe.gen.project --phoenix --force
```

What this gives you:

- `src_haxe/<app>_hx/**` for Haxe source
- `build.hxml` for server-side Haxe -> Elixir compilation
- `build-tests.hxml` for Haxe-authored ExUnit tests
- `lib/<app>_hx/**` as the generated Elixir output namespace
- Phoenix client JS wiring for Haxe/Genes hooks when needed

If the task reports that it skipped Phoenix client wiring because your app shape is customized, run the client scaffold explicitly:

```bash
mix haxe.phoenix.scaffold
```

For heavily customized Phoenix templates, use warn-only mode to keep the migration exploratory:

```bash
mix haxe.phoenix.scaffold --warn-only
```

During gradual adoption, keep generated modules isolated. For an app named `MyApp`, the default shape is:

```text
src_haxe/my_app_hx/**   # Haxe source
lib/my_app_hx/**        # generated Elixir
MyAppHx.*               # generated Elixir modules
```

That isolation keeps reviews small and makes rollback simple: remove the route/callsite, then remove the generated namespace.

## 3) Add a Typed Haxe Domain Module

Create `src_haxe/my_app_hx/pricing/DiscountRules.hx`:

```haxe
package my_app_hx.pricing;

@:module
class DiscountRules {
  public static function percentForCustomer(totalCents: Int, isReturningCustomer: Bool): Int {
    if (totalCents >= 20000) {
      return 15;
    }

    if (isReturningCustomer && totalCents >= 5000) {
      return 10;
    }

    return 0;
  }
}
```

Add it to `build.hxml`:

```hxml
my_app_hx.pricing.DiscountRules
```

Compile:

```bash
mix compile.haxe --force
```

The generated Elixir module is now callable as `MyAppHx.Pricing.DiscountRules`.

## 4) Call the Haxe Module From Existing Elixir

Use the generated module from a normal Phoenix controller, context, or LiveView. For example:

```elixir
defmodule MyAppWeb.DiscountController do
  use MyAppWeb, :controller

  def show(conn, %{"total_cents" => total}) do
    total_cents = String.to_integer(total)
    percent = MyAppHx.Pricing.DiscountRules.percent_for_customer(total_cents, true)

    json(conn, %{discount_percent: percent})
  end
end
```

Add the route:

```elixir
# lib/my_app_web/router.ex
scope "/", MyAppWeb do
  pipe_through :browser

  get "/discount", DiscountController, :show
end
```

This is the first safe migration step: Haxe owns pure domain logic, while Phoenix routing and request handling stay exactly where the team expects them.

## 5) Verify the Elixir Call Path

Use a regular Phoenix test first:

```elixir
defmodule MyAppWeb.DiscountControllerTest do
  use MyAppWeb.ConnCase, async: true

  test "returns discount from Haxe rules", %{conn: conn} do
    conn = get(conn, ~p"/discount?total_cents=20000")

    assert %{"discount_percent" => 15} = json_response(conn, 200)
  end
end
```

Run:

```bash
mix test test/my_app_web/controllers/discount_controller_test.exs
```

This proves the generated Haxe module is loaded by the Phoenix app and called through a real request path.

## 6) Add a Haxe-Authored ExUnit Test

Add `test_haxe/pricing/DiscountRulesTest.hx`:

```haxe
package pricing;

import exunit.TestCase;
import exunit.Assert.*;
import my_app_hx.pricing.DiscountRules;

@:exunit
class DiscountRulesTest extends TestCase {
  @:test
  public function test_large_orders_get_15_percent(): Void {
    assertEqual(15, DiscountRules.percentForCustomer(20000, false));
  }

  @:test
  public function test_returning_customers_get_10_percent(): Void {
    assertEqual(10, DiscountRules.percentForCustomer(5000, true));
  }
}
```

Add the test module to `build-tests.hxml` if the scaffold did not already include a wildcard or explicit test entry:

```hxml
pricing.DiscountRulesTest
```

Run:

```bash
mix test
```

The scaffolded Mix aliases compile Haxe tests into `test/generated/**/*.exs`, and `test/test_helper.exs` requires them before ExUnit runs.

## 7) Add One Haxe LiveView Without Rewriting the App

Generate a Haxe LiveView:

```bash
mix haxe.gen.live DiscountLive --assigns "count:Int" --events "refresh" --haxe-dir src_haxe/my_app_hx/live
```

Adjust the generated file package to match the directory if needed:

```haxe
package my_app_hx.live;
```

Add it to `build.hxml`:

```hxml
my_app_hx.live.DiscountLive
```

Compile:

```bash
mix compile.haxe --force
```

Route to the generated LiveView from the existing Elixir router:

```elixir
# lib/my_app_web/router.ex
scope "/", MyAppWeb do
  pipe_through :browser

  live "/discount-live", DiscountLive
end
```

With `-D app_name=MyApp`, the generated Haxe LiveView uses `@:liveview` to derive
the normal Phoenix module `MyAppWeb.DiscountLive`. Use class-level `@:native(...)`
only when you need an exact legacy or interop module name.

## 8) Verify the LiveView Route

Use Phoenix LiveViewTest:

```elixir
defmodule MyAppWeb.DiscountLiveTest do
  use MyAppWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  test "renders generated Haxe LiveView", %{conn: conn} do
    {:ok, _view, html} = live(conn, ~p"/discount-live")

    assert html =~ "DiscountLive"
    assert html =~ "Count:"
  end
end
```

Run:

```bash
mix test test/my_app_web/live/discount_live_test.exs
```

## 9) Keep the Boundary Clean

Use this rule of thumb while migrating:

| Step | Good gradual-adoption boundary |
| --- | --- |
| First Haxe module | Pure domain logic called from Elixir |
| First Phoenix surface | One new LiveView route, not a rewritten router |
| Existing Elixir APIs | Typed extern + optional Haxe wrapper |
| Client hooks | Use `mix haxe.phoenix.scaffold` and keep Phoenix JS shape recognizable |
| Verification | ConnTest/LiveViewTest first, Playwright only for critical browser behavior |

Avoid:

- moving generated files into existing hand-written namespaces too early
- using `__elixir__()` for app code when a typed extern/wrapper would work
- adding `Dynamic` to make boundary types compile
- rewriting a whole Phoenix app before the first small Haxe module is proven

## Working Reference

The closest checked-in reference is `examples/13-elixir-first-liveview/`:

- Haxe-authored LiveViews compiled into a Phoenix app
- typed interop with a hand-written Elixir module
- Haxe-authored ExUnit tests
- Phoenix LiveView integration tests
- Haxe/Genes client boot wiring

For realtime chat, compare the two chat tutorials:

- `docs/06-guides/PHOENIX_CHAT_TUTORIAL.md` for hybrid adoption
- `docs/06-guides/PHOENIX_CHAT_TUTORIAL_HAXE_FIRST.md` for Haxe-first server modules
