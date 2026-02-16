defmodule Main_Fields_ do
  def initial_query() do
    "SELECT * FROM users"
  end
  def add_filter(query, field, value) do
    "#{query} WHERE #{field} = #{value}"
  end
  def add_sort(query, field) do
    "#{query} ORDER BY #{field}"
  end
end
