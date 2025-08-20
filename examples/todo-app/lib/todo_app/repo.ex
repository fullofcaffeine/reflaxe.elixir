defmodule TodoApp.Repo do
  @moduledoc """
    TodoApp database repository
    Provides type-safe database access using Ecto patterns

    This module is compiled to TodoApp.Repo with proper Ecto.Repo usage
    and PostgreSQL adapter configuration for the todo-app application.

    ## Directory Structure Note

    This file is located in `server/infrastructure/` which differs from Phoenix conventions.
    Standard Phoenix would place this directly under the app namespace (TodoApp.Repo).

    We use the @:native("TodoApp.Repo") annotation to ensure the generated module follows
    Phoenix conventions regardless of the Haxe package structure. This allows us to organize
    our Haxe code with more explicit architectural boundaries (infrastructure, domain, etc.)
    while still generating idiomatic Phoenix/Elixir modules.

    Phoenix convention: lib/todo_app/repo.ex
    Our structure: server/infrastructure/Repo.hx → compiles to → lib/todo_app/repo.ex
  """
  use Ecto.Repo,
    otp_app: :todo_app,
    adapter: Ecto.Adapters.Postgres
end