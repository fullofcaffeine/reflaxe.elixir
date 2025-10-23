defmodule TodoApp.HealthTest do
  use ExUnit.Case, async: true
  import Phoenix.ConnTest
  @endpoint TodoAppWeb.Endpoint

  test "sanity" do
    assert 1 + 1 == 2
  end
end
