defmodule ElixirFirstLiveview.SearchDomain do
  def apply(query, catalog) do
    if Kernel.is_nil(query) do
      {:error, "query cannot be null"}
    else
      if Kernel.is_nil(catalog) do
        {:error, "catalog cannot be null"}
      else
        normalized = String.trim(query)

        if normalized == "" do
          {:ok, %{query: "", visible: catalog, result_count: length(catalog)}}
        else
          needle = String.downcase(normalized)

          visible =
            Enum.filter(catalog, fn item ->
              not Kernel.is_nil(item) and String.contains?(String.downcase(item), needle)
            end)

          {:ok, %{query: normalized, visible: visible, result_count: length(visible)}}
        end
      end
    end
  end
end
