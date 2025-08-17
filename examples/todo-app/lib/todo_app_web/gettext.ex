defmodule TodoAppWeb.Gettext do
  @moduledoc """
  A module providing Internationalization with a gettext-based API.
  """
  use Gettext, otp_app: :todo_app
end