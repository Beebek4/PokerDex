defmodule ZoonkWeb.Plugs.DailyReward do
  @moduledoc false

  import Phoenix.Component, only: [assign: 3]

  alias Zoonk.Poker.Campaigns

  @weekdays ~w(S M T W T F S)

  def on_mount(:claim_daily_reward, params, _session, %{assigns: %{current_user: %{id: user_id}}} = socket) do
    {:ok, reward} = Campaigns.claim_daily_reward(user_id)
    preview_all? = Application.get_env(:zoonk, :play_preview_all_opponents, false) and params["preview"] == "all"

    socket =
      socket
      |> assign(:daily_reward, reward)
      |> assign(:daily_streak, reward.day_streak)
      |> assign(:daily_streak_calendar, streak_calendar(reward.day_streak, reward.claim_date))
      |> assign(:show_daily_reward?, reward.awarded? or preview_all?)

    {:cont, socket}
  end

  defp streak_calendar(streak, today) do
    sunday = Date.add(today, -rem(Date.day_of_week(today), 7))

    Enum.map(0..6, fn days_after_sunday ->
      date = Date.add(sunday, days_after_sunday)
      days_ago = Date.diff(today, date)

      %{
        weekday: Enum.at(@weekdays, days_after_sunday),
        day: date.day,
        checked?: days_ago >= 0 and days_ago < streak,
        today?: days_ago == 0
      }
    end)
  end
end
