defmodule Main do
  def string_map() do
    map = %{}
    map = Map.put(map, "one", 1)
    map = Map.put(map, "two", 2)
    map = Map.put(map, "three", 3)

    Log.trace("Value of \"two\": #{Map.get(map, "two")}", %{:file_name => "Main.hx", :line_number => 18, :class_name => "Main", :method_name => "stringMap"})
    Log.trace("Value of \"four\": #{Map.get(map, "four")}", %{:file_name => "Main.hx", :line_number => 19, :class_name => "Main", :method_name => "stringMap"})

    Log.trace("Has \"one\": #{Map.has_key?(map, "one")}", %{:file_name => "Main.hx", :line_number => 22, :class_name => "Main", :method_name => "stringMap"})
    Log.trace("Has \"four\": #{Map.has_key?(map, "four")}", %{:file_name => "Main.hx", :line_number => 23, :class_name => "Main", :method_name => "stringMap"})

    map = Map.delete(map, "two")
    Log.trace("After remove, has \"two\": #{Map.has_key?(map, "two")}", %{:file_name => "Main.hx", :line_number => 27, :class_name => "Main", :method_name => "stringMap"})

    Log.trace("Iterating string map:", %{:file_name => "Main.hx", :line_number => 30, :class_name => "Main", :method_name => "stringMap"})
    Enum.each(map, fn {key, value} ->
      Log.trace("  #{key} => #{value}", %{:file_name => "Main.hx", :line_number => 32, :class_name => "Main", :method_name => "stringMap"})
    end)

    map = %{}
    keys = Map.keys(map)
    Log.trace("After clear, keys: #{inspect(keys)}", %{:file_name => "Main.hx", :line_number => 37, :class_name => "Main", :method_name => "stringMap"})
  end

  def int_map() do
    map = %{}
    map = Map.put(map, 1, "first")
    map = Map.put(map, 2, "second")
    map = Map.put(map, 10, "tenth")
    map = Map.put(map, 100, "hundredth")

    Log.trace("Int map values:", %{:file_name => "Main.hx", :line_number => 49, :class_name => "Main", :method_name => "intMap"})
    Enum.each(map, fn {key, value} ->
      Log.trace("  #{key} => #{value}", %{:file_name => "Main.hx", :line_number => 51, :class_name => "Main", :method_name => "intMap"})
    end)

    keys = Map.keys(map)
    values = Map.values(map)
    Log.trace("Keys: #{inspect(keys)}", %{:file_name => "Main.hx", :line_number => 57, :class_name => "Main", :method_name => "intMap"})
    Log.trace("Values: #{inspect(values)}", %{:file_name => "Main.hx", :line_number => 58, :class_name => "Main", :method_name => "intMap"})
  end

  def object_map() do
    map = %{}
    obj1 = %{id: 1}
    obj2 = %{id: 2}
    map = Map.put(map, obj1, "Object 1")
    map = Map.put(map, obj2, "Object 2")

    Log.trace("Object 1 value: #{Map.get(map, obj1)}", %{:file_name => "Main.hx", :line_number => 71, :class_name => "Main", :method_name => "objectMap"})
    Log.trace("Object 2 value: #{Map.get(map, obj2)}", %{:file_name => "Main.hx", :line_number => 72, :class_name => "Main", :method_name => "objectMap"})

    obj3 = %{id: 1}
    Log.trace("New {id: 1} value: #{Map.get(map, obj3)}", %{:file_name => "Main.hx", :line_number => 76, :class_name => "Main", :method_name => "objectMap"})
  end

  def map_literals() do
    colors = %{
      "red" => 0xFF0000,
      "green" => 0x00FF00,
      "blue" => 0x0000FF
    }

    Log.trace("Color values:", %{:file_name => "Main.hx", :line_number => 88, :class_name => "Main", :method_name => "mapLiterals"})
    Enum.each(colors, fn {color, value} ->
      Log.trace("  #{color} => ##{Integer.to_string(value, 16)}", %{:file_name => "Main.hx", :line_number => 90, :class_name => "Main", :method_name => "mapLiterals"})
    end)

    squares = %{
      1 => 1,
      2 => 4,
      3 => 9,
      4 => 16,
      5 => 25
    }

    Log.trace("Squares:", %{:file_name => "Main.hx", :line_number => 103, :class_name => "Main", :method_name => "mapLiterals"})
    Enum.each(squares, fn {n, square} ->
      Log.trace("  #{n}² = #{square}", %{:file_name => "Main.hx", :line_number => 105, :class_name => "Main", :method_name => "mapLiterals"})
    end)
  end

  def nested_maps() do
    users = %{
      "alice" => %{
        "age" => 30,
        "email" => "alice@example.com",
        "active" => true
      },
      "bob" => %{
        "age" => 25,
        "email" => "bob@example.com",
        "active" => false
      }
    }

    Log.trace("User data:", %{:file_name => "Main.hx", :line_number => 128, :class_name => "Main", :method_name => "nestedMaps"})
    Enum.each(users, fn {username, data} ->
      Log.trace("  #{username}: age=#{data["age"]}, email=#{data["email"]}, active=#{data["active"]}",
                %{:file_name => "Main.hx", :line_number => 130, :class_name => "Main", :method_name => "nestedMaps"})
    end)
  end

  def map_transformations() do
    original = %{
      "a" => 1,
      "b" => 2,
      "c" => 3,
      "d" => 4
    }

    # Double all values
    doubled = original
      |> Enum.map(fn {k, v} -> {k, v * 2} end)
      |> Enum.into(%{})

    Log.trace("Doubled values:", %{:file_name => "Main.hx", :line_number => 153, :class_name => "Main", :method_name => "mapTransformations"})
    Enum.each(doubled, fn {key, value} ->
      Log.trace("  #{key} => #{value}", %{:file_name => "Main.hx", :line_number => 155, :class_name => "Main", :method_name => "mapTransformations"})
    end)

    # Filter values > 2
    filtered = original
      |> Enum.filter(fn {_k, v} -> v > 2 end)
      |> Enum.into(%{})

    Log.trace("Filtered (value > 2):", %{:file_name => "Main.hx", :line_number => 167, :class_name => "Main", :method_name => "mapTransformations"})
    Enum.each(filtered, fn {key, value} ->
      Log.trace("  #{key} => #{value}", %{:file_name => "Main.hx", :line_number => 169, :class_name => "Main", :method_name => "mapTransformations"})
    end)

    # Merge maps
    map1 = %{"a" => 1, "b" => 2}
    map2 = %{"c" => 3, "d" => 4, "a" => 10}
    merged = Map.merge(map1, map2)

    Log.trace("Merged maps:", %{:file_name => "Main.hx", :line_number => 184, :class_name => "Main", :method_name => "mapTransformations"})
    Enum.each(merged, fn {key, value} ->
      Log.trace("  #{key} => #{value}", %{:file_name => "Main.hx", :line_number => 186, :class_name => "Main", :method_name => "mapTransformations"})
    end)
  end

  def enum_map() do
    map = %{
      :red => "FF0000",
      :green => "00FF00",
      :blue => "0000FF"
    }

    Log.trace("Enum map:", %{:file_name => "Main.hx", :line_number => 198, :class_name => "Main", :method_name => "enumMap"})
    Enum.each(map, fn {color, hex} ->
      Log.trace("  #{color} => ##{hex}", %{:file_name => "Main.hx", :line_number => 200, :class_name => "Main", :method_name => "enumMap"})
    end)

    if Map.has_key?(map, :red) do
      Log.trace("Red color code: ##{Map.get(map, :red)}", %{:file_name => "Main.hx", :line_number => 205, :class_name => "Main", :method_name => "enumMap"})
    end
  end

  def process_map(input) do
    input
    |> Enum.map(fn {k, v} -> {String.upcase(k), v * v} end)
    |> Enum.into(%{})
  end

  def main() do
    Log.trace("=== String Map ===", %{:file_name => "Main.hx", :line_number => 220, :class_name => "Main", :method_name => "main"})
    string_map()

    Log.trace("\n=== Int Map ===", %{:file_name => "Main.hx", :line_number => 223, :class_name => "Main", :method_name => "main"})
    int_map()

    Log.trace("\n=== Object Map ===", %{:file_name => "Main.hx", :line_number => 226, :class_name => "Main", :method_name => "main"})
    object_map()

    Log.trace("\n=== Map Literals ===", %{:file_name => "Main.hx", :line_number => 229, :class_name => "Main", :method_name => "main"})
    map_literals()

    Log.trace("\n=== Nested Maps ===", %{:file_name => "Main.hx", :line_number => 232, :class_name => "Main", :method_name => "main"})
    nested_maps()

    Log.trace("\n=== Map Transformations ===", %{:file_name => "Main.hx", :line_number => 235, :class_name => "Main", :method_name => "main"})
    map_transformations()

    Log.trace("\n=== Enum Map ===", %{:file_name => "Main.hx", :line_number => 238, :class_name => "Main", :method_name => "main"})
    enum_map()

    Log.trace("\n=== Map Functions ===", %{:file_name => "Main.hx", :line_number => 241, :class_name => "Main", :method_name => "main"})
    input = %{"x" => 10, "y" => 20, "z" => 30}
    output = process_map(input)

    Enum.each(output, fn {key, value} ->
      Log.trace("  #{key} => #{value}", %{:file_name => "Main.hx", :line_number => 246, :class_name => "Main", :method_name => "main"})
    end)
  end
end