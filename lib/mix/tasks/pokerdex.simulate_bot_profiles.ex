defmodule Mix.Tasks.Pokerdex.SimulateBotProfiles do
  @shortdoc "Simulate and save bot playstyle profiles"

  @moduledoc "Simulates bot hands and saves baseline playstyle metrics under priv/poker."
  use Mix.Task

  alias Zoonk.Poker.Bot.PlaystyleSimulation

  @impl Mix.Task
  def run(args) do
    {opts, positional, invalid} = OptionParser.parse(args, strict: [hands: :integer])
    hands = Keyword.get(opts, :hands, 1_000)

    if positional != [] or invalid != [] or hands <= 0 do
      Mix.raise("Usage: mix pokerdex.simulate_bot_profiles [--hands 1000]")
    end

    # The web server may already be running in another terminal, so this
    # one-off task must not compete for its PromEx HTTP listener port.
    Application.put_env(:zoonk, Zoonk.PromEx, metrics_server: :disabled)
    Mix.Task.run("app.start")
    Mix.shell().info("Simulating #{hands} six-player hands for each Home bot...")

    profiles = PlaystyleSimulation.simulate_all(hands)
    path = PlaystyleSimulation.save_profiles!(profiles, hands)

    Mix.shell().info("Saved simulated bot playstyles to #{path}")
  end
end
