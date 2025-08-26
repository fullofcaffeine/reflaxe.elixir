defmodule TypeSafeChildSpecBuilder do
  @moduledoc """
    TypeSafeChildSpecBuilder module generated from Haxe

     * Builder functions for common child spec patterns
     *
     * These provide convenient factory methods for creating type-safe child specs
     * with sensible defaults and proper Phoenix conventions.
  """

  # Static functions
  @doc """
    Create a Phoenix.PubSub child spec

    @param appName Application name (e.g., "TodoApp")
    @return TypeSafeChildSpec for Phoenix.PubSub
  """
  @spec pubsub(String.t()) :: TypeSafeChildSpec.t()
  def pubsub(app_name) do
    {Phoenix.PubSub, name: app_name <> ".PubSub"}
  end

  @doc """
    Create an Ecto repository child spec

    @param appName Application name (e.g., "TodoApp")
    @param config Optional repository configuration
    @return TypeSafeChildSpec for repository
  """
  @spec repo(String.t(), Null.t()) :: TypeSafeChildSpec.t()
  def repo(app_name, config) do
    App.Repo
  end

  @doc """
    Create a Phoenix endpoint child spec

    @param appName Application name (e.g., "TodoApp")
    @param port Optional port number (defaults to 4000)
    @param config Optional endpoint configuration
    @return TypeSafeChildSpec for endpoint
  """
  @spec endpoint(String.t(), Null.t(), Null.t()) :: TypeSafeChildSpec.t()
  def endpoint(app_name, port, config) do
    (
          temp_number = nil
          temp_number = nil
    tmp = port
    temp_number = if (((tmp != nil))), do: tmp, else: 4000
          AppWeb.Endpoint
        )
  end

  @doc """
    Create a telemetry supervisor child spec

    @param appName Application name (e.g., "TodoApp")
    @param config Optional telemetry configuration
    @return TypeSafeChildSpec for telemetry
  """
  @spec telemetry(String.t(), Null.t()) :: TypeSafeChildSpec.t()
  def telemetry(app_name, config) do
    AppWeb.Telemetry
  end

  @doc """
    Create a Phoenix Presence child spec

    @param appName Application name (e.g., "TodoApp")
    @param pubsubName Optional PubSub server name
    @return TypeSafeChildSpec for presence
  """
  @spec presence(String.t(), Null.t()) :: TypeSafeChildSpec.t()
  def presence(app_name, pubsub_name) do
    (
          temp_string = nil
          temp_string = nil
    tmp = pubsub_name
    temp_string = if (((tmp != nil))), do: tmp, else: "" <> app_name <> ".PubSub"
          {:presence, %{"name" => "" <> app_name <> ".Presence", "pubsub_server" => temp_string}}
        )
  end

  @doc """
    Create a worker child spec for custom modules

    @param T The type of the worker's initialization argument
    @param module The worker module class
    @param args Initialization arguments for the worker
    @return TypeSafeChildSpec for custom worker
  """
  @spec worker(Class.t(), T.t()) :: TypeSafeChildSpec.t()
  def worker(module, args) do
    {:custom, module, args, :permanent, ShutdownType.timeout(5000)}
  end

  @doc """
    Create a supervisor child spec for custom modules

    @param T The type of the supervisor's initialization argument
    @param module The supervisor module class
    @param args Initialization arguments for the supervisor
    @return TypeSafeChildSpec for custom supervisor
  """
  @spec supervisor(Class.t(), T.t()) :: TypeSafeChildSpec.t()
  def supervisor(module, args) do
    {:custom, module, args, :permanent, :infinity}
  end

end
