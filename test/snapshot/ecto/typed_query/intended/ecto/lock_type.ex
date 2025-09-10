defmodule Ecto.LockType do
  def for_update() do
    {:ForUpdate}
  end
  def for_share() do
    {:ForShare}
  end
  def for_key_share() do
    {:ForKeyShare}
  end
  def for_no_key_update() do
    {:ForNoKeyUpdate}
  end
end