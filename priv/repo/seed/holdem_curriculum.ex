defmodule HoldemCurriculumSeed do
  @moduledoc false

  alias Zoonk.Content.Course
  alias Zoonk.Content.HoldemCurriculum
  alias Zoonk.Content.Lesson
  alias Zoonk.Content.LessonStep
  alias Zoonk.Content.StepOption
  alias Zoonk.Organizations.School
  alias Zoonk.Repo

  def seed do
    school = Repo.get_by!(School, slug: "zoonk")
    retire_legacy_theory_courses(school)

    Enum.each(HoldemCurriculum.all_tracks(), fn track ->
      course = ensure_course(track, school)

      track.lessons
      |> Enum.with_index(1)
      |> Enum.each(fn {lesson_data, order} ->
        lesson = ensure_lesson(lesson_data, course, order)
        seed_steps(lesson_data, lesson)
      end)
    end)
  end

  defp retire_legacy_theory_courses(school) do
    old_streets = ~w(preflop flop turn river showdown)
    old_stages = ~w(fundamentals competency deep-dive mastery)

    legacy_slugs =
      ["holdem-theory-fundamentals"] ++
        old_streets ++
        for street <- old_streets, stage <- old_stages, do: "theory-#{street}-#{stage}"

    legacy_slugs
    |> Enum.each(fn slug ->
      case Repo.get_by(Course, slug: slug, school_id: school.id) do
        nil ->
          :ok

        course ->
          course
          |> Course.changeset(%{public?: false, published?: false})
          |> Repo.update!()
      end
    end)
  end

  defp ensure_course(track, school) do
    attrs = %{
      name: track.name,
      slug: track.slug,
      description: track.description,
      curriculum_stage: Map.get(track, :curriculum_stage),
      curriculum_street: Map.get(track, :curriculum_street),
      language: :en,
      level: track.level,
      public?: true,
      published?: true,
      school_id: school.id
    }

    case Repo.get_by(Course, slug: track.slug, school_id: school.id) do
      nil ->
        %Course{} |> Course.changeset(attrs) |> Repo.insert!()

      course ->
        course |> Course.changeset(attrs) |> Repo.update!()
    end
  end

  defp ensure_lesson(lesson_data, course, order) do
    attrs = %{
      course_id: course.id,
      name: lesson_data.name,
      description: lesson_data.description,
      difficulty: Map.get(lesson_data, :difficulty, :beginner),
      order: order,
      published?: true
    }

    case Repo.get_by(Lesson, course_id: course.id, order: order) do
      nil ->
        %Lesson{}
        |> Lesson.changeset(attrs)
        |> Repo.insert!()

      lesson when lesson.difficulty == attrs.difficulty ->
        lesson

      lesson ->
        lesson
        |> Lesson.changeset(%{difficulty: attrs.difficulty})
        |> Repo.update!()
    end
  end

  defp seed_steps(lesson_data, lesson) do
    lesson_data
    |> HoldemCurriculum.lesson_with_steps()
    |> Map.fetch!(:steps)
    |> Enum.with_index(1)
    |> Enum.each(fn {step_data, order} ->
      sync_puzzle? = Map.get(lesson_data, :puzzle_only?, false)
      step = ensure_step(step_data, lesson, order, sync_puzzle?)
      seed_options(step_data, step, sync_puzzle?)
    end)
  end

  defp ensure_step(step_data, lesson, order, sync_puzzle?) do
    attrs = %{
      lesson_id: lesson.id,
      content: step_data.content,
      kind: step_data.kind,
      order: order,
      poker_scenario: Map.get(step_data, :poker_scenario)
    }

    case Repo.get_by(LessonStep, lesson_id: lesson.id, order: order) do
      nil ->
        %LessonStep{} |> LessonStep.changeset(attrs) |> Repo.insert!()

      step when sync_puzzle? ->
        changeset = LessonStep.changeset(step, Map.take(attrs, [:content, :poker_scenario]))
        if changeset.changes == %{}, do: step, else: Repo.update!(changeset)

      step ->
        step
    end
  end

  defp seed_options(%{options: options}, step, true) do
    Enum.each(options, fn option ->
      attrs = Map.put(option, :lesson_step_id, step.id)

      case Repo.get_by(StepOption, lesson_step_id: step.id, title: option.title) do
        nil ->
          %StepOption{} |> StepOption.changeset(attrs) |> Repo.insert!()

        existing ->
          changeset = StepOption.changeset(existing, Map.delete(attrs, :lesson_step_id))
          if changeset.changes == %{}, do: existing, else: Repo.update!(changeset)
      end
    end)
  end

  defp seed_options(%{options: options}, step, false) do
    Enum.each(options, fn option ->
      if is_nil(Repo.get_by(StepOption, lesson_step_id: step.id, title: option.title)) do
        %StepOption{}
        |> StepOption.changeset(Map.put(option, :lesson_step_id, step.id))
        |> Repo.insert!()
      end
    end)
  end

  defp seed_options(_step_data, _step, _sync_puzzle?), do: :ok
end
