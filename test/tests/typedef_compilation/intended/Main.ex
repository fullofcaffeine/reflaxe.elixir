defmodule Main do
  @moduledoc """
  Main module generated from Haxe
  """

  # Static functions
  @doc "Function main"
  @spec main() :: TAbstract(Void,[]).t()
  def main() do
    (
  user_id = 123
  username = "john_doe"
  score = 98.5
  is_active = true
  api_response_data_value_0_name = nil
  api_response_data_value_0_id = nil
  api_response_data_value_0_email = nil
  api_response_data_value_0_age = nil
  api_response_data_value_0_id = user_id
  api_response_data_value_0_name = username
  api_response_data_value_0_age = 30
  api_response_data_value_0_email = "john@example.com"
  api_response_data_value_1_name = nil
  api_response_data_value_1_id = nil
  api_response_data_value_1_age = nil
  api_response_data_value_1_id = 456
  api_response_data_value_1_name = "jane"
  api_response_data_value_1_age = 25
  company_name = nil
  company_address_zip_code = nil
  company_address_street = nil
  company_address_country = nil
  company_address_city = nil
  company_name = "Tech Corp"
  company_address_street = "123 Main St"
  company_address_city = "San Francisco"
  company_address_zip_code = "94102"
  company_address_country = "USA"
  success_result_value = nil
  success_result_ok = nil
  success_result_ok = true
  success_result_value = "Success!"
  error_result_ok = nil
  error_result_error = nil
  error_result_ok = false
  error_result_error = "Something went wrong"
  pair_second = nil
  pair_first = nil
  pair_first = 42
  pair_second = "Answer"
  callback = fn msg, code -> code == 200 end
  handler = fn  -> Log.trace("Async operation complete", %{fileName: "Main.hx", lineNumber: 145, className: "Main", methodName: "main"}) end
  api_response_status = nil
  api_response_metadata_version = nil
  api_response_metadata_timestamp = nil
  api_response_data_ok = nil
  api_response_status = 200
  api_response_data_ok = true
  api_response_metadata_timestamp = Date.now().getTime()
  api_response_metadata_version = "1.0.0"
  success_status_success = nil
  success_status_success = true
  error_status_error = nil
  error_status_error = "Failed to process"
  tree_value = nil
  tree_right_value = nil
  tree_left_value = nil
  tree_left_right_value = nil
  tree_left_left_value = nil
  tree_value = 10
  tree_left_value = 5
  tree_left_left_value = 3
  tree_left_right_value = 7
  tree_right_value = 15
  Log.trace("Typedef compilation test complete", %{fileName: "Main.hx", lineNumber: 183, className: "Main", methodName: "main"})
)
  end

end


@typedoc """

 * Typedef Compilation Test
 * Tests compilation of Haxe typedefs to Elixir @type specifications
 
"""
@type user_id :: integer()

@type username :: String.t()

@type score :: float()

@type is_active :: boolean()

@type user :: %{
  age: integer(),
  optional(:email) => String.t() | nil,
  id: user_id(),
  name: username()
}

@type company :: %{
  optional(:address) => address() | nil,
  employees: list(user()),
  name: String.t()
}

@type address :: %{
  city: String.t(),
  optional(:country) => String.t() | nil,
  street: String.t(),
  zip_code: String.t()
}

@type callback :: (String.t(), integer() -> boolean())

@type async_handler :: (() -> :ok)

@type processor :: (user() -> user())

@type validator :: (String.t() -> %{
  optional(:error) => String.t() | nil,
  valid: boolean()
})

@type result(t) :: %{
  optional(:error) => String.t() | nil,
  ok: boolean(),
  optional(:value) => t | nil
}

@type pair(a, b) :: %{
  first: a,
  second: b
}

@type container(t) :: %{
  count: integer(),
  items: list(t)
}

@type api_response :: %{
  data: result(list(user())),
  optional(:metadata) => %{
  timestamp: float(),
  version: String.t()
} | nil,
  status: integer()
}

@type status :: %{
  optional(:error) => String.t() | nil,
  optional(:pending) => boolean() | nil,
  optional(:success) => boolean() | nil
}

@type config :: %{
  flags: list(String.t()),
  settings: map(String.t(), any())
}

@type tree_node :: %{
  optional(:left) => tree_node() | nil,
  optional(:right) => tree_node() | nil,
  value: integer()
}