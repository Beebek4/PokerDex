defmodule Zoonk.ProductionSeed do
  @moduledoc "Bootstraps only the public PokerDex school and authored curriculum."

  alias Zoonk.Accounts
  alias Zoonk.Organizations.School
  alias Zoonk.Repo

  def seed do
    ensure_school()

    [List.to_string(:code.priv_dir(:zoonk)), "repo", "seed", "holdem_curriculum.ex"]
    |> Path.join()
    |> Code.require_file()

    apply(Module.concat(["HoldemCurriculumSeed"]), :seed, [])
  end

  defp ensure_school do
    host = System.get_env("PHX_HOST") || System.get_env("RENDER_EXTERNAL_HOSTNAME")

    unless is_binary(host) and host != "" do
      raise "Set PHX_HOST or RENDER_EXTERNAL_HOSTNAME before seeding PokerDex."
    end

    case Repo.get_by(School, slug: "zoonk") do
      nil ->
        {:ok, owner} = Accounts.create_guest_user()

        %School{}
        |> School.create_changeset(%{
          name: "PokerDex",
          slug: "zoonk",
          custom_domain: host,
          email: "noreply@pokerdex.example",
          public?: true,
          allow_guests?: true,
          created_by_id: owner.id
        })
        |> Repo.insert!()

      school ->
        school
        |> School.update_changeset(%{custom_domain: host, public?: true, allow_guests?: true})
        |> Repo.update!()
    end
  end
end
