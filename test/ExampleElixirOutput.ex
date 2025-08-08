# Example of expected Elixir output from our Haxe→Elixir compiler

# From a Haxe class like:
# class UserService {
#   var name: String;
#   var age: Int;
#   
#   public function new(name: String, age: Int) {
#     this.name = name;
#     this.age = age;
#   }
#   
#   public function greet(): String {
#     return "Hello, " + name;
#   }
#   
#   public static function create(): UserService {
#     return new UserService("Unknown", 0);
#   }
# }

defmodule UserService do
  @moduledoc """
  UserService module generated from Haxe
  """

  defstruct [name: nil, age: nil]

  # Static functions
  @doc "Generated from Haxe create"
  def create() do
    # TODO: Implement function body
    # new UserService("Unknown", 0)
    :ok
  end

  # Instance functions
  @doc "Generated from Haxe new"
  def __struct__(name, age) do
    # TODO: Implement function body
    # Constructor logic
    :ok
  end

  @doc "Generated from Haxe greet"
  def greet() do
    # TODO: Implement function body
    # "Hello, " + name
    :ok
  end
end

# From a Haxe enum like:
# enum Color {
#   Red;
#   Green;
#   Blue;
#   Custom(r: Int, g: Int, b: Int);
# }

defmodule Color do
  @moduledoc """
  Color enum generated from Haxe
  
  This module provides tagged tuple constructors for the Haxe enum.
  """

  @type t() :: 
    :red |
    :green |
    :blue |
    {:custom, any(), any(), any()}

  @doc "Creates red enum value"
  def red(), do: :red

  @doc "Creates green enum value"
  def green(), do: :green

  @doc "Creates blue enum value"
  def blue(), do: :blue

  @doc "Creates custom enum value with parameters"
  def custom(arg0, arg1, arg2) do
    {:custom, arg0, arg1, arg2}
  end

  @doc "Pattern match helper for enum values"
  def match(value, patterns) do
    case value do
      :red -> Map.get(patterns, :red, fn -> nil end).()
      :green -> Map.get(patterns, :green, fn -> nil end).()
      :blue -> Map.get(patterns, :blue, fn -> nil end).()
      {:custom, arg0, arg1, arg2} -> Map.get(patterns, :custom, fn _, _, _ -> nil end).(arg0, arg1, arg2)
      _ -> nil
    end
  end
end