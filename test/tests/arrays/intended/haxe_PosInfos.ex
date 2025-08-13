@typedoc """

	`PosInfos` is a magic type which can be used to generate position information
	into the output for debugging use.

	If a function has a final optional argument of this type, i.e.
	`(..., ?pos:haxe.PosInfos)`, each call to that function which does not assign
	a value to that argument has its position added as call argument.

	This can be used to track positions of calls in e.g. a unit testing
	framework.

"""
@type pos_infos :: %{
  class_name: String.t(),
  optional(:custom_params) => list(any()) | nil,
  file_name: String.t(),
  line_number: integer(),
  method_name: String.t()
}