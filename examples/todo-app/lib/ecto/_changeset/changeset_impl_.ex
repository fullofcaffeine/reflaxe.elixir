defmodule Changeset_Impl_ do
  @data nil
  @params nil
  @errors nil
  @valid nil
  def _new(data, params) do
    this1 = nil
    this1 = %{:data => data, :params => params, :errors => [], :valid => true, :required => [], :action => :none}
    this1
  end
  defp get_data(this1) do
    this1.data
  end
  defp get_params(this1) do
    this1.params
  end
  defp get_errors(this1) do
    this1.errors
  end
  defp get_valid(this1) do
    this1.valid
  end
  def create(data, params) do
    Changeset_Impl_._new(data, params)
  end
  def validate_required(this1, _fields) do
    Changeset_Impl_.create(this1.data, this1.params)
  end
  def validate_length(this1, _field, _opts) do
    Changeset_Impl_.create(this1.data, this1.params)
  end
end