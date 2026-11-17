{:ok, _} = Application.ensure_all_started(:ecto_sql)
{:ok, _} = Application.ensure_all_started(:postgrex)
{:ok, _repo_pid} = Zoonk.Repo.start_link()

Code.require_file("priv/repo/seed/users.ex")
Code.require_file("priv/repo/seed/schools.ex")
Code.require_file("priv/repo/seed/holdem_curriculum.ex")

UserSeed.seed()
SchoolSeed.seed()
HoldemCurriculumSeed.seed()
