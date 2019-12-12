defmodule Proj4.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    # List all child processes to be supervised
    IO.puts("started")
    # {num_users, num_messages} = System.argv() |> parseArguments

    children = [
      # Start the Twitter Engine
      Proj4.TwitterEngine,
      # Start the Twitter Client Simulator
      # {Proj4.Simulator, {num_users, num_messages}}
      {Proj4.Simulator, {20, 5}},
      # Start the Ecto repository
      Proj4.Repo,
      # Start the endpoint when the application starts
      Proj4Web.Endpoint
      # Starts a worker by calling: Proj4.Worker.start_link(arg)
      # {Proj4.Worker, arg},
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Proj4.Supervisor]
    Supervisor.start_link(children, opts)
    Process.sleep(:infinity)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    Proj4Web.Endpoint.config_change(changed, removed)
    :ok
  end

  def parseArguments(arguments) do
    parse =
      OptionParser.parse(arguments,
        strict: [num_users: :integer, num_messages: :integer]
      )

    case parse do
      # {[help: true], _, _} ->
      # :help

      {_, [u, m], _} ->
        {String.to_integer(u), String.to_integer(m)}

      _ ->
        :help
    end
  end
end
