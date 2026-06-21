defmodule HeexTemplatesTest do
  use ExUnit.Case, async: true

  defp render_to_html(rendered) do
    rendered
    |> Phoenix.HTML.Safe.to_iodata()
    |> IO.iodata_to_binary()
  end

  test "user profile renders nested post helpers" do
    assigns = %{
      user: %{
        name: "Ada",
        email: "ada@example.com",
        active: true,
        inserted_at: "2026-01-01"
      },
      posts: [
        %{
          title: "First post",
          content: "Hello from HXX",
          view_count: 3,
          inserted_at: "2026-01-02"
        }
      ]
    }

    html =
      assigns
      |> UserProfile.render()
      |> render_to_html()

    assert html =~ "Welcome, Ada!"
    assert html =~ "ada@example.com"
    assert html =~ "Recent Posts (1)"
    assert html =~ "First post"
    assert html =~ "3 views"
    assert html =~ "Edit Profile"
    assert html =~ "Settings"
  end

  test "user profile renders the empty-post state" do
    assigns = %{
      user: %{
        name: "Grace",
        email: "grace@example.com",
        active: false,
        inserted_at: "2026-01-01"
      },
      posts: []
    }

    html =
      assigns
      |> UserProfile.render()
      |> render_to_html()

    assert html =~ "Welcome, Grace!"
    assert html =~ "Offline"
    assert html =~ "No posts yet!"
  end

  test "search form renders active filter helpers" do
    html =
      %{query: "ada", filter: "active", active_filters: ["admin", "active"]}
      |> FormComponents.search_form()
      |> render_to_html()

    assert html =~ ~s(value="ada")
    assert html =~ "admin"
    assert html =~ "active"
    assert html =~ "Search"
    assert html =~ "Clear all"
  end
end
