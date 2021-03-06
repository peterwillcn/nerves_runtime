defmodule Nerves.Runtime.Application do
  @moduledoc false

  use Application

  alias Nerves.Runtime.{
    Init,
    Kernel,
    KV,
    LogTailer
  }

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    # On systems with hardware random number generation, it is important that
    # "rngd" gets started as soon as possible to start adding entropy to the
    # system. So much code directly or indirectly uses random numbers that it's
    # very easy to block on the random number generator or get low entropy
    # numbers.
    try_rngd()

    children = [
      worker(LogTailer, [:syslog], id: :syslog),
      worker(LogTailer, [:kmsg], id: :kmsg),
      supervisor(Kernel, []),
      worker(KV, []),
      worker(Init, [])
    ]

    opts = [strategy: :one_for_one, name: Nerves.Runtime.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp try_rngd() do
    rngd_path = "/usr/sbin/rngd"

    if File.exists?(rngd_path) do
      # Launch rngd. It daemonizes itself so this should return quickly.
      System.cmd(rngd_path, [])
    end
  end
end
