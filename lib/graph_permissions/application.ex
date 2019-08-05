defmodule GraphPermissions.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    # List all child processes to be supervised
    children = [
      # Starts a worker by calling: GraphPermissions.Worker.start_link(arg)
      # {GraphPermissions.Worker, arg}
      {Bolt.Sips, Application.get_env(:bolt_sips, Bolt)}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: GraphPermissions.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
