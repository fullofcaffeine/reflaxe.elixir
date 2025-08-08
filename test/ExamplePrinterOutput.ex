# Example output from ElixirPrinter - what our printer should generate

# From printClass("UserService", [field1, field2], [func1, func2])
defmodule UserService do
  @moduledoc """
  UserService module generated from Haxe
  """

  @type t() :: %__MODULE__{
    field0: any(),
    field1: any()
  }

  defstruct [field0: nil, field1: nil]

  # Instance functions
  @spec example_function() :: any()
  @doc "Generated function example_function"
  def example_function() do
    # TODO: Implement function body
    :ok
  end
end

# From printFunction("getUserData", ["userId", "options"], "Map.t()", false)
@spec get_user_data(any(), any()) :: Map.t()
@doc "Generated function getUserData"
def get_user_data(userId, options) do
  # TODO: Implement function body
  :ok
end

# From printList(["item1", "item2", "item3"], true) - multiline
[
  item1,
  item2,
  item3
]

# From printMap([{key: "name", value: "value"}, {key: "age", value: "30"}], true) - multiline
%{
  name: value,
  age: 30
}

# From FormatHelper.formatDoc("This is a test function", false, 1)
  @doc "This is a test function"

# From FormatHelper.formatSpec("test_func", ["String.t()", "integer()"], "boolean()", 1)
  @spec test_func(String.t(), integer()) :: boolean()

# Complex class with inheritance info
defmodule ComplexService do
  @moduledoc """
  ComplexService module generated from Haxe
  
  Enhanced documentation example
  """

  # Inherits from BaseService
  # Implements interfaces:
  # - ServiceInterface
  # - LoggingInterface

  @type t() :: %__MODULE__{
    config: any(),
    state: any()
  }

  defstruct [
    config: nil,
    state: nil
  ]

  # Static functions
  @spec create_default() :: any()
  @doc "Generated function createDefault"
  def create_default() do
    # TODO: Implement function body
    :ok
  end

  # Instance functions
  @spec process_request(any(), any()) :: any()
  @doc "Generated function processRequest"
  def process_request(request, context) do
    # TODO: Implement function body
    :ok
  end
end