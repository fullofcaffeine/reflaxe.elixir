defmodule Main do
  def main() do
    view = "live-view"
    keys_count = :count
    key = keys_count
    has_count = Phoenix.LiveViewTest.has_assign(view, key)
    key = keys_count
    count = Phoenix.LiveViewTest.get_assign(view, key)
    view = view |> Phoenix.LiveViewTest.render_click("increment") |> Phoenix.LiveViewTest.render_submit("search", %{query: "typed"})
    unsafe_search = "search"
    view = Phoenix.LiveViewTest.render_change(view, unsafe_search, %{query: "unsafe"})
    use_results(view, has_count, count)
  end
  defp use_results(view, has_count, count) do
    %{view: view, has_count: has_count, count: count}
  end
end
