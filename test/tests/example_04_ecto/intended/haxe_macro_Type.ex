defmodule Type do
  @moduledoc """
  Type enum generated from Haxe
  
  
	Represents a type.
 
  
  This module provides tagged tuple constructors and pattern matching helpers.
  """

  @type t() ::
    {:t_mono, term()} |
    {:t_enum, term(), term()} |
    {:t_inst, term(), term()} |
    {:t_type, term(), term()} |
    {:t_fun, term(), term()} |
    {:t_anonymous, term()} |
    {:t_dynamic, term()} |
    {:t_lazy, term()} |
    {:t_abstract, term(), term()}

  @doc """
  Creates t_mono enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec t_mono(term()) :: {:t_mono, term()}
  def t_mono(arg0) do
    {:t_mono, arg0}
  end

  @doc """
  Creates t_enum enum value with parameters
  
  ## Parameters
    - `arg0`: term()
    - `arg1`: term()
  """
  @spec t_enum(term(), term()) :: {:t_enum, term(), term()}
  def t_enum(arg0, arg1) do
    {:t_enum, arg0, arg1}
  end

  @doc """
  Creates t_inst enum value with parameters
  
  ## Parameters
    - `arg0`: term()
    - `arg1`: term()
  """
  @spec t_inst(term(), term()) :: {:t_inst, term(), term()}
  def t_inst(arg0, arg1) do
    {:t_inst, arg0, arg1}
  end

  @doc """
  Creates t_type enum value with parameters
  
  ## Parameters
    - `arg0`: term()
    - `arg1`: term()
  """
  @spec t_type(term(), term()) :: {:t_type, term(), term()}
  def t_type(arg0, arg1) do
    {:t_type, arg0, arg1}
  end

  @doc """
  Creates t_fun enum value with parameters
  
  ## Parameters
    - `arg0`: term()
    - `arg1`: term()
  """
  @spec t_fun(term(), term()) :: {:t_fun, term(), term()}
  def t_fun(arg0, arg1) do
    {:t_fun, arg0, arg1}
  end

  @doc """
  Creates t_anonymous enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec t_anonymous(term()) :: {:t_anonymous, term()}
  def t_anonymous(arg0) do
    {:t_anonymous, arg0}
  end

  @doc """
  Creates t_dynamic enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec t_dynamic(term()) :: {:t_dynamic, term()}
  def t_dynamic(arg0) do
    {:t_dynamic, arg0}
  end

  @doc """
  Creates t_lazy enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec t_lazy(term()) :: {:t_lazy, term()}
  def t_lazy(arg0) do
    {:t_lazy, arg0}
  end

  @doc """
  Creates t_abstract enum value with parameters
  
  ## Parameters
    - `arg0`: term()
    - `arg1`: term()
  """
  @spec t_abstract(term(), term()) :: {:t_abstract, term(), term()}
  def t_abstract(arg0, arg1) do
    {:t_abstract, arg0, arg1}
  end

  # Predicate functions for pattern matching
  @doc "Returns true if value is t_mono variant"
  @spec is_t_mono(t()) :: boolean()
  def is_t_mono({:t_mono, _}), do: true
  def is_t_mono(_), do: false

  @doc "Returns true if value is t_enum variant"
  @spec is_t_enum(t()) :: boolean()
  def is_t_enum({:t_enum, _}), do: true
  def is_t_enum(_), do: false

  @doc "Returns true if value is t_inst variant"
  @spec is_t_inst(t()) :: boolean()
  def is_t_inst({:t_inst, _}), do: true
  def is_t_inst(_), do: false

  @doc "Returns true if value is t_type variant"
  @spec is_t_type(t()) :: boolean()
  def is_t_type({:t_type, _}), do: true
  def is_t_type(_), do: false

  @doc "Returns true if value is t_fun variant"
  @spec is_t_fun(t()) :: boolean()
  def is_t_fun({:t_fun, _}), do: true
  def is_t_fun(_), do: false

  @doc "Returns true if value is t_anonymous variant"
  @spec is_t_anonymous(t()) :: boolean()
  def is_t_anonymous({:t_anonymous, _}), do: true
  def is_t_anonymous(_), do: false

  @doc "Returns true if value is t_dynamic variant"
  @spec is_t_dynamic(t()) :: boolean()
  def is_t_dynamic({:t_dynamic, _}), do: true
  def is_t_dynamic(_), do: false

  @doc "Returns true if value is t_lazy variant"
  @spec is_t_lazy(t()) :: boolean()
  def is_t_lazy({:t_lazy, _}), do: true
  def is_t_lazy(_), do: false

  @doc "Returns true if value is t_abstract variant"
  @spec is_t_abstract(t()) :: boolean()
  def is_t_abstract({:t_abstract, _}), do: true
  def is_t_abstract(_), do: false

  @doc "Extracts value from t_mono variant, returns {:ok, value} or :error"
  @spec get_t_mono_value(t()) :: {:ok, term()} | :error
  def get_t_mono_value({:t_mono, value}), do: {:ok, value}
  def get_t_mono_value(_), do: :error

  @doc "Extracts value from t_enum variant, returns {:ok, value} or :error"
  @spec get_t_enum_value(t()) :: {:ok, {term(), term()}} | :error
  def get_t_enum_value({:t_enum, arg0, arg1}), do: {:ok, {arg0, arg1}}
  def get_t_enum_value(_), do: :error

  @doc "Extracts value from t_inst variant, returns {:ok, value} or :error"
  @spec get_t_inst_value(t()) :: {:ok, {term(), term()}} | :error
  def get_t_inst_value({:t_inst, arg0, arg1}), do: {:ok, {arg0, arg1}}
  def get_t_inst_value(_), do: :error

  @doc "Extracts value from t_type variant, returns {:ok, value} or :error"
  @spec get_t_type_value(t()) :: {:ok, {term(), term()}} | :error
  def get_t_type_value({:t_type, arg0, arg1}), do: {:ok, {arg0, arg1}}
  def get_t_type_value(_), do: :error

  @doc "Extracts value from t_fun variant, returns {:ok, value} or :error"
  @spec get_t_fun_value(t()) :: {:ok, {term(), term()}} | :error
  def get_t_fun_value({:t_fun, arg0, arg1}), do: {:ok, {arg0, arg1}}
  def get_t_fun_value(_), do: :error

  @doc "Extracts value from t_anonymous variant, returns {:ok, value} or :error"
  @spec get_t_anonymous_value(t()) :: {:ok, term()} | :error
  def get_t_anonymous_value({:t_anonymous, value}), do: {:ok, value}
  def get_t_anonymous_value(_), do: :error

  @doc "Extracts value from t_dynamic variant, returns {:ok, value} or :error"
  @spec get_t_dynamic_value(t()) :: {:ok, term()} | :error
  def get_t_dynamic_value({:t_dynamic, value}), do: {:ok, value}
  def get_t_dynamic_value(_), do: :error

  @doc "Extracts value from t_lazy variant, returns {:ok, value} or :error"
  @spec get_t_lazy_value(t()) :: {:ok, term()} | :error
  def get_t_lazy_value({:t_lazy, value}), do: {:ok, value}
  def get_t_lazy_value(_), do: :error

  @doc "Extracts value from t_abstract variant, returns {:ok, value} or :error"
  @spec get_t_abstract_value(t()) :: {:ok, {term(), term()}} | :error
  def get_t_abstract_value({:t_abstract, arg0, arg1}), do: {:ok, {arg0, arg1}}
  def get_t_abstract_value(_), do: :error

end


defmodule AnonStatus do
  @moduledoc """
  AnonStatus enum generated from Haxe
  
  
	Represents the kind of the anonymous structure type.

  
  This module provides tagged tuple constructors and pattern matching helpers.
  """

  @type t() ::
    :a_closed |
    :a_opened |
    :a_const |
    {:a_extend, term()} |
    {:a_class_statics, term()} |
    {:a_enum_statics, term()} |
    {:a_abstract_statics, term()}

  @doc "Creates a_closed enum value"
  @spec a_closed() :: :a_closed
  def a_closed(), do: :a_closed

  @doc "Creates a_opened enum value"
  @spec a_opened() :: :a_opened
  def a_opened(), do: :a_opened

  @doc "Creates a_const enum value"
  @spec a_const() :: :a_const
  def a_const(), do: :a_const

  @doc """
  Creates a_extend enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec a_extend(term()) :: {:a_extend, term()}
  def a_extend(arg0) do
    {:a_extend, arg0}
  end

  @doc """
  Creates a_class_statics enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec a_class_statics(term()) :: {:a_class_statics, term()}
  def a_class_statics(arg0) do
    {:a_class_statics, arg0}
  end

  @doc """
  Creates a_enum_statics enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec a_enum_statics(term()) :: {:a_enum_statics, term()}
  def a_enum_statics(arg0) do
    {:a_enum_statics, arg0}
  end

  @doc """
  Creates a_abstract_statics enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec a_abstract_statics(term()) :: {:a_abstract_statics, term()}
  def a_abstract_statics(arg0) do
    {:a_abstract_statics, arg0}
  end

  # Predicate functions for pattern matching
  @doc "Returns true if value is a_closed variant"
  @spec is_a_closed(t()) :: boolean()
  def is_a_closed(:a_closed), do: true
  def is_a_closed(_), do: false

  @doc "Returns true if value is a_opened variant"
  @spec is_a_opened(t()) :: boolean()
  def is_a_opened(:a_opened), do: true
  def is_a_opened(_), do: false

  @doc "Returns true if value is a_const variant"
  @spec is_a_const(t()) :: boolean()
  def is_a_const(:a_const), do: true
  def is_a_const(_), do: false

  @doc "Returns true if value is a_extend variant"
  @spec is_a_extend(t()) :: boolean()
  def is_a_extend({:a_extend, _}), do: true
  def is_a_extend(_), do: false

  @doc "Returns true if value is a_class_statics variant"
  @spec is_a_class_statics(t()) :: boolean()
  def is_a_class_statics({:a_class_statics, _}), do: true
  def is_a_class_statics(_), do: false

  @doc "Returns true if value is a_enum_statics variant"
  @spec is_a_enum_statics(t()) :: boolean()
  def is_a_enum_statics({:a_enum_statics, _}), do: true
  def is_a_enum_statics(_), do: false

  @doc "Returns true if value is a_abstract_statics variant"
  @spec is_a_abstract_statics(t()) :: boolean()
  def is_a_abstract_statics({:a_abstract_statics, _}), do: true
  def is_a_abstract_statics(_), do: false

  @doc "Extracts value from a_extend variant, returns {:ok, value} or :error"
  @spec get_a_extend_value(t()) :: {:ok, term()} | :error
  def get_a_extend_value({:a_extend, value}), do: {:ok, value}
  def get_a_extend_value(_), do: :error

  @doc "Extracts value from a_class_statics variant, returns {:ok, value} or :error"
  @spec get_a_class_statics_value(t()) :: {:ok, term()} | :error
  def get_a_class_statics_value({:a_class_statics, value}), do: {:ok, value}
  def get_a_class_statics_value(_), do: :error

  @doc "Extracts value from a_enum_statics variant, returns {:ok, value} or :error"
  @spec get_a_enum_statics_value(t()) :: {:ok, term()} | :error
  def get_a_enum_statics_value({:a_enum_statics, value}), do: {:ok, value}
  def get_a_enum_statics_value(_), do: :error

  @doc "Extracts value from a_abstract_statics variant, returns {:ok, value} or :error"
  @spec get_a_abstract_statics_value(t()) :: {:ok, term()} | :error
  def get_a_abstract_statics_value({:a_abstract_statics, value}), do: {:ok, value}
  def get_a_abstract_statics_value(_), do: :error

end


defmodule ClassKind do
  @moduledoc """
  ClassKind enum generated from Haxe
  
  
	Represents the kind of a class.
 
  
  This module provides tagged tuple constructors and pattern matching helpers.
  """

  @type t() ::
    :k_normal |
    {:k_type_parameter, term()} |
    {:k_module_fields, term()} |
    {:k_expr, term()} |
    :k_generic |
    {:k_generic_instance, term(), term()} |
    :k_macro_type |
    {:k_abstract_impl, term()} |
    :k_generic_build

  @doc "Creates k_normal enum value"
  @spec k_normal() :: :k_normal
  def k_normal(), do: :k_normal

  @doc """
  Creates k_type_parameter enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec k_type_parameter(term()) :: {:k_type_parameter, term()}
  def k_type_parameter(arg0) do
    {:k_type_parameter, arg0}
  end

  @doc """
  Creates k_module_fields enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec k_module_fields(term()) :: {:k_module_fields, term()}
  def k_module_fields(arg0) do
    {:k_module_fields, arg0}
  end

  @doc """
  Creates k_expr enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec k_expr(term()) :: {:k_expr, term()}
  def k_expr(arg0) do
    {:k_expr, arg0}
  end

  @doc "Creates k_generic enum value"
  @spec k_generic() :: :k_generic
  def k_generic(), do: :k_generic

  @doc """
  Creates k_generic_instance enum value with parameters
  
  ## Parameters
    - `arg0`: term()
    - `arg1`: term()
  """
  @spec k_generic_instance(term(), term()) :: {:k_generic_instance, term(), term()}
  def k_generic_instance(arg0, arg1) do
    {:k_generic_instance, arg0, arg1}
  end

  @doc "Creates k_macro_type enum value"
  @spec k_macro_type() :: :k_macro_type
  def k_macro_type(), do: :k_macro_type

  @doc """
  Creates k_abstract_impl enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec k_abstract_impl(term()) :: {:k_abstract_impl, term()}
  def k_abstract_impl(arg0) do
    {:k_abstract_impl, arg0}
  end

  @doc "Creates k_generic_build enum value"
  @spec k_generic_build() :: :k_generic_build
  def k_generic_build(), do: :k_generic_build

  # Predicate functions for pattern matching
  @doc "Returns true if value is k_normal variant"
  @spec is_k_normal(t()) :: boolean()
  def is_k_normal(:k_normal), do: true
  def is_k_normal(_), do: false

  @doc "Returns true if value is k_type_parameter variant"
  @spec is_k_type_parameter(t()) :: boolean()
  def is_k_type_parameter({:k_type_parameter, _}), do: true
  def is_k_type_parameter(_), do: false

  @doc "Returns true if value is k_module_fields variant"
  @spec is_k_module_fields(t()) :: boolean()
  def is_k_module_fields({:k_module_fields, _}), do: true
  def is_k_module_fields(_), do: false

  @doc "Returns true if value is k_expr variant"
  @spec is_k_expr(t()) :: boolean()
  def is_k_expr({:k_expr, _}), do: true
  def is_k_expr(_), do: false

  @doc "Returns true if value is k_generic variant"
  @spec is_k_generic(t()) :: boolean()
  def is_k_generic(:k_generic), do: true
  def is_k_generic(_), do: false

  @doc "Returns true if value is k_generic_instance variant"
  @spec is_k_generic_instance(t()) :: boolean()
  def is_k_generic_instance({:k_generic_instance, _}), do: true
  def is_k_generic_instance(_), do: false

  @doc "Returns true if value is k_macro_type variant"
  @spec is_k_macro_type(t()) :: boolean()
  def is_k_macro_type(:k_macro_type), do: true
  def is_k_macro_type(_), do: false

  @doc "Returns true if value is k_abstract_impl variant"
  @spec is_k_abstract_impl(t()) :: boolean()
  def is_k_abstract_impl({:k_abstract_impl, _}), do: true
  def is_k_abstract_impl(_), do: false

  @doc "Returns true if value is k_generic_build variant"
  @spec is_k_generic_build(t()) :: boolean()
  def is_k_generic_build(:k_generic_build), do: true
  def is_k_generic_build(_), do: false

  @doc "Extracts value from k_type_parameter variant, returns {:ok, value} or :error"
  @spec get_k_type_parameter_value(t()) :: {:ok, term()} | :error
  def get_k_type_parameter_value({:k_type_parameter, value}), do: {:ok, value}
  def get_k_type_parameter_value(_), do: :error

  @doc "Extracts value from k_module_fields variant, returns {:ok, value} or :error"
  @spec get_k_module_fields_value(t()) :: {:ok, term()} | :error
  def get_k_module_fields_value({:k_module_fields, value}), do: {:ok, value}
  def get_k_module_fields_value(_), do: :error

  @doc "Extracts value from k_expr variant, returns {:ok, value} or :error"
  @spec get_k_expr_value(t()) :: {:ok, term()} | :error
  def get_k_expr_value({:k_expr, value}), do: {:ok, value}
  def get_k_expr_value(_), do: :error

  @doc "Extracts value from k_generic_instance variant, returns {:ok, value} or :error"
  @spec get_k_generic_instance_value(t()) :: {:ok, {term(), term()}} | :error
  def get_k_generic_instance_value({:k_generic_instance, arg0, arg1}), do: {:ok, {arg0, arg1}}
  def get_k_generic_instance_value(_), do: :error

  @doc "Extracts value from k_abstract_impl variant, returns {:ok, value} or :error"
  @spec get_k_abstract_impl_value(t()) :: {:ok, term()} | :error
  def get_k_abstract_impl_value({:k_abstract_impl, value}), do: {:ok, value}
  def get_k_abstract_impl_value(_), do: :error

end


defmodule FieldKind do
  @moduledoc """
  FieldKind enum generated from Haxe
  
  
	Represents a field kind.
 
  
  This module provides tagged tuple constructors and pattern matching helpers.
  """

  @type t() ::
    {:f_var, term(), term()} |
    {:f_method, term()}

  @doc """
  Creates f_var enum value with parameters
  
  ## Parameters
    - `arg0`: term()
    - `arg1`: term()
  """
  @spec f_var(term(), term()) :: {:f_var, term(), term()}
  def f_var(arg0, arg1) do
    {:f_var, arg0, arg1}
  end

  @doc """
  Creates f_method enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec f_method(term()) :: {:f_method, term()}
  def f_method(arg0) do
    {:f_method, arg0}
  end

  # Predicate functions for pattern matching
  @doc "Returns true if value is f_var variant"
  @spec is_f_var(t()) :: boolean()
  def is_f_var({:f_var, _}), do: true
  def is_f_var(_), do: false

  @doc "Returns true if value is f_method variant"
  @spec is_f_method(t()) :: boolean()
  def is_f_method({:f_method, _}), do: true
  def is_f_method(_), do: false

  @doc "Extracts value from f_var variant, returns {:ok, value} or :error"
  @spec get_f_var_value(t()) :: {:ok, {term(), term()}} | :error
  def get_f_var_value({:f_var, arg0, arg1}), do: {:ok, {arg0, arg1}}
  def get_f_var_value(_), do: :error

  @doc "Extracts value from f_method variant, returns {:ok, value} or :error"
  @spec get_f_method_value(t()) :: {:ok, term()} | :error
  def get_f_method_value({:f_method, value}), do: {:ok, value}
  def get_f_method_value(_), do: :error

end


defmodule VarAccess do
  @moduledoc """
  VarAccess enum generated from Haxe
  
  
	Represents the variable accessor.
 
  
  This module provides tagged tuple constructors and pattern matching helpers.
  """

  @type t() ::
    :acc_normal |
    :acc_no |
    :acc_never |
    :acc_resolve |
    :acc_call |
    :acc_inline |
    {:acc_require, term(), term()} |
    :acc_ctor

  @doc "Creates acc_normal enum value"
  @spec acc_normal() :: :acc_normal
  def acc_normal(), do: :acc_normal

  @doc "Creates acc_no enum value"
  @spec acc_no() :: :acc_no
  def acc_no(), do: :acc_no

  @doc "Creates acc_never enum value"
  @spec acc_never() :: :acc_never
  def acc_never(), do: :acc_never

  @doc "Creates acc_resolve enum value"
  @spec acc_resolve() :: :acc_resolve
  def acc_resolve(), do: :acc_resolve

  @doc "Creates acc_call enum value"
  @spec acc_call() :: :acc_call
  def acc_call(), do: :acc_call

  @doc "Creates acc_inline enum value"
  @spec acc_inline() :: :acc_inline
  def acc_inline(), do: :acc_inline

  @doc """
  Creates acc_require enum value with parameters
  
  ## Parameters
    - `arg0`: term()
    - `arg1`: term()
  """
  @spec acc_require(term(), term()) :: {:acc_require, term(), term()}
  def acc_require(arg0, arg1) do
    {:acc_require, arg0, arg1}
  end

  @doc "Creates acc_ctor enum value"
  @spec acc_ctor() :: :acc_ctor
  def acc_ctor(), do: :acc_ctor

  # Predicate functions for pattern matching
  @doc "Returns true if value is acc_normal variant"
  @spec is_acc_normal(t()) :: boolean()
  def is_acc_normal(:acc_normal), do: true
  def is_acc_normal(_), do: false

  @doc "Returns true if value is acc_no variant"
  @spec is_acc_no(t()) :: boolean()
  def is_acc_no(:acc_no), do: true
  def is_acc_no(_), do: false

  @doc "Returns true if value is acc_never variant"
  @spec is_acc_never(t()) :: boolean()
  def is_acc_never(:acc_never), do: true
  def is_acc_never(_), do: false

  @doc "Returns true if value is acc_resolve variant"
  @spec is_acc_resolve(t()) :: boolean()
  def is_acc_resolve(:acc_resolve), do: true
  def is_acc_resolve(_), do: false

  @doc "Returns true if value is acc_call variant"
  @spec is_acc_call(t()) :: boolean()
  def is_acc_call(:acc_call), do: true
  def is_acc_call(_), do: false

  @doc "Returns true if value is acc_inline variant"
  @spec is_acc_inline(t()) :: boolean()
  def is_acc_inline(:acc_inline), do: true
  def is_acc_inline(_), do: false

  @doc "Returns true if value is acc_require variant"
  @spec is_acc_require(t()) :: boolean()
  def is_acc_require({:acc_require, _}), do: true
  def is_acc_require(_), do: false

  @doc "Returns true if value is acc_ctor variant"
  @spec is_acc_ctor(t()) :: boolean()
  def is_acc_ctor(:acc_ctor), do: true
  def is_acc_ctor(_), do: false

  @doc "Extracts value from acc_require variant, returns {:ok, value} or :error"
  @spec get_acc_require_value(t()) :: {:ok, {term(), term()}} | :error
  def get_acc_require_value({:acc_require, arg0, arg1}), do: {:ok, {arg0, arg1}}
  def get_acc_require_value(_), do: :error

end


defmodule MethodKind do
  @moduledoc """
  MethodKind enum generated from Haxe
  
  
	Represents the method kind.
 
  
  This module provides tagged tuple constructors and pattern matching helpers.
  """

  @type t() ::
    :meth_normal |
    :meth_inline |
    :meth_dynamic |
    :meth_macro

  @doc "Creates meth_normal enum value"
  @spec meth_normal() :: :meth_normal
  def meth_normal(), do: :meth_normal

  @doc "Creates meth_inline enum value"
  @spec meth_inline() :: :meth_inline
  def meth_inline(), do: :meth_inline

  @doc "Creates meth_dynamic enum value"
  @spec meth_dynamic() :: :meth_dynamic
  def meth_dynamic(), do: :meth_dynamic

  @doc "Creates meth_macro enum value"
  @spec meth_macro() :: :meth_macro
  def meth_macro(), do: :meth_macro

  # Predicate functions for pattern matching
  @doc "Returns true if value is meth_normal variant"
  @spec is_meth_normal(t()) :: boolean()
  def is_meth_normal(:meth_normal), do: true
  def is_meth_normal(_), do: false

  @doc "Returns true if value is meth_inline variant"
  @spec is_meth_inline(t()) :: boolean()
  def is_meth_inline(:meth_inline), do: true
  def is_meth_inline(_), do: false

  @doc "Returns true if value is meth_dynamic variant"
  @spec is_meth_dynamic(t()) :: boolean()
  def is_meth_dynamic(:meth_dynamic), do: true
  def is_meth_dynamic(_), do: false

  @doc "Returns true if value is meth_macro variant"
  @spec is_meth_macro(t()) :: boolean()
  def is_meth_macro(:meth_macro), do: true
  def is_meth_macro(_), do: false

end


defmodule TConstant do
  @moduledoc """
  TConstant enum generated from Haxe
  
  
	Represents typed constant.
 
  
  This module provides tagged tuple constructors and pattern matching helpers.
  """

  @type t() ::
    {:t_int, term()} |
    {:t_float, term()} |
    {:t_string, term()} |
    {:t_bool, term()} |
    :t_null |
    :t_this |
    :t_super

  @doc """
  Creates t_int enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec t_int(term()) :: {:t_int, term()}
  def t_int(arg0) do
    {:t_int, arg0}
  end

  @doc """
  Creates t_float enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec t_float(term()) :: {:t_float, term()}
  def t_float(arg0) do
    {:t_float, arg0}
  end

  @doc """
  Creates t_string enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec t_string(term()) :: {:t_string, term()}
  def t_string(arg0) do
    {:t_string, arg0}
  end

  @doc """
  Creates t_bool enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec t_bool(term()) :: {:t_bool, term()}
  def t_bool(arg0) do
    {:t_bool, arg0}
  end

  @doc "Creates t_null enum value"
  @spec t_null() :: :t_null
  def t_null(), do: :t_null

  @doc "Creates t_this enum value"
  @spec t_this() :: :t_this
  def t_this(), do: :t_this

  @doc "Creates t_super enum value"
  @spec t_super() :: :t_super
  def t_super(), do: :t_super

  # Predicate functions for pattern matching
  @doc "Returns true if value is t_int variant"
  @spec is_t_int(t()) :: boolean()
  def is_t_int({:t_int, _}), do: true
  def is_t_int(_), do: false

  @doc "Returns true if value is t_float variant"
  @spec is_t_float(t()) :: boolean()
  def is_t_float({:t_float, _}), do: true
  def is_t_float(_), do: false

  @doc "Returns true if value is t_string variant"
  @spec is_t_string(t()) :: boolean()
  def is_t_string({:t_string, _}), do: true
  def is_t_string(_), do: false

  @doc "Returns true if value is t_bool variant"
  @spec is_t_bool(t()) :: boolean()
  def is_t_bool({:t_bool, _}), do: true
  def is_t_bool(_), do: false

  @doc "Returns true if value is t_null variant"
  @spec is_t_null(t()) :: boolean()
  def is_t_null(:t_null), do: true
  def is_t_null(_), do: false

  @doc "Returns true if value is t_this variant"
  @spec is_t_this(t()) :: boolean()
  def is_t_this(:t_this), do: true
  def is_t_this(_), do: false

  @doc "Returns true if value is t_super variant"
  @spec is_t_super(t()) :: boolean()
  def is_t_super(:t_super), do: true
  def is_t_super(_), do: false

  @doc "Extracts value from t_int variant, returns {:ok, value} or :error"
  @spec get_t_int_value(t()) :: {:ok, term()} | :error
  def get_t_int_value({:t_int, value}), do: {:ok, value}
  def get_t_int_value(_), do: :error

  @doc "Extracts value from t_float variant, returns {:ok, value} or :error"
  @spec get_t_float_value(t()) :: {:ok, term()} | :error
  def get_t_float_value({:t_float, value}), do: {:ok, value}
  def get_t_float_value(_), do: :error

  @doc "Extracts value from t_string variant, returns {:ok, value} or :error"
  @spec get_t_string_value(t()) :: {:ok, term()} | :error
  def get_t_string_value({:t_string, value}), do: {:ok, value}
  def get_t_string_value(_), do: :error

  @doc "Extracts value from t_bool variant, returns {:ok, value} or :error"
  @spec get_t_bool_value(t()) :: {:ok, term()} | :error
  def get_t_bool_value({:t_bool, value}), do: {:ok, value}
  def get_t_bool_value(_), do: :error

end


defmodule ModuleType do
  @moduledoc """
  ModuleType enum generated from Haxe
  
  
	Represents a module type. These are the types that can be declared in a Haxe
	module and which are passed to the generators (except `TTypeDecl`).
 
  
  This module provides tagged tuple constructors and pattern matching helpers.
  """

  @type t() ::
    {:t_class_decl, term()} |
    {:t_enum_decl, term()} |
    {:t_type_decl, term()} |
    {:t_abstract, term()}

  @doc """
  Creates t_class_decl enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec t_class_decl(term()) :: {:t_class_decl, term()}
  def t_class_decl(arg0) do
    {:t_class_decl, arg0}
  end

  @doc """
  Creates t_enum_decl enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec t_enum_decl(term()) :: {:t_enum_decl, term()}
  def t_enum_decl(arg0) do
    {:t_enum_decl, arg0}
  end

  @doc """
  Creates t_type_decl enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec t_type_decl(term()) :: {:t_type_decl, term()}
  def t_type_decl(arg0) do
    {:t_type_decl, arg0}
  end

  @doc """
  Creates t_abstract enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec t_abstract(term()) :: {:t_abstract, term()}
  def t_abstract(arg0) do
    {:t_abstract, arg0}
  end

  # Predicate functions for pattern matching
  @doc "Returns true if value is t_class_decl variant"
  @spec is_t_class_decl(t()) :: boolean()
  def is_t_class_decl({:t_class_decl, _}), do: true
  def is_t_class_decl(_), do: false

  @doc "Returns true if value is t_enum_decl variant"
  @spec is_t_enum_decl(t()) :: boolean()
  def is_t_enum_decl({:t_enum_decl, _}), do: true
  def is_t_enum_decl(_), do: false

  @doc "Returns true if value is t_type_decl variant"
  @spec is_t_type_decl(t()) :: boolean()
  def is_t_type_decl({:t_type_decl, _}), do: true
  def is_t_type_decl(_), do: false

  @doc "Returns true if value is t_abstract variant"
  @spec is_t_abstract(t()) :: boolean()
  def is_t_abstract({:t_abstract, _}), do: true
  def is_t_abstract(_), do: false

  @doc "Extracts value from t_class_decl variant, returns {:ok, value} or :error"
  @spec get_t_class_decl_value(t()) :: {:ok, term()} | :error
  def get_t_class_decl_value({:t_class_decl, value}), do: {:ok, value}
  def get_t_class_decl_value(_), do: :error

  @doc "Extracts value from t_enum_decl variant, returns {:ok, value} or :error"
  @spec get_t_enum_decl_value(t()) :: {:ok, term()} | :error
  def get_t_enum_decl_value({:t_enum_decl, value}), do: {:ok, value}
  def get_t_enum_decl_value(_), do: :error

  @doc "Extracts value from t_type_decl variant, returns {:ok, value} or :error"
  @spec get_t_type_decl_value(t()) :: {:ok, term()} | :error
  def get_t_type_decl_value({:t_type_decl, value}), do: {:ok, value}
  def get_t_type_decl_value(_), do: :error

  @doc "Extracts value from t_abstract variant, returns {:ok, value} or :error"
  @spec get_t_abstract_value(t()) :: {:ok, term()} | :error
  def get_t_abstract_value({:t_abstract, value}), do: {:ok, value}
  def get_t_abstract_value(_), do: :error

end


defmodule FieldAccess do
  @moduledoc """
  FieldAccess enum generated from Haxe
  
  
	Represents the kind of field access in the typed AST.
 
  
  This module provides tagged tuple constructors and pattern matching helpers.
  """

  @type t() ::
    {:f_instance, term(), term(), term()} |
    {:f_static, term(), term()} |
    {:f_anon, term()} |
    {:f_dynamic, term()} |
    {:f_closure, term(), term()} |
    {:f_enum, term(), term()}

  @doc """
  Creates f_instance enum value with parameters
  
  ## Parameters
    - `arg0`: term()
    - `arg1`: term()
    - `arg2`: term()
  """
  @spec f_instance(term(), term(), term()) :: {:f_instance, term(), term(), term()}
  def f_instance(arg0, arg1, arg2) do
    {:f_instance, arg0, arg1, arg2}
  end

  @doc """
  Creates f_static enum value with parameters
  
  ## Parameters
    - `arg0`: term()
    - `arg1`: term()
  """
  @spec f_static(term(), term()) :: {:f_static, term(), term()}
  def f_static(arg0, arg1) do
    {:f_static, arg0, arg1}
  end

  @doc """
  Creates f_anon enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec f_anon(term()) :: {:f_anon, term()}
  def f_anon(arg0) do
    {:f_anon, arg0}
  end

  @doc """
  Creates f_dynamic enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec f_dynamic(term()) :: {:f_dynamic, term()}
  def f_dynamic(arg0) do
    {:f_dynamic, arg0}
  end

  @doc """
  Creates f_closure enum value with parameters
  
  ## Parameters
    - `arg0`: term()
    - `arg1`: term()
  """
  @spec f_closure(term(), term()) :: {:f_closure, term(), term()}
  def f_closure(arg0, arg1) do
    {:f_closure, arg0, arg1}
  end

  @doc """
  Creates f_enum enum value with parameters
  
  ## Parameters
    - `arg0`: term()
    - `arg1`: term()
  """
  @spec f_enum(term(), term()) :: {:f_enum, term(), term()}
  def f_enum(arg0, arg1) do
    {:f_enum, arg0, arg1}
  end

  # Predicate functions for pattern matching
  @doc "Returns true if value is f_instance variant"
  @spec is_f_instance(t()) :: boolean()
  def is_f_instance({:f_instance, _}), do: true
  def is_f_instance(_), do: false

  @doc "Returns true if value is f_static variant"
  @spec is_f_static(t()) :: boolean()
  def is_f_static({:f_static, _}), do: true
  def is_f_static(_), do: false

  @doc "Returns true if value is f_anon variant"
  @spec is_f_anon(t()) :: boolean()
  def is_f_anon({:f_anon, _}), do: true
  def is_f_anon(_), do: false

  @doc "Returns true if value is f_dynamic variant"
  @spec is_f_dynamic(t()) :: boolean()
  def is_f_dynamic({:f_dynamic, _}), do: true
  def is_f_dynamic(_), do: false

  @doc "Returns true if value is f_closure variant"
  @spec is_f_closure(t()) :: boolean()
  def is_f_closure({:f_closure, _}), do: true
  def is_f_closure(_), do: false

  @doc "Returns true if value is f_enum variant"
  @spec is_f_enum(t()) :: boolean()
  def is_f_enum({:f_enum, _}), do: true
  def is_f_enum(_), do: false

  @doc "Extracts value from f_instance variant, returns {:ok, value} or :error"
  @spec get_f_instance_value(t()) :: {:ok, {term(), term(), term()}} | :error
  def get_f_instance_value({:f_instance, arg0, arg1, arg2}), do: {:ok, {arg0, arg1, arg2}}
  def get_f_instance_value(_), do: :error

  @doc "Extracts value from f_static variant, returns {:ok, value} or :error"
  @spec get_f_static_value(t()) :: {:ok, {term(), term()}} | :error
  def get_f_static_value({:f_static, arg0, arg1}), do: {:ok, {arg0, arg1}}
  def get_f_static_value(_), do: :error

  @doc "Extracts value from f_anon variant, returns {:ok, value} or :error"
  @spec get_f_anon_value(t()) :: {:ok, term()} | :error
  def get_f_anon_value({:f_anon, value}), do: {:ok, value}
  def get_f_anon_value(_), do: :error

  @doc "Extracts value from f_dynamic variant, returns {:ok, value} or :error"
  @spec get_f_dynamic_value(t()) :: {:ok, term()} | :error
  def get_f_dynamic_value({:f_dynamic, value}), do: {:ok, value}
  def get_f_dynamic_value(_), do: :error

  @doc "Extracts value from f_closure variant, returns {:ok, value} or :error"
  @spec get_f_closure_value(t()) :: {:ok, {term(), term()}} | :error
  def get_f_closure_value({:f_closure, arg0, arg1}), do: {:ok, {arg0, arg1}}
  def get_f_closure_value(_), do: :error

  @doc "Extracts value from f_enum variant, returns {:ok, value} or :error"
  @spec get_f_enum_value(t()) :: {:ok, {term(), term()}} | :error
  def get_f_enum_value({:f_enum, arg0, arg1}), do: {:ok, {arg0, arg1}}
  def get_f_enum_value(_), do: :error

end


defmodule TypedExprDef do
  @moduledoc """
  TypedExprDef enum generated from Haxe
  
  
	Represents kind of a node in the typed AST.
 
  
  This module provides tagged tuple constructors and pattern matching helpers.
  """

  @type t() ::
    {:t_const, term()} |
    {:t_local, term()} |
    {:t_array, term(), term()} |
    {:t_binop, term(), term(), term()} |
    {:t_field, term(), term()} |
    {:t_type_expr, term()} |
    {:t_parenthesis, term()} |
    {:t_object_decl, term()} |
    {:t_array_decl, term()} |
    {:t_call, term(), term()} |
    {:t_new, term(), term(), term()} |
    {:t_unop, term(), term(), term()} |
    {:t_function, term()} |
    {:t_var, term(), term()} |
    {:t_block, term()} |
    {:t_for, term(), term(), term()} |
    {:t_if, term(), term(), term()} |
    {:t_while, term(), term(), term()} |
    {:t_switch, term(), term(), term()} |
    {:t_try, term(), term()} |
    {:t_return, term()} |
    :t_break |
    :t_continue |
    {:t_throw, term()} |
    {:t_cast, term(), term()} |
    {:t_meta, term(), term()} |
    {:t_enum_parameter, term(), term(), term()} |
    {:t_enum_index, term()} |
    {:t_ident, term()}

  @doc """
  Creates t_const enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec t_const(term()) :: {:t_const, term()}
  def t_const(arg0) do
    {:t_const, arg0}
  end

  @doc """
  Creates t_local enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec t_local(term()) :: {:t_local, term()}
  def t_local(arg0) do
    {:t_local, arg0}
  end

  @doc """
  Creates t_array enum value with parameters
  
  ## Parameters
    - `arg0`: term()
    - `arg1`: term()
  """
  @spec t_array(term(), term()) :: {:t_array, term(), term()}
  def t_array(arg0, arg1) do
    {:t_array, arg0, arg1}
  end

  @doc """
  Creates t_binop enum value with parameters
  
  ## Parameters
    - `arg0`: term()
    - `arg1`: term()
    - `arg2`: term()
  """
  @spec t_binop(term(), term(), term()) :: {:t_binop, term(), term(), term()}
  def t_binop(arg0, arg1, arg2) do
    {:t_binop, arg0, arg1, arg2}
  end

  @doc """
  Creates t_field enum value with parameters
  
  ## Parameters
    - `arg0`: term()
    - `arg1`: term()
  """
  @spec t_field(term(), term()) :: {:t_field, term(), term()}
  def t_field(arg0, arg1) do
    {:t_field, arg0, arg1}
  end

  @doc """
  Creates t_type_expr enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec t_type_expr(term()) :: {:t_type_expr, term()}
  def t_type_expr(arg0) do
    {:t_type_expr, arg0}
  end

  @doc """
  Creates t_parenthesis enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec t_parenthesis(term()) :: {:t_parenthesis, term()}
  def t_parenthesis(arg0) do
    {:t_parenthesis, arg0}
  end

  @doc """
  Creates t_object_decl enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec t_object_decl(term()) :: {:t_object_decl, term()}
  def t_object_decl(arg0) do
    {:t_object_decl, arg0}
  end

  @doc """
  Creates t_array_decl enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec t_array_decl(term()) :: {:t_array_decl, term()}
  def t_array_decl(arg0) do
    {:t_array_decl, arg0}
  end

  @doc """
  Creates t_call enum value with parameters
  
  ## Parameters
    - `arg0`: term()
    - `arg1`: term()
  """
  @spec t_call(term(), term()) :: {:t_call, term(), term()}
  def t_call(arg0, arg1) do
    {:t_call, arg0, arg1}
  end

  @doc """
  Creates t_new enum value with parameters
  
  ## Parameters
    - `arg0`: term()
    - `arg1`: term()
    - `arg2`: term()
  """
  @spec t_new(term(), term(), term()) :: {:t_new, term(), term(), term()}
  def t_new(arg0, arg1, arg2) do
    {:t_new, arg0, arg1, arg2}
  end

  @doc """
  Creates t_unop enum value with parameters
  
  ## Parameters
    - `arg0`: term()
    - `arg1`: term()
    - `arg2`: term()
  """
  @spec t_unop(term(), term(), term()) :: {:t_unop, term(), term(), term()}
  def t_unop(arg0, arg1, arg2) do
    {:t_unop, arg0, arg1, arg2}
  end

  @doc """
  Creates t_function enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec t_function(term()) :: {:t_function, term()}
  def t_function(arg0) do
    {:t_function, arg0}
  end

  @doc """
  Creates t_var enum value with parameters
  
  ## Parameters
    - `arg0`: term()
    - `arg1`: term()
  """
  @spec t_var(term(), term()) :: {:t_var, term(), term()}
  def t_var(arg0, arg1) do
    {:t_var, arg0, arg1}
  end

  @doc """
  Creates t_block enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec t_block(term()) :: {:t_block, term()}
  def t_block(arg0) do
    {:t_block, arg0}
  end

  @doc """
  Creates t_for enum value with parameters
  
  ## Parameters
    - `arg0`: term()
    - `arg1`: term()
    - `arg2`: term()
  """
  @spec t_for(term(), term(), term()) :: {:t_for, term(), term(), term()}
  def t_for(arg0, arg1, arg2) do
    {:t_for, arg0, arg1, arg2}
  end

  @doc """
  Creates t_if enum value with parameters
  
  ## Parameters
    - `arg0`: term()
    - `arg1`: term()
    - `arg2`: term()
  """
  @spec t_if(term(), term(), term()) :: {:t_if, term(), term(), term()}
  def t_if(arg0, arg1, arg2) do
    {:t_if, arg0, arg1, arg2}
  end

  @doc """
  Creates t_while enum value with parameters
  
  ## Parameters
    - `arg0`: term()
    - `arg1`: term()
    - `arg2`: term()
  """
  @spec t_while(term(), term(), term()) :: {:t_while, term(), term(), term()}
  def t_while(arg0, arg1, arg2) do
    {:t_while, arg0, arg1, arg2}
  end

  @doc """
  Creates t_switch enum value with parameters
  
  ## Parameters
    - `arg0`: term()
    - `arg1`: term()
    - `arg2`: term()
  """
  @spec t_switch(term(), term(), term()) :: {:t_switch, term(), term(), term()}
  def t_switch(arg0, arg1, arg2) do
    {:t_switch, arg0, arg1, arg2}
  end

  @doc """
  Creates t_try enum value with parameters
  
  ## Parameters
    - `arg0`: term()
    - `arg1`: term()
  """
  @spec t_try(term(), term()) :: {:t_try, term(), term()}
  def t_try(arg0, arg1) do
    {:t_try, arg0, arg1}
  end

  @doc """
  Creates t_return enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec t_return(term()) :: {:t_return, term()}
  def t_return(arg0) do
    {:t_return, arg0}
  end

  @doc "Creates t_break enum value"
  @spec t_break() :: :t_break
  def t_break(), do: :t_break

  @doc "Creates t_continue enum value"
  @spec t_continue() :: :t_continue
  def t_continue(), do: :t_continue

  @doc """
  Creates t_throw enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec t_throw(term()) :: {:t_throw, term()}
  def t_throw(arg0) do
    {:t_throw, arg0}
  end

  @doc """
  Creates t_cast enum value with parameters
  
  ## Parameters
    - `arg0`: term()
    - `arg1`: term()
  """
  @spec t_cast(term(), term()) :: {:t_cast, term(), term()}
  def t_cast(arg0, arg1) do
    {:t_cast, arg0, arg1}
  end

  @doc """
  Creates t_meta enum value with parameters
  
  ## Parameters
    - `arg0`: term()
    - `arg1`: term()
  """
  @spec t_meta(term(), term()) :: {:t_meta, term(), term()}
  def t_meta(arg0, arg1) do
    {:t_meta, arg0, arg1}
  end

  @doc """
  Creates t_enum_parameter enum value with parameters
  
  ## Parameters
    - `arg0`: term()
    - `arg1`: term()
    - `arg2`: term()
  """
  @spec t_enum_parameter(term(), term(), term()) :: {:t_enum_parameter, term(), term(), term()}
  def t_enum_parameter(arg0, arg1, arg2) do
    {:t_enum_parameter, arg0, arg1, arg2}
  end

  @doc """
  Creates t_enum_index enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec t_enum_index(term()) :: {:t_enum_index, term()}
  def t_enum_index(arg0) do
    {:t_enum_index, arg0}
  end

  @doc """
  Creates t_ident enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec t_ident(term()) :: {:t_ident, term()}
  def t_ident(arg0) do
    {:t_ident, arg0}
  end

  # Predicate functions for pattern matching
  @doc "Returns true if value is t_const variant"
  @spec is_t_const(t()) :: boolean()
  def is_t_const({:t_const, _}), do: true
  def is_t_const(_), do: false

  @doc "Returns true if value is t_local variant"
  @spec is_t_local(t()) :: boolean()
  def is_t_local({:t_local, _}), do: true
  def is_t_local(_), do: false

  @doc "Returns true if value is t_array variant"
  @spec is_t_array(t()) :: boolean()
  def is_t_array({:t_array, _}), do: true
  def is_t_array(_), do: false

  @doc "Returns true if value is t_binop variant"
  @spec is_t_binop(t()) :: boolean()
  def is_t_binop({:t_binop, _}), do: true
  def is_t_binop(_), do: false

  @doc "Returns true if value is t_field variant"
  @spec is_t_field(t()) :: boolean()
  def is_t_field({:t_field, _}), do: true
  def is_t_field(_), do: false

  @doc "Returns true if value is t_type_expr variant"
  @spec is_t_type_expr(t()) :: boolean()
  def is_t_type_expr({:t_type_expr, _}), do: true
  def is_t_type_expr(_), do: false

  @doc "Returns true if value is t_parenthesis variant"
  @spec is_t_parenthesis(t()) :: boolean()
  def is_t_parenthesis({:t_parenthesis, _}), do: true
  def is_t_parenthesis(_), do: false

  @doc "Returns true if value is t_object_decl variant"
  @spec is_t_object_decl(t()) :: boolean()
  def is_t_object_decl({:t_object_decl, _}), do: true
  def is_t_object_decl(_), do: false

  @doc "Returns true if value is t_array_decl variant"
  @spec is_t_array_decl(t()) :: boolean()
  def is_t_array_decl({:t_array_decl, _}), do: true
  def is_t_array_decl(_), do: false

  @doc "Returns true if value is t_call variant"
  @spec is_t_call(t()) :: boolean()
  def is_t_call({:t_call, _}), do: true
  def is_t_call(_), do: false

  @doc "Returns true if value is t_new variant"
  @spec is_t_new(t()) :: boolean()
  def is_t_new({:t_new, _}), do: true
  def is_t_new(_), do: false

  @doc "Returns true if value is t_unop variant"
  @spec is_t_unop(t()) :: boolean()
  def is_t_unop({:t_unop, _}), do: true
  def is_t_unop(_), do: false

  @doc "Returns true if value is t_function variant"
  @spec is_t_function(t()) :: boolean()
  def is_t_function({:t_function, _}), do: true
  def is_t_function(_), do: false

  @doc "Returns true if value is t_var variant"
  @spec is_t_var(t()) :: boolean()
  def is_t_var({:t_var, _}), do: true
  def is_t_var(_), do: false

  @doc "Returns true if value is t_block variant"
  @spec is_t_block(t()) :: boolean()
  def is_t_block({:t_block, _}), do: true
  def is_t_block(_), do: false

  @doc "Returns true if value is t_for variant"
  @spec is_t_for(t()) :: boolean()
  def is_t_for({:t_for, _}), do: true
  def is_t_for(_), do: false

  @doc "Returns true if value is t_if variant"
  @spec is_t_if(t()) :: boolean()
  def is_t_if({:t_if, _}), do: true
  def is_t_if(_), do: false

  @doc "Returns true if value is t_while variant"
  @spec is_t_while(t()) :: boolean()
  def is_t_while({:t_while, _}), do: true
  def is_t_while(_), do: false

  @doc "Returns true if value is t_switch variant"
  @spec is_t_switch(t()) :: boolean()
  def is_t_switch({:t_switch, _}), do: true
  def is_t_switch(_), do: false

  @doc "Returns true if value is t_try variant"
  @spec is_t_try(t()) :: boolean()
  def is_t_try({:t_try, _}), do: true
  def is_t_try(_), do: false

  @doc "Returns true if value is t_return variant"
  @spec is_t_return(t()) :: boolean()
  def is_t_return({:t_return, _}), do: true
  def is_t_return(_), do: false

  @doc "Returns true if value is t_break variant"
  @spec is_t_break(t()) :: boolean()
  def is_t_break(:t_break), do: true
  def is_t_break(_), do: false

  @doc "Returns true if value is t_continue variant"
  @spec is_t_continue(t()) :: boolean()
  def is_t_continue(:t_continue), do: true
  def is_t_continue(_), do: false

  @doc "Returns true if value is t_throw variant"
  @spec is_t_throw(t()) :: boolean()
  def is_t_throw({:t_throw, _}), do: true
  def is_t_throw(_), do: false

  @doc "Returns true if value is t_cast variant"
  @spec is_t_cast(t()) :: boolean()
  def is_t_cast({:t_cast, _}), do: true
  def is_t_cast(_), do: false

  @doc "Returns true if value is t_meta variant"
  @spec is_t_meta(t()) :: boolean()
  def is_t_meta({:t_meta, _}), do: true
  def is_t_meta(_), do: false

  @doc "Returns true if value is t_enum_parameter variant"
  @spec is_t_enum_parameter(t()) :: boolean()
  def is_t_enum_parameter({:t_enum_parameter, _}), do: true
  def is_t_enum_parameter(_), do: false

  @doc "Returns true if value is t_enum_index variant"
  @spec is_t_enum_index(t()) :: boolean()
  def is_t_enum_index({:t_enum_index, _}), do: true
  def is_t_enum_index(_), do: false

  @doc "Returns true if value is t_ident variant"
  @spec is_t_ident(t()) :: boolean()
  def is_t_ident({:t_ident, _}), do: true
  def is_t_ident(_), do: false

  @doc "Extracts value from t_const variant, returns {:ok, value} or :error"
  @spec get_t_const_value(t()) :: {:ok, term()} | :error
  def get_t_const_value({:t_const, value}), do: {:ok, value}
  def get_t_const_value(_), do: :error

  @doc "Extracts value from t_local variant, returns {:ok, value} or :error"
  @spec get_t_local_value(t()) :: {:ok, term()} | :error
  def get_t_local_value({:t_local, value}), do: {:ok, value}
  def get_t_local_value(_), do: :error

  @doc "Extracts value from t_array variant, returns {:ok, value} or :error"
  @spec get_t_array_value(t()) :: {:ok, {term(), term()}} | :error
  def get_t_array_value({:t_array, arg0, arg1}), do: {:ok, {arg0, arg1}}
  def get_t_array_value(_), do: :error

  @doc "Extracts value from t_binop variant, returns {:ok, value} or :error"
  @spec get_t_binop_value(t()) :: {:ok, {term(), term(), term()}} | :error
  def get_t_binop_value({:t_binop, arg0, arg1, arg2}), do: {:ok, {arg0, arg1, arg2}}
  def get_t_binop_value(_), do: :error

  @doc "Extracts value from t_field variant, returns {:ok, value} or :error"
  @spec get_t_field_value(t()) :: {:ok, {term(), term()}} | :error
  def get_t_field_value({:t_field, arg0, arg1}), do: {:ok, {arg0, arg1}}
  def get_t_field_value(_), do: :error

  @doc "Extracts value from t_type_expr variant, returns {:ok, value} or :error"
  @spec get_t_type_expr_value(t()) :: {:ok, term()} | :error
  def get_t_type_expr_value({:t_type_expr, value}), do: {:ok, value}
  def get_t_type_expr_value(_), do: :error

  @doc "Extracts value from t_parenthesis variant, returns {:ok, value} or :error"
  @spec get_t_parenthesis_value(t()) :: {:ok, term()} | :error
  def get_t_parenthesis_value({:t_parenthesis, value}), do: {:ok, value}
  def get_t_parenthesis_value(_), do: :error

  @doc "Extracts value from t_object_decl variant, returns {:ok, value} or :error"
  @spec get_t_object_decl_value(t()) :: {:ok, term()} | :error
  def get_t_object_decl_value({:t_object_decl, value}), do: {:ok, value}
  def get_t_object_decl_value(_), do: :error

  @doc "Extracts value from t_array_decl variant, returns {:ok, value} or :error"
  @spec get_t_array_decl_value(t()) :: {:ok, term()} | :error
  def get_t_array_decl_value({:t_array_decl, value}), do: {:ok, value}
  def get_t_array_decl_value(_), do: :error

  @doc "Extracts value from t_call variant, returns {:ok, value} or :error"
  @spec get_t_call_value(t()) :: {:ok, {term(), term()}} | :error
  def get_t_call_value({:t_call, arg0, arg1}), do: {:ok, {arg0, arg1}}
  def get_t_call_value(_), do: :error

  @doc "Extracts value from t_new variant, returns {:ok, value} or :error"
  @spec get_t_new_value(t()) :: {:ok, {term(), term(), term()}} | :error
  def get_t_new_value({:t_new, arg0, arg1, arg2}), do: {:ok, {arg0, arg1, arg2}}
  def get_t_new_value(_), do: :error

  @doc "Extracts value from t_unop variant, returns {:ok, value} or :error"
  @spec get_t_unop_value(t()) :: {:ok, {term(), term(), term()}} | :error
  def get_t_unop_value({:t_unop, arg0, arg1, arg2}), do: {:ok, {arg0, arg1, arg2}}
  def get_t_unop_value(_), do: :error

  @doc "Extracts value from t_function variant, returns {:ok, value} or :error"
  @spec get_t_function_value(t()) :: {:ok, term()} | :error
  def get_t_function_value({:t_function, value}), do: {:ok, value}
  def get_t_function_value(_), do: :error

  @doc "Extracts value from t_var variant, returns {:ok, value} or :error"
  @spec get_t_var_value(t()) :: {:ok, {term(), term()}} | :error
  def get_t_var_value({:t_var, arg0, arg1}), do: {:ok, {arg0, arg1}}
  def get_t_var_value(_), do: :error

  @doc "Extracts value from t_block variant, returns {:ok, value} or :error"
  @spec get_t_block_value(t()) :: {:ok, term()} | :error
  def get_t_block_value({:t_block, value}), do: {:ok, value}
  def get_t_block_value(_), do: :error

  @doc "Extracts value from t_for variant, returns {:ok, value} or :error"
  @spec get_t_for_value(t()) :: {:ok, {term(), term(), term()}} | :error
  def get_t_for_value({:t_for, arg0, arg1, arg2}), do: {:ok, {arg0, arg1, arg2}}
  def get_t_for_value(_), do: :error

  @doc "Extracts value from t_if variant, returns {:ok, value} or :error"
  @spec get_t_if_value(t()) :: {:ok, {term(), term(), term()}} | :error
  def get_t_if_value({:t_if, arg0, arg1, arg2}), do: {:ok, {arg0, arg1, arg2}}
  def get_t_if_value(_), do: :error

  @doc "Extracts value from t_while variant, returns {:ok, value} or :error"
  @spec get_t_while_value(t()) :: {:ok, {term(), term(), term()}} | :error
  def get_t_while_value({:t_while, arg0, arg1, arg2}), do: {:ok, {arg0, arg1, arg2}}
  def get_t_while_value(_), do: :error

  @doc "Extracts value from t_switch variant, returns {:ok, value} or :error"
  @spec get_t_switch_value(t()) :: {:ok, {term(), term(), term()}} | :error
  def get_t_switch_value({:t_switch, arg0, arg1, arg2}), do: {:ok, {arg0, arg1, arg2}}
  def get_t_switch_value(_), do: :error

  @doc "Extracts value from t_try variant, returns {:ok, value} or :error"
  @spec get_t_try_value(t()) :: {:ok, {term(), term()}} | :error
  def get_t_try_value({:t_try, arg0, arg1}), do: {:ok, {arg0, arg1}}
  def get_t_try_value(_), do: :error

  @doc "Extracts value from t_return variant, returns {:ok, value} or :error"
  @spec get_t_return_value(t()) :: {:ok, term()} | :error
  def get_t_return_value({:t_return, value}), do: {:ok, value}
  def get_t_return_value(_), do: :error

  @doc "Extracts value from t_throw variant, returns {:ok, value} or :error"
  @spec get_t_throw_value(t()) :: {:ok, term()} | :error
  def get_t_throw_value({:t_throw, value}), do: {:ok, value}
  def get_t_throw_value(_), do: :error

  @doc "Extracts value from t_cast variant, returns {:ok, value} or :error"
  @spec get_t_cast_value(t()) :: {:ok, {term(), term()}} | :error
  def get_t_cast_value({:t_cast, arg0, arg1}), do: {:ok, {arg0, arg1}}
  def get_t_cast_value(_), do: :error

  @doc "Extracts value from t_meta variant, returns {:ok, value} or :error"
  @spec get_t_meta_value(t()) :: {:ok, {term(), term()}} | :error
  def get_t_meta_value({:t_meta, arg0, arg1}), do: {:ok, {arg0, arg1}}
  def get_t_meta_value(_), do: :error

  @doc "Extracts value from t_enum_parameter variant, returns {:ok, value} or :error"
  @spec get_t_enum_parameter_value(t()) :: {:ok, {term(), term(), term()}} | :error
  def get_t_enum_parameter_value({:t_enum_parameter, arg0, arg1, arg2}), do: {:ok, {arg0, arg1, arg2}}
  def get_t_enum_parameter_value(_), do: :error

  @doc "Extracts value from t_enum_index variant, returns {:ok, value} or :error"
  @spec get_t_enum_index_value(t()) :: {:ok, term()} | :error
  def get_t_enum_index_value({:t_enum_index, value}), do: {:ok, value}
  def get_t_enum_index_value(_), do: :error

  @doc "Extracts value from t_ident variant, returns {:ok, value} or :error"
  @spec get_t_ident_value(t()) :: {:ok, term()} | :error
  def get_t_ident_value({:t_ident, value}), do: {:ok, value}
  def get_t_ident_value(_), do: :error

end
