defmodule Main do
  def main() do
    query1 = Main_Fields_.initial_query()
    apply_filter = true
    _ = if (apply_filter) do
      Main_Fields_.add_filter(query1, "status", "active")
    else
      query1
    end
    query2 = Main_Fields_.initial_query()
    filter_by_status = true
    sort_by_name = true
    query2 = if (filter_by_status) do
      Main_Fields_.add_filter(query2, "status", "active")
    else
      query2
    end
    _ = if (sort_by_name) do
      Main_Fields_.add_sort(query2, "name")
    else
      query2
    end
    query3 = Main_Fields_.initial_query()
    apply_advanced_filters = true
    _ = if (apply_advanced_filters) do
      query3 = Main_Fields_.add_filter(query3, "role", "admin")
      include_inactive = false
      if (not include_inactive) do
        Main_Fields_.add_filter(query3, "active", "true")
      else
        query3
      end
    else
      query3
    end
    query4 = Main_Fields_.initial_query()
    use_special_query = false
    _ = if (use_special_query) do
      Main_Fields_.add_filter(query4, "special", "yes")
    else
      Main_Fields_.add_filter(query4, "standard", "yes")
    end
    nil
  end
end
