defmodule UserSeed do
  @moduledoc false

  alias Zoonk.Accounts

  @admin %{
    first_name: "PokerDex",
    last_name: "Admin",
    email: "admin@pokerdex.example",
    username: "pokerdex-admin",
    language: :en,
    password: "Demo1234"
  }

  @doc "Creates the local PokerDex manager account if it does not already exist."
  def seed do
    user_exists? =
      Accounts.get_user_by_email(@admin.email) || Accounts.get_user_by_username(@admin.username)

    if is_nil(user_exists?) do
      case Accounts.register_user(@admin) do
        {:ok, _user} ->
          :ok

        {:error, changeset} ->
          raise "Could not seed PokerDex manager: #{inspect(changeset.errors)}"
      end
    end
  end
end
