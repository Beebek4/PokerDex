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

    Enum.each(HoldemCurriculum.tracks(), fn track ->
      course = ensure_course(track, school)

      track.lessons
      |> Enum.with_index(1)
      |> Enum.each(fn {lesson_data, order} ->
        lesson = ensure_lesson(lesson_data, course, order)
        seed_steps(lesson_data, lesson)
      end)
    end)
  end

  defp ensure_course(track, school) do
    Repo.get_by(Course, slug: track.slug, school_id: school.id) ||
      %Course{}
      |> Course.changeset(%{
        name: track.name,
        slug: track.slug,
        description: track.description,
        language: :en,
        level: track.level,
        public?: true,
        published?: true,
        school_id: school.id
      })
      |> Repo.insert!()
  end

  defp ensure_lesson(lesson_data, course, order) do
    Repo.get_by(Lesson, course_id: course.id, order: order) ||
      %Lesson{}
      |> Lesson.changeset(%{
        course_id: course.id,
        name: lesson_data.name,
        description: lesson_data.description,
        order: order,
        published?: true
      })
      |> Repo.insert!()
  end

  defp seed_steps(lesson_data, lesson) do
    lesson_data
    |> HoldemCurriculum.lesson_with_steps()
    |> Map.fetch!(:steps)
    |> Enum.with_index(1)
    |> Enum.each(fn {step_data, order} ->
      step = ensure_step(step_data, lesson, order)
      seed_options(step_data, step)
    end)
  end

  defp ensure_step(step_data, lesson, order) do
    Repo.get_by(LessonStep, lesson_id: lesson.id, order: order) ||
      %LessonStep{}
      |> LessonStep.changeset(%{
        lesson_id: lesson.id,
        content: step_data.content,
        kind: step_data.kind,
        order: order,
        poker_scenario: Map.get(step_data, :poker_scenario)
      })
      |> Repo.insert!()
  end

  defp seed_options(%{options: options}, step) do
    Enum.each(options, fn option ->
      if is_nil(Repo.get_by(StepOption, lesson_step_id: step.id, title: option.title)) do
        %StepOption{}
        |> StepOption.changeset(Map.put(option, :lesson_step_id, step.id))
        |> Repo.insert!()
      end
    end)
  end

  defp seed_options(_step_data, _step), do: :ok
end
