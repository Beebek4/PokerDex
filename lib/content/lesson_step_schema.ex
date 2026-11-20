defmodule Zoonk.Content.LessonStep do
  @moduledoc """
  LessonStep schema.
  """
  use Ecto.Schema

  import Ecto.Changeset

  alias Zoonk.Content.CourseUtils
  alias Zoonk.Content.Lesson
  alias Zoonk.Content.PokerRules
  alias Zoonk.Content.PokerScenario
  alias Zoonk.Content.StepOption
  alias Zoonk.Content.StepSuggestedCourse

  @type t :: %__MODULE__{}

  schema "lesson_steps" do
    field :content, :string
    field :image, :string
    field :kind, Ecto.Enum, values: [:readonly, :quiz, :open_ended], default: :readonly
    field :order, :integer
    field :poker_scenario, :map

    belongs_to :lesson, Lesson
    has_many :options, StepOption
    has_many :suggested_courses, StepSuggestedCourse

    timestamps(type: :utc_datetime_usec)
  end

  @doc false
  @spec changeset(Ecto.Schema.t(), map()) :: Ecto.Changeset.t()
  def changeset(lesson_step, attrs) do
    lesson_step
    |> cast(attrs, [:content, :image, :kind, :lesson_id, :order, :poker_scenario])
    |> validate_required([:content, :kind, :lesson_id, :order])
    |> validate_length(:content, max: CourseUtils.max_length(:step_content))
    |> validate_poker_scenario()
  end

  defp validate_poker_scenario(changeset) do
    case get_field(changeset, :poker_scenario) do
      nil ->
        changeset

      scenario ->
        errors = PokerScenario.validate(scenario) ++ PokerRules.validate_scenario(scenario)

        Enum.reduce(errors, changeset, fn message, changeset ->
          add_error(changeset, :poker_scenario, message)
        end)
    end
  end
end
