defmodule SupervisorStrategy do
  @moduledoc """
  SupervisorStrategy enum generated from Haxe
  
  
 * Supervisor restart strategies
 
  
  This module provides tagged tuple constructors and pattern matching helpers.
  """

  @type t() ::
    :r_e_s_t__f_o_r__o_n_e |
    :o_n_e__f_o_r__o_n_e |
    :o_n_e__f_o_r__a_l_l

  @doc "Creates r_e_s_t__f_o_r__o_n_e enum value"
  @spec r_e_s_t__f_o_r__o_n_e() :: :r_e_s_t__f_o_r__o_n_e
  def r_e_s_t__f_o_r__o_n_e(), do: :r_e_s_t__f_o_r__o_n_e

  @doc "Creates o_n_e__f_o_r__o_n_e enum value"
  @spec o_n_e__f_o_r__o_n_e() :: :o_n_e__f_o_r__o_n_e
  def o_n_e__f_o_r__o_n_e(), do: :o_n_e__f_o_r__o_n_e

  @doc "Creates o_n_e__f_o_r__a_l_l enum value"
  @spec o_n_e__f_o_r__a_l_l() :: :o_n_e__f_o_r__a_l_l
  def o_n_e__f_o_r__a_l_l(), do: :o_n_e__f_o_r__a_l_l

  # Predicate functions for pattern matching
  @doc "Returns true if value is r_e_s_t__f_o_r__o_n_e variant"
  @spec is_r_e_s_t__f_o_r__o_n_e(t()) :: boolean()
  def is_r_e_s_t__f_o_r__o_n_e(:r_e_s_t__f_o_r__o_n_e), do: true
  def is_r_e_s_t__f_o_r__o_n_e(_), do: false

  @doc "Returns true if value is o_n_e__f_o_r__o_n_e variant"
  @spec is_o_n_e__f_o_r__o_n_e(t()) :: boolean()
  def is_o_n_e__f_o_r__o_n_e(:o_n_e__f_o_r__o_n_e), do: true
  def is_o_n_e__f_o_r__o_n_e(_), do: false

  @doc "Returns true if value is o_n_e__f_o_r__a_l_l variant"
  @spec is_o_n_e__f_o_r__a_l_l(t()) :: boolean()
  def is_o_n_e__f_o_r__a_l_l(:o_n_e__f_o_r__a_l_l), do: true
  def is_o_n_e__f_o_r__a_l_l(_), do: false

end


defmodule RestartOption do
  @moduledoc """
  RestartOption enum generated from Haxe
  
  
 * Child restart options
 
  
  This module provides tagged tuple constructors and pattern matching helpers.
  """

  @type t() ::
    :t_r_a_n_s_i_e_n_t |
    :t_e_m_p_o_r_a_r_y |
    :p_e_r_m_a_n_e_n_t

  @doc "Creates t_r_a_n_s_i_e_n_t enum value"
  @spec t_r_a_n_s_i_e_n_t() :: :t_r_a_n_s_i_e_n_t
  def t_r_a_n_s_i_e_n_t(), do: :t_r_a_n_s_i_e_n_t

  @doc "Creates t_e_m_p_o_r_a_r_y enum value"
  @spec t_e_m_p_o_r_a_r_y() :: :t_e_m_p_o_r_a_r_y
  def t_e_m_p_o_r_a_r_y(), do: :t_e_m_p_o_r_a_r_y

  @doc "Creates p_e_r_m_a_n_e_n_t enum value"
  @spec p_e_r_m_a_n_e_n_t() :: :p_e_r_m_a_n_e_n_t
  def p_e_r_m_a_n_e_n_t(), do: :p_e_r_m_a_n_e_n_t

  # Predicate functions for pattern matching
  @doc "Returns true if value is t_r_a_n_s_i_e_n_t variant"
  @spec is_t_r_a_n_s_i_e_n_t(t()) :: boolean()
  def is_t_r_a_n_s_i_e_n_t(:t_r_a_n_s_i_e_n_t), do: true
  def is_t_r_a_n_s_i_e_n_t(_), do: false

  @doc "Returns true if value is t_e_m_p_o_r_a_r_y variant"
  @spec is_t_e_m_p_o_r_a_r_y(t()) :: boolean()
  def is_t_e_m_p_o_r_a_r_y(:t_e_m_p_o_r_a_r_y), do: true
  def is_t_e_m_p_o_r_a_r_y(_), do: false

  @doc "Returns true if value is p_e_r_m_a_n_e_n_t variant"
  @spec is_p_e_r_m_a_n_e_n_t(t()) :: boolean()
  def is_p_e_r_m_a_n_e_n_t(:p_e_r_m_a_n_e_n_t), do: true
  def is_p_e_r_m_a_n_e_n_t(_), do: false

end
