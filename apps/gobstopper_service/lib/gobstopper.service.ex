defmodule Gobstopper.Service do
    @moduledoc """
      The service application for identities and credentials.

      ## Configurable Options

      * `:server` - The name the server should be registered as. This takes a
      function that accepts a module and returns a valid named server.

      An example configuration:

        config :gobstopper_service,
            server: &(&1)
    """

    use Application

    @doc """
      Start the service application.

      By default the service will run in `:auto` setup mode, which
      will automatically create and migrate the database. To override
      this behaviour, the mode can be passed in as an argument for the
      `:setup_mode` key. The supported setup modes are: `:auto` and
      `:manual`. If using manual mode, the state of the database is
      left up to the caller.
    """
    def start(_type, args) do
        import Supervisor.Spec, warn: false

        setup_mode = args[:setup_mode] || :auto

        if setup_mode == :auto do
            prepare_db()
            Gobstopper.Service.Repo.DB.create()
        end

        children = [
            Gobstopper.Service.Repo,
            Guardian.DB.Token.SweeperServer,
            Gobstopper.Service.Auth
        ]

        opts = [strategy: :one_for_one, name: Gobstopper.Service.Supervisor]
        supervisor = Supervisor.start_link(children, opts)

        if setup_mode == :auto do
            Gobstopper.Service.Repo.DB.migrate()
        end

        supervisor
    end

    if Mix.env == :test do
        defp prepare_db(), do: Gobstopper.Service.Repo.DB.drop()
    else
        defp prepare_db(), do: :ok
    end
end
