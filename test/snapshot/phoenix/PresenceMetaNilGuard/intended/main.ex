defmodule Main do
  def main() do

  end
  def needs_coalesce_one_liner(socket, key) do
    current_meta = maybe_get_meta()
    if (Kernel.is_nil(current_meta)) do
      Presence.track(self(), socket, key, %{})
    end
    current_meta = %{}
    Map.get(current_meta, :user_name)
  end
  def needs_coalesce_do_end(socket, key) do
    current_meta = maybe_get_meta()
    if (Kernel.is_nil(current_meta)) do
      Presence.track(self(), socket, key, %{})
    end
    current_meta = %{}
    Map.get(current_meta, :online_at)
  end
  def negative_reassign_prevents_injection(socket, key) do
    current_meta = maybe_get_meta()
    if (Kernel.is_nil(current_meta)) do
      Presence.track(self(), socket, key, %{})
    end
    current_meta = %{online_at: 0, user_name: "x"}
    current_meta.online_at
  end
  def negative_no_field_access(socket, key) do
    current_meta = maybe_get_meta()
    if (Kernel.is_nil(current_meta)) do
      Presence.track(self(), socket, key, %{})
    end
  end
  defp maybe_get_meta() do
    nil
  end
end
