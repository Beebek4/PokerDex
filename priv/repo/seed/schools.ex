defmodule SchoolSeed do
  @moduledoc false

  alias Zoonk.Accounts
  alias Zoonk.Organizations
  alias Zoonk.Organizations.School
  alias Zoonk.Organizations.SchoolUser
  alias Zoonk.Repo

  @app %{
    name: "PokerDex",
    custom_domain: "zoonk.test",
    email: "noreply@pokerdex.example",
    public?: true,
    allow_guests?: true,
    slug: "zoonk",
    manager: "pokerdex-admin"
  }

  @doc "Creates the local PokerDex school and its manager membership if they are missing."
  def seed do
    manager = Accounts.get_user_by_username(@app.manager)
    attrs = Map.merge(Map.delete(@app, :manager), %{created_by_id: manager.id})

    school =
      case Repo.get_by(School, slug: @app.slug) do
        nil ->
          case Organizations.create_school(attrs) do
            {:ok, school} -> school
            {:error, changeset} -> raise "Could not seed PokerDex: #{inspect(changeset.errors)}"
          end

        %School{allow_guests?: false} = school ->
          case Organizations.update_school(school, %{allow_guests?: true}) do
            {:ok, school} ->
              school

            {:error, changeset} ->
              raise "Could not enable guest learning: #{inspect(changeset.errors)}"
          end

        school ->
          school
      end

    if is_nil(Repo.get_by(SchoolUser, school_id: school.id, user_id: manager.id)) do
      Organizations.create_school_user(school, manager, %{
        role: :manager,
        approved?: true,
        approved_by_id: manager.id,
        approved_at: DateTime.utc_now()
      })
    end

    school
  end
end
