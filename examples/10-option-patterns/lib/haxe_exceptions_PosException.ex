defmodule PosException do
  use Bitwise
  @moduledoc """
  PosException module generated from Haxe
  
  
	An exception that carry position information of a place where it was created.

  """

  # Instance functions
  @doc "Returns exception "
  @spec to_string() :: String.t()
  def to_string() do
    "" <> __MODULE__.toString() <> " in " <> __MODULE__.pos_infos.class_name <> "." <> __MODULE__.pos_infos.method_name <> " at " <> __MODULE__.pos_infos.file_name <> ":" <> Integer.to_string(__MODULE__.pos_infos.line_number)
  end

end
