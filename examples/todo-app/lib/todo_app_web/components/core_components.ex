defmodule TodoAppWeb.CoreComponents do
  @moduledoc """
  Provides core UI components for TodoApp.
  
  This module contains minimal Phoenix component functions needed for the
  todo app to function. These are typically shared UI patterns.
  """
  use Phoenix.Component

  @doc """
  Renders a modal dialog.
  """
  attr :id, :string, required: true
  attr :show, :boolean, default: false
  slot :inner_block, required: true

  def modal(assigns) do
    ~H"""
    <div
      id={@id}
      phx-mounted={@show && show_modal(@id)}
      phx-remove={hide_modal(@id)}
      data-cancel={JS.exec("phx-remove", to: "##{@id}")}
      class={"fixed z-50 inset-0 overflow-y-auto #{unless @show, do: "hidden"}"}
    >
      <div class="flex items-center justify-center min-h-screen px-4">
        <div class="fixed inset-0 bg-gray-500 bg-opacity-75 transition-opacity" aria-hidden="true"></div>
        <div class="bg-white rounded-lg overflow-hidden shadow-xl transform transition-all sm:max-w-lg sm:w-full">
          <%= render_slot(@inner_block) %>
        </div>
      </div>
    </div>
    """
  end

  @doc """
  Renders a button.
  """
  attr :type, :string, default: nil
  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(disabled form name value)
  slot :inner_block, required: true

  def button(assigns) do
    ~H"""
    <button
      type={@type}
      class={[
        "phx-submit-loading:opacity-75 rounded-lg bg-zinc-900 hover:bg-zinc-700 py-2 px-3",
        "text-sm font-semibold leading-6 text-white active:text-white/80",
        @class
      ]}
      {@rest}
    >
      <%= render_slot(@inner_block) %>
    </button>
    """
  end

  @doc """
  Renders an input field.
  """
  attr :id, :any, default: nil
  attr :name, :any
  attr :label, :string, default: nil
  attr :value, :any
  attr :type, :string, default: "text"
  attr :field, Phoenix.HTML.FormField, default: nil
  attr :errors, :list, default: []
  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(accept autocomplete disabled form max min pattern placeholder readonly required)

  def input(assigns) do
    assigns = assign_field(assigns)
    ~H"""
    <div>
      <.label :if={@label} for={@id}><%= @label %></.label>
      <input
        type={@type}
        name={@name}
        id={@id}
        value={Phoenix.HTML.Form.normalize_value(@type, @value)}
        class={[
          "mt-2 block w-full rounded-lg text-zinc-900 focus:ring-0 sm:text-sm sm:leading-6",
          "border-zinc-300 focus:border-zinc-400",
          @errors != [] && "border-rose-400 focus:border-rose-400",
          @class
        ]}
        {@rest}
      />
      <.error :for={msg <- @errors}><%= msg %></.error>
    </div>
    """
  end

  @doc """
  Renders a label.
  """
  attr :for, :string, default: nil
  slot :inner_block, required: true

  def label(assigns) do
    ~H"""
    <label for={@for} class="block text-sm font-semibold leading-6 text-zinc-800">
      <%= render_slot(@inner_block) %>
    </label>
    """
  end

  @doc """
  Renders error messages.
  """
  slot :inner_block, required: true

  def error(assigns) do
    ~H"""
    <p class="mt-3 flex gap-3 text-sm leading-6 text-rose-600">
      <%= render_slot(@inner_block) %>
    </p>
    """
  end

  @doc """
  Renders flash notices.
  """
  attr :id, :string, default: "flash"
  attr :flash, :map, required: true
  attr :kind, :atom, default: nil

  def flash(assigns) do
    assigns = assign_flash_kind(assigns)
    ~H"""
    <div
      :if={@flash[@kind]}
      id={@id}
      class={[
        "fixed top-2 right-2 z-50 rounded-lg p-3 shadow-md",
        @kind == :info && "bg-blue-50 text-blue-800",
        @kind == :error && "bg-red-50 text-red-800"
      ]}
    >
      <p class="text-sm font-medium"><%= @flash[@kind] %></p>
    </div>
    """
  end

  @doc """
  Shows the modal by executing JavaScript.
  """
  def show_modal(js \\ %JS{}, id) do
    js
    |> JS.show(to: "##{id}")
    |> JS.focus_first(to: "##{id}")
  end

  @doc """
  Hides the modal.
  """
  def hide_modal(js \\ %JS{}, id) do
    js
    |> JS.hide(to: "##{id}")
    |> JS.pop_focus()
  end

  # Private functions

  defp assign_field(assigns) do
    if assigns[:field] do
      assigns
      |> assign(:id, assigns.id || assigns.field.id)
      |> assign(:name, assigns.name || assigns.field.name)
      |> assign(:value, assigns.value || assigns.field.value)
      |> assign(:errors, assigns.errors || assigns.field.errors)
    else
      assigns
    end
  end

  defp assign_flash_kind(assigns) do
    if assigns[:kind] do
      assigns
    else
      if assigns.flash["info"], do: assign(assigns, :kind, :info), else: assign(assigns, :kind, :error)
    end
  end

  # Import Phoenix LiveView JS commands
  alias Phoenix.LiveView.JS
end