defmodule Changeset_Impl_ do
  def _new(_data, _params) do
    this1 = Ecto.Changeset.change(data, params)
    this1
  end
end