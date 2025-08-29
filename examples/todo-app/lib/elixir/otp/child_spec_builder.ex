defmodule ChildSpecBuilder do
  @moduledoc """
    ChildSpecBuilder module generated from Haxe

     * Helper class for creating child specifications
  """

  # Static functions
  @doc "Generated from Haxe worker"
  def worker(module, args, id \\ nil) do
    temp_string = nil

    temp_string = nil
    if (id != nil) do
      temp_string = id
    else
      temp_string = module
    end
    %{:id => temp_string, :start => %{:module => module, :func => "start_link", :args => args}, :restart => :Permanent, :shutdown => {:Timeout, 5000}, :type => :Worker, :modules => [module]}
  end

  @doc "Generated from Haxe supervisor"
  def supervisor(module, args, id \\ nil) do
    temp_string = nil

    temp_string = nil
    if (id != nil) do
      temp_string = id
    else
      temp_string = module
    end
    %{:id => temp_string, :start => %{:module => module, :func => "start_link", :args => args}, :restart => :Permanent, :shutdown => :Infinity, :type => :Supervisor, :modules => [module]}
  end

  @doc "Generated from Haxe tempWorker"
  def temp_worker(module, args, id \\ nil) do
    spec = :ChildSpecBuilder.worker(module, args, id)
    restart = :Temporary
    spec
  end

end
