defmodule Zoonk.Content.StepOption do
  @moduledoc """
  StepOption schema.
  """
  use Ecto.Schema

  import Ecto.Changeset

  alias Zoonk.Content.CourseUtils
  alias Zoonk.Content.LessonStep
  alias Zoonk.Content.UserSelection

  @type t :: %__MODULE__{}

  schema "step_options" do
    field :correct?, :boolean, default: false
    field :feedback, :string
    field :image, :string
    field :score, :integer
    field :score_label, :string
    field :title, :string

    belongs_to :lesson_step, LessonStep
    has_many :user_selections, UserSelection, foreign_key: :option_id

    timestamps(type: :utc_datetime_usec)
  end

  @doc false
  @spec changeset(Ecto.Schema.t(), map()) :: Ecto.Changeset.t()
  def changeset(step_option, attrs) do
    step_option
    |> cast(attrs, [:correct?, :feedback, :image, :score, :score_label, :title, :lesson_step_id])
    |> validate_required([:correct?, :title, :lesson_step_id])
    |> validate_length(:feedback, max: CourseUtils.max_length(:option_feedback))
    |> validate_length(:title, max: CourseUtils.max_length(:option_title))
    |> validate_score()
  end

  defp validate_score(changeset) do
    score = get_field(changeset, :score)
    score_label = get_field(changeset, :score_label)

    changeset =
      if is_nil(score) do
        changeset
      else
        validate_number(changeset, :score, greater_than_or_equal_to: 0, less_than_or_equal_to: 100)
      end

    cond do
      not is_nil(score) and (not is_binary(score_label) or String.trim(score_label) == "") ->
        add_error(changeset, :score_label, "can't be blank when a score is set")

      is_nil(score) and not is_nil(score_label) ->
        add_error(changeset, :score, "can't be blank when a score label is set")

      true ->
        changeset
    end
  end
end
