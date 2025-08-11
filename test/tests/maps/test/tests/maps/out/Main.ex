defmodule Main do
  @moduledoc """
  Main module generated from Haxe
  
  
 * Map/Dictionary test case
 * Tests various map types and operations
 
  """

  # Static functions
  @doc "Function string_map"
  @spec string_map() :: TAbstract(Void,[]).t()
  def string_map() do
    # TODO: Implement function body
    nil
  end

  @doc "Function int_map"
  @spec int_map() :: TAbstract(Void,[]).t()
  def int_map() do
    # TODO: Implement function body
    nil
  end

  @doc "Function object_map"
  @spec object_map() :: TAbstract(Void,[]).t()
  def object_map() do
    # TODO: Implement function body
    nil
  end

  @doc "Function map_literals"
  @spec map_literals() :: TAbstract(Void,[]).t()
  def map_literals() do
    # TODO: Implement function body
    nil
  end

  @doc "Function nested_maps"
  @spec nested_maps() :: TAbstract(Void,[]).t()
  def nested_maps() do
    # TODO: Implement function body
    nil
  end

  @doc "Function map_transformations"
  @spec map_transformations() :: TAbstract(Void,[]).t()
  def map_transformations() do
    # TODO: Implement function body
    nil
  end

  @doc "Function enum_map"
  @spec enum_map() :: TAbstract(Void,[]).t()
  def enum_map() do
    # TODO: Implement function body
    nil
  end

  @doc "Function process_map"
  @spec process_map(TType(Map,[TInst(String,[]),TAbstract(Int,[])]).t()) :: TType(Map,[TInst(String,[]),TInst(String,[])]).t()
  def process_map(arg0) do
    # TODO: Implement function body
    nil
  end

  @doc "Function main"
  @spec main() :: TAbstract(Void,[]).t()
  def main() do
    # TODO: Implement function body
    nil
  end

end


defmodule Color do
  @moduledoc """
  Color enum generated from Haxe
  
  This module provides tagged tuple constructors and pattern matching helpers.
  """

  @type t() ::
    :red |
    :green |
    :blue

  @doc "Creates red enum value"
  @spec red() :: :red
  def red(), do: :red

  @doc "Creates green enum value"
  @spec green() :: :green
  def green(), do: :green

  @doc "Creates blue enum value"
  @spec blue() :: :blue
  def blue(), do: :blue

  # Predicate functions for pattern matching
  @doc "Returns true if value is red variant"
  @spec is_red(t()) :: boolean()
  def is_red(:red), do: true
  def is_red(_), do: false

  @doc "Returns true if value is green variant"
  @spec is_green(t()) :: boolean()
  def is_green(:green), do: true
  def is_green(_), do: false

  @doc "Returns true if value is blue variant"
  @spec is_blue(t()) :: boolean()
  def is_blue(:blue), do: true
  def is_blue(_), do: false

end
