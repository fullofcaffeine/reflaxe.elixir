defmodule Changeset_Impl_ do
  def _new(data, params) do
    this1 = %{:data => data, :params => params, :errors => [], :valid => true, :required => [], :action => :none}
    this1
  end
  def create(data, params) do
    _new(data, params)
  end
  def validate_required(this1, _fields) do
    create(this1.data, this1.params)
  end
  def validate_length(this1, _field, _opts) do
    create(this1.data, this1.params)
  end
end