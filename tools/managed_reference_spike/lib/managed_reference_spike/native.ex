defmodule ManagedReferenceSpike.Native do
  @moduledoc false

  @on_load :load_nif

  def load_nif do
    case :code.priv_dir(:managed_reference_spike) do
      {:error, reason} -> {:error, reason}
      dir -> :erlang.load_nif(:filename.join(dir, ~c"managed_reference_spike"), 0)
    end
  end

  def new_object(_value), do: not_loaded()
  def clone(_reference), do: not_loaded()
  def same(_left, _right), do: not_loaded()
  def get(_reference), do: not_loaded()
  def put(_reference, _value), do: not_loaded()
  def increment(_reference, _delta), do: not_loaded()
  def set_strong_nested(_reference, _nested), do: not_loaded()
  def set_weak_nested(_reference, _nested), do: not_loaded()
  def strong_ids(_reference), do: not_loaded()
  def weak_ids(_reference), do: not_loaded()
  def lease_for(_reference, _object_id), do: not_loaded()
  def descriptor(_reference), do: not_loaded()
  def resolve(_node_token, _object_id), do: not_loaded()
  def object_info(_object_id), do: not_loaded()
  def stats(), do: not_loaded()
  def collect(), do: not_loaded()
  def reset(), do: not_loaded()
  def new_hybrid_lease(_owner, _object_id), do: not_loaded()
  def hybrid_id(_lease), do: not_loaded()
  def nif_info(), do: not_loaded()

  defp not_loaded, do: :erlang.nif_error(:nif_not_loaded)
end
