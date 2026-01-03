defmodule TodoApp.InviteEmail do
  @moduledoc """
  Minimal invite email delivery for the todo-app showcase.

  Uses Swoosh with the Local adapter so invites can be previewed in the browser
  during development and E2E runs (see `/dev/mailbox`).
  """

  import Swoosh.Email

  @from {"TodoApp", "noreply@todo-app.local"}

  @spec deliver_invite(String.t(), String.t(), String.t(), String.t(), String.t() | nil) :: boolean()
  def deliver_invite(to_email, org_slug, org_name, role, inviter_name) do
    email =
      new()
      |> to(to_email)
      |> from(@from)
      |> subject("You're invited to #{org_name}")
      |> text_body(text_body(to_email, org_slug, org_name, role, inviter_name))

    case TodoApp.Mailer.deliver(email) do
      {:ok, _} -> true
      {:error, _} -> false
    end
  end

  defp text_body(to_email, org_slug, org_name, role, inviter_name) do
    inviter_label =
      case inviter_name do
        nil -> "An admin"
        "" -> "An admin"
        name -> name
      end

    """
    Hi,

    #{inviter_label} invited you to #{org_name} (#{org_slug}) as #{role}.

    Sign in at #{login_url()} using #{to_email} to accept the invite.
    """
  end

  defp login_url do
    base =
      case System.get_env("BASE_URL") do
        nil -> nil
        "" -> nil
        url -> url
      end ||
        case System.get_env("PORT") do
          nil -> "http://localhost:4000"
          "" -> "http://localhost:4000"
          port -> "http://localhost:" <> port
        end

    base <> "/login"
  end
end
