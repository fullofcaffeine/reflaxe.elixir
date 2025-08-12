defmodule PosException do
  @moduledoc """
  PosException module generated from Haxe
  
  
	An exception that carry position information of a place where it was created.

  """

  # Instance functions
  @doc "
		Returns exception message.
	"
  @spec to_string() :: TInst(String,[]).t()
  def to_string() do
    "" + super().toString() + " in " + self().pos_infos.class_name + "." + self().pos_infos.method_name + " at " + self().pos_infos.file_name + ":" + self().pos_infos.line_number
  end

end
