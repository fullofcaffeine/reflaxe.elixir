defmodule HttpMethod do
  @moduledoc """
  HttpMethod enum generated from Haxe
  
  
 * HTTP methods enum
 
  
  This module provides tagged tuple constructors and pattern matching helpers.
  """

  @type t() ::
    :g_e_t |
    :p_o_s_t |
    :p_u_t |
    :p_a_t_c_h |
    :d_e_l_e_t_e |
    :h_e_a_d |
    :o_p_t_i_o_n_s

  @doc "Creates g_e_t enum value"
  @spec g_e_t() :: :g_e_t
  def g_e_t(), do: :g_e_t

  @doc "Creates p_o_s_t enum value"
  @spec p_o_s_t() :: :p_o_s_t
  def p_o_s_t(), do: :p_o_s_t

  @doc "Creates p_u_t enum value"
  @spec p_u_t() :: :p_u_t
  def p_u_t(), do: :p_u_t

  @doc "Creates p_a_t_c_h enum value"
  @spec p_a_t_c_h() :: :p_a_t_c_h
  def p_a_t_c_h(), do: :p_a_t_c_h

  @doc "Creates d_e_l_e_t_e enum value"
  @spec d_e_l_e_t_e() :: :d_e_l_e_t_e
  def d_e_l_e_t_e(), do: :d_e_l_e_t_e

  @doc "Creates h_e_a_d enum value"
  @spec h_e_a_d() :: :h_e_a_d
  def h_e_a_d(), do: :h_e_a_d

  @doc "Creates o_p_t_i_o_n_s enum value"
  @spec o_p_t_i_o_n_s() :: :o_p_t_i_o_n_s
  def o_p_t_i_o_n_s(), do: :o_p_t_i_o_n_s

  # Predicate functions for pattern matching
  @doc "Returns true if value is g_e_t variant"
  @spec is_g_e_t(t()) :: boolean()
  def is_g_e_t(:g_e_t), do: true
  def is_g_e_t(_), do: false

  @doc "Returns true if value is p_o_s_t variant"
  @spec is_p_o_s_t(t()) :: boolean()
  def is_p_o_s_t(:p_o_s_t), do: true
  def is_p_o_s_t(_), do: false

  @doc "Returns true if value is p_u_t variant"
  @spec is_p_u_t(t()) :: boolean()
  def is_p_u_t(:p_u_t), do: true
  def is_p_u_t(_), do: false

  @doc "Returns true if value is p_a_t_c_h variant"
  @spec is_p_a_t_c_h(t()) :: boolean()
  def is_p_a_t_c_h(:p_a_t_c_h), do: true
  def is_p_a_t_c_h(_), do: false

  @doc "Returns true if value is d_e_l_e_t_e variant"
  @spec is_d_e_l_e_t_e(t()) :: boolean()
  def is_d_e_l_e_t_e(:d_e_l_e_t_e), do: true
  def is_d_e_l_e_t_e(_), do: false

  @doc "Returns true if value is h_e_a_d variant"
  @spec is_h_e_a_d(t()) :: boolean()
  def is_h_e_a_d(:h_e_a_d), do: true
  def is_h_e_a_d(_), do: false

  @doc "Returns true if value is o_p_t_i_o_n_s variant"
  @spec is_o_p_t_i_o_n_s(t()) :: boolean()
  def is_o_p_t_i_o_n_s(:o_p_t_i_o_n_s), do: true
  def is_o_p_t_i_o_n_s(_), do: false

end
