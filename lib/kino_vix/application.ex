defmodule KinoVix.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    Kino.SmartCell.register(KinoVix.OperationCell)

    children = []
    opts = [strategy: :one_for_one, name: KinoVix.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
