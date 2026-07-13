defmodule HandwrittenCorpus.ElixirFirstLiveView.SearchDomain do
  def apply(query, catalog) when is_binary(query) and is_list(catalog) do
    normalized = String.trim(query)

    if normalized == "" do
      {:ok, %{query: "", visible: catalog, result_count: length(catalog)}}
    else
      needle = String.downcase(normalized)

      visible =
        Enum.filter(catalog, fn item ->
          is_binary(item) and String.contains?(String.downcase(item), needle)
        end)

      {:ok, %{query: normalized, visible: visible, result_count: length(visible)}}
    end
  end

  def apply(nil, _catalog), do: {:error, "query cannot be null"}
  def apply(_query, nil), do: {:error, "catalog cannot be null"}
end
