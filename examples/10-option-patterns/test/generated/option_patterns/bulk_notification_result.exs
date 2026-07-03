defmodule OptionPatterns.BulkNotificationResult do
  def new(successful_param, failed_param) do
    struct = %{:__reflaxe_class__ => OptionPatterns.BulkNotificationResult, :successful => nil, :failed => nil}
    struct = %{struct | successful: successful_param}
    struct = %{struct | failed: failed_param}
    struct
  end
  def get_success_count(struct) do
    length(struct.successful)
  end
  def get_failure_count(struct) do
    length(struct.failed)
  end
  def get_total_count(struct) do
    apply(Map.get(struct, :__reflaxe_class__) || Map.get(struct, :__struct__), :get_success_count, [struct]) + apply(Map.get(struct, :__reflaxe_class__) || Map.get(struct, :__struct__), :get_failure_count, [struct])
  end
  def get_success_rate(struct) do
    total = apply(Map.get(struct, :__reflaxe_class__) || Map.get(struct, :__struct__), :get_total_count, [struct])
    if (total > 0) do
      Reflaxe.Elixir.HaxeFloat.divide(apply(Map.get(struct, :__reflaxe_class__) || Map.get(struct, :__struct__), :get_success_count, [struct]), total)
    else
      0
    end
  end
end
