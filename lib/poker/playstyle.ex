defmodule Zoonk.Poker.Playstyle do
  @moduledoc "Shared graph calibration and labels for the playstyle profile."

  # Adjust these cutoffs to change the playstyle tags without changing how the
  # bots make decisions. Bot behavior itself is tuned in Zoonk.Poker.Bot.Profiles.
  @loose_vpip_threshold 30
  @passive_aggression_threshold 40
  @aggressive_aggression_threshold 60

  @tight_aggressive {241, 154, 99}
  @loose_aggressive {213, 187, 88}
  @tight_passive {137, 164, 204}
  @loose_passive {91, 188, 169}

  def aggression_score(aggressive_actions, calls) when aggressive_actions + calls < 10, do: 50
  def aggression_score(aggressive_actions, 0) when aggressive_actions > 0, do: 100

  def aggression_score(aggressive_actions, calls) do
    factor = aggressive_actions / calls
    round(100 * factor / (1 + factor))
  end

  def style_title(vpip, aggression_score) do
    looseness = if vpip >= @loose_vpip_threshold, do: "Loose", else: "Tight"

    aggression =
      cond do
        aggression_score < @passive_aggression_threshold -> "Passive"
        aggression_score >= @aggressive_aggression_threshold -> "Aggressive"
        true -> "Balanced"
      end

    title = "#{looseness}-#{aggression}"

    case title do
      "Tight-Aggressive" -> "Tight-Aggressive (TAG)"
      "Loose-Aggressive" -> "Loose-Aggressive (LAG)"
      other -> other
    end
  end

  def graph_color(vpip, aggression_score) do
    looseness = clamp(vpip / 100)
    aggression = clamp(aggression_score / 100)
    top = blend(@tight_aggressive, @loose_aggressive, looseness)
    bottom = blend(@tight_passive, @loose_passive, looseness)
    top |> blend(bottom, 1 - aggression) |> hex_color()
  end

  defp blend({r1, g1, b1}, {r2, g2, b2}, amount) do
    {
      round(r1 + (r2 - r1) * amount),
      round(g1 + (g2 - g1) * amount),
      round(b1 + (b2 - b1) * amount)
    }
  end

  defp hex_color({red, green, blue}) do
    "#" <> hex(red) <> hex(green) <> hex(blue)
  end

  defp hex(value), do: value |> Integer.to_string(16) |> String.pad_leading(2, "0")
  defp clamp(value), do: value |> max(0) |> min(1)
end
