defmodule HttpMethod do
  @moduledoc """
  HttpMethod enum generated from Haxe
  
  
 * Type-safe HTTP methods for Router DSL
 * 
 * Provides compile-time validation and IDE autocomplete for route methods
 * instead of error-prone string literals.
 
  
  This module provides tagged tuple constructors and pattern matching helpers.
  """

  @type t() ::
    :p_u_t |
    :p_o_s_t |
    :p_a_t_c_h |
    :l_i_v_e__d_a_s_h_b_o_a_r_d |
    :l_i_v_e |
    :g_e_t |
    :d_e_l_e_t_e

  @doc "Creates p_u_t enum value"
  @spec p_u_t() :: :p_u_t
  def p_u_t(), do: :p_u_t

  @doc "Creates p_o_s_t enum value"
  @spec p_o_s_t() :: :p_o_s_t
  def p_o_s_t(), do: :p_o_s_t

  @doc "Creates p_a_t_c_h enum value"
  @spec p_a_t_c_h() :: :p_a_t_c_h
  def p_a_t_c_h(), do: :p_a_t_c_h

  @doc "Creates l_i_v_e__d_a_s_h_b_o_a_r_d enum value"
  @spec l_i_v_e__d_a_s_h_b_o_a_r_d() :: :l_i_v_e__d_a_s_h_b_o_a_r_d
  def l_i_v_e__d_a_s_h_b_o_a_r_d(), do: :l_i_v_e__d_a_s_h_b_o_a_r_d

  @doc "Creates l_i_v_e enum value"
  @spec l_i_v_e() :: :l_i_v_e
  def l_i_v_e(), do: :l_i_v_e

  @doc "Creates g_e_t enum value"
  @spec g_e_t() :: :g_e_t
  def g_e_t(), do: :g_e_t

  @doc "Creates d_e_l_e_t_e enum value"
  @spec d_e_l_e_t_e() :: :d_e_l_e_t_e
  def d_e_l_e_t_e(), do: :d_e_l_e_t_e

  # Predicate functions for pattern matching
  @doc "Returns true if value is p_u_t variant"
  @spec is_p_u_t(t()) :: boolean()
  def is_p_u_t(:p_u_t), do: true
  def is_p_u_t(_), do: false

  @doc "Returns true if value is p_o_s_t variant"
  @spec is_p_o_s_t(t()) :: boolean()
  def is_p_o_s_t(:p_o_s_t), do: true
  def is_p_o_s_t(_), do: false

  @doc "Returns true if value is p_a_t_c_h variant"
  @spec is_p_a_t_c_h(t()) :: boolean()
  def is_p_a_t_c_h(:p_a_t_c_h), do: true
  def is_p_a_t_c_h(_), do: false

  @doc "Returns true if value is l_i_v_e__d_a_s_h_b_o_a_r_d variant"
  @spec is_l_i_v_e__d_a_s_h_b_o_a_r_d(t()) :: boolean()
  def is_l_i_v_e__d_a_s_h_b_o_a_r_d(:l_i_v_e__d_a_s_h_b_o_a_r_d), do: true
  def is_l_i_v_e__d_a_s_h_b_o_a_r_d(_), do: false

  @doc "Returns true if value is l_i_v_e variant"
  @spec is_l_i_v_e(t()) :: boolean()
  def is_l_i_v_e(:l_i_v_e), do: true
  def is_l_i_v_e(_), do: false

  @doc "Returns true if value is g_e_t variant"
  @spec is_g_e_t(t()) :: boolean()
  def is_g_e_t(:g_e_t), do: true
  def is_g_e_t(_), do: false

  @doc "Returns true if value is d_e_l_e_t_e variant"
  @spec is_d_e_l_e_t_e(t()) :: boolean()
  def is_d_e_l_e_t_e(:d_e_l_e_t_e), do: true
  def is_d_e_l_e_t_e(_), do: false

end
