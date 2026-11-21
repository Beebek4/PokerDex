defmodule Zoonk.Release do
  @moduledoc """
  Used for executing DB release tasks when run in production without Mix
  installed.
  """
  @app :zoonk

  def migrate do
    load_app()
    use_direct_database_url()

    for repo <- repos() do
      {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :up, all: true))
    end
  end

  def seed do
    load_app()

    {:ok, result, _repo_pid} =
      Ecto.Migrator.with_repo(Zoonk.Repo, fn _repo ->
        Zoonk.ProductionSeed.seed()
      end)

    result
  end

  def rollback(repo, version) do
    load_app()
    {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :down, to: version))
  end

  defp repos do
    Application.fetch_env!(@app, :ecto_repos)
  end

  defp load_app do
    Application.load(@app)
  end

  defp use_direct_database_url do
    case System.get_env("DATABASE_URL_UNPOOLED") do
      url when is_binary(url) and url != "" ->
        config = Application.fetch_env!(@app, Zoonk.Repo)
        Application.put_env(@app, Zoonk.Repo, Keyword.put(config, :url, url))

      _ ->
        :ok
    end
  end
end
