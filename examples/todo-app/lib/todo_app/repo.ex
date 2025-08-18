defmodule TodoApp.Repo do
  @moduledoc """
    TodoApp database repository
    Provides type-safe database access using Ecto patterns

    This module is compiled to TodoApp.Repo with proper Ecto.Repo usage
    and PostgreSQL adapter configuration for the todo-app application.
  """
  use Ecto.Repo,
    otp_app: :todoapp,
    adapter: Ecto.Adapters.Postgres
end