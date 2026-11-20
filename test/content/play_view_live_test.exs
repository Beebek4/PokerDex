defmodule ZoonkWeb.PlayViewLiveTest do
  use ZoonkWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Zoonk.Fixtures.Content

  alias Zoonk.Accounts
  alias Zoonk.Content
  alias Zoonk.Content.HoldemCurriculum
  alias Zoonk.Content.UserLesson
  alias Zoonk.Content.UserSelection
  alias Zoonk.Repo
  alias Zoonk.Storage

  @select_form "#play"
  @poker_scenario %{
    "scenario_id" => "a-preflop-open",
    "version" => 2,
    "status" => "published",
    "format" => "six_max_cash",
    "table" => %{"seat_count" => 6, "button_seat" => 4, "players_in_hand" => 6},
    "hero" => %{
      "seat" => 2,
      "position" => "cutoff",
      "starting_stack_bb" => 100,
      "remaining_stack_bb" => 100,
      "hole_cards" => ["As", "Kd"]
    },
    "effective_stack_bb" => 100,
    "blinds" => %{"small_blind" => 0.5, "big_blind" => 1, "ante" => 0, "straddle" => 0},
    "street" => "preflop",
    "board" => [],
    "pot" => 1.5,
    "action_history" => [],
    "action_state" => %{
      "amount_to_call_bb" => 1,
      "street_bet_bb" => 1,
      "hero_street_contribution_bb" => 0,
      "contributions_by_seat_bb" => [0.5, 0, 0, 0, 1, 0]
    },
    "legal_actions" => ["fold", "call", "raise"],
    "question" => %{"type" => "choose_action", "prompt" => "What should Hero do?"},
    "assumptions" => ["All players use a 100 big blind effective stack."],
    "skill_tags" => ["preflop.opening"],
    "answer_key" => %{"rationale" => "Open a strong hand from late position."},
    "review" => %{"reviewer" => "Poker reviewer", "approved" => true, "reviewed_at" => "2026-11-17"}
  }

  describe "play view (non-authenticated user)" do
    setup :set_school

    test "redirects to the login page", %{conn: conn, school: school} do
      course = course_fixture(%{school_id: school.id})
      lesson = lesson_fixture(%{course_id: course.id})

      result = get(conn, ~p"/c/#{course.slug}/#{lesson.id}")
      assert redirected_to(result) == "/users/login"
    end
  end

  describe "play view (allow guests)" do
    setup do
      set_school(%{conn: build_conn()}, %{allow_guests?: true})
    end

    test "renders the page", %{conn: conn, school: school} do
      course = course_fixture(%{school_id: school.id})
      lesson = lesson_fixture(%{course_id: course.id})
      generate_steps(lesson)

      conn = get(conn, ~p"/c/#{course.slug}/#{lesson.id}")
      assert redirected_to(conn) == ~p"/c/#{course.slug}/#{lesson.id}"

      {:ok, lv, _html} = live(conn, ~p"/c/#{course.slug}/#{lesson.id}")
      assert has_element?(lv, ~s|blockquote p:fl-icontains("step 1!")|)
    end
  end

  describe "play view (private course, non course user)" do
    setup do
      course_setup(%{conn: build_conn()}, public_course?: false, course_user: nil)
    end

    test "returns 403", %{conn: conn, course: course} do
      assert_403(conn, course)
    end
  end

  describe "play view (private course, pending course user)" do
    setup do
      course_setup(%{conn: build_conn()}, public_course?: false, course_user: :pending)
    end

    test "returns 403", %{conn: conn, course: course} do
      assert_403(conn, course)
    end
  end

  describe "play view (public course, non course user)" do
    setup do
      course_setup(%{conn: build_conn()}, public_course?: true, course_user: nil)
    end

    test "automatically enrolls users", %{conn: conn, course: course, user: user} do
      assert Content.get_course_user_by_id(course.id, user.id) == nil

      lesson = lesson_fixture(%{course_id: course.id})
      generate_steps(lesson)

      {:ok, lv, _html} = live(conn, ~p"/c/#{course.slug}/#{lesson.id}")

      assert Content.get_course_user_by_id(course.id, user.id) != nil

      assert has_element?(lv, "blockquote p", "step 1!")
    end
  end

  describe "play view (course user)" do
    setup :course_setup

    test "completes a lesson", %{conn: conn, course: course} do
      lesson = lesson_fixture(%{course_id: course.id})
      generate_steps(lesson)
      lessons = Content.list_lesson_steps(lesson)

      {:ok, lv, _html} = live(conn, ~p"/c/#{course.slug}/#{lesson.id}")

      # image options
      refute has_element?(lv, ~s|li a span:fl-icontains("Home")|)
      refute has_element?(lv, ~s|img[alt="option 1!"]|)
      assert has_element?(lv, ~s|img[alt="option 2!"]|)

      assert_first_step(lv, lessons)
      assert_second_step(lv, lessons)
      assert_third_step(lv, lessons)
      assert_fourth_step(lv, lessons)
      assert_fifth_step(conn, lv, lessons, course)
    end

    test "returns an error if trying to play a lesson from another course", %{conn: conn, course: course} do
      other_course = course_fixture(%{school_id: course.school_id})
      other_lesson = lesson_fixture(%{course_id: other_course.id})
      generate_steps(other_lesson)

      assert_error_sent 404, fn -> get(conn, ~p"/c/#{course.slug}/#{other_lesson.id}") end
    end

    test "returns an error if trying to play an unpublished lesson", %{conn: conn, course: course} do
      lesson = lesson_fixture(%{course_id: course.id, published?: false})
      generate_steps(lesson)

      assert_error_sent 404, fn -> get(conn, ~p"/c/#{course.slug}/#{lesson.id}") end
    end

    test "doesn't play sound effects when disabled", %{conn: conn, course: course, user: user} do
      Accounts.update_user_settings(user, %{sound_effects?: false})
      lesson = lesson_fixture(%{course_id: course.id})
      generate_steps(lesson)

      {:ok, lv, _html} = live(conn, ~p"/c/#{course.slug}/#{lesson.id}")

      refute has_element?(lv, ~s|form[phx-hook="LessonSoundEffect"]|)
    end

    test "plays sound effects when enabled", %{conn: conn, course: course, user: user} do
      Accounts.update_user_settings(user, %{sound_effects?: true})
      lesson = lesson_fixture(%{course_id: course.id})
      generate_steps(lesson)

      {:ok, lv, _html} = live(conn, ~p"/c/#{course.slug}/#{lesson.id}")

      assert has_element?(lv, ~s|form[phx-hook="LessonSoundEffect"]|)
    end

    test "embeds youtube videos when available", %{conn: conn, course: course} do
      lesson = lesson_fixture(%{course_id: course.id})
      lesson_step_fixture(%{lesson_id: lesson.id, content: "watch the video: https://www.youtube.com/watch?v=12345678901"})

      {:ok, lv, _html} = live(conn, ~p"/c/#{course.slug}/#{lesson.id}")

      assert has_element?(lv, "p", "watch the video:")
      refute has_element?(lv, "p", "https://www.youtube.com/watch?v=12345678901")
      assert has_element?(lv, "iframe[src='https://www.youtube-nocookie.com/embed/12345678901']")
    end

    test "displays suggested courses when available", %{conn: conn, school: school, course: course1} do
      course2 = course_fixture(%{school_id: school.id})
      course3 = course_fixture(%{school_id: school.id})

      lesson = lesson_fixture(%{course_id: course1.id})
      step = lesson_step_fixture(%{lesson_id: lesson.id})

      Content.add_step_suggested_course(%{lesson_step_id: step.id, course_id: course2.id})
      Content.add_step_suggested_course(%{lesson_step_id: step.id, course_id: course3.id})

      {:ok, lv, _html} = live(conn, ~p"/c/#{course1.slug}/#{lesson.id}")

      assert has_element?(lv, "a", course2.name)
      assert has_element?(lv, "a", course3.name)
    end

    test "answers an open-ended question", %{conn: conn, course: course, user: user} do
      lesson = lesson_fixture(%{course_id: course.id})
      step = lesson_step_fixture(%{lesson_id: lesson.id, content: "question?", kind: :open_ended, order: 1})
      lesson_step_fixture(%{lesson_id: lesson.id, content: "step 2 question", kind: :readonly, order: 2})

      refute Repo.get_by(UserSelection, user_id: user.id, step_id: step.id)

      {:ok, lv, _html} = live(conn, ~p"/c/#{course.slug}/#{lesson.id}")

      assert has_element?(lv, "blockquote p", "question?")
      refute has_element?(lv, "blockquote p", "step 2 question")

      lv |> form(@select_form, %{answer: "answer!"}) |> render_submit()

      assert has_element?(lv, "blockquote p", "step 2 question")
      assert Repo.get_by(UserSelection, user_id: user.id, step_id: step.id).answer == ["answer!"]
    end

    test "saves the rubric score and scenario snapshot with a poker answer", %{conn: conn, course: course, user: user} do
      lesson = lesson_fixture(%{course_id: course.id})

      step =
        lesson_step_fixture(%{
          lesson_id: lesson.id,
          content: "What should Hero do?",
          kind: :quiz,
          order: 1,
          poker_scenario: @poker_scenario
        })

      option =
        step_option_fixture(%{
          lesson_step_id: step.id,
          title: "Raise",
          correct?: true,
          score: 70,
          score_label: "Reasonable"
        })

      step_option_fixture(%{lesson_step_id: step.id, title: "Fold", correct?: false, score: 30, score_label: "Questionable"})
      step_option_fixture(%{lesson_step_id: step.id, title: "Call", correct?: false, score: 30, score_label: "Questionable"})

      {:ok, lv, _html} = live(conn, ~p"/c/#{course.slug}/#{lesson.id}")
      lv |> form(@select_form, %{selected_option: option.id}) |> render_submit()

      assert has_element?(lv, "h3", "Reasonable alternative")
      assert has_element?(lv, "span", "Reasonable · 70/100")
      assert has_element?(lv, "summary", "See the other choices")
      assert has_element?(lv, "p", "Evidence and takeaway")

      selection = Repo.get_by!(UserSelection, user_id: user.id, step_id: step.id)

      assert selection.score == 70
      assert selection.scenario_version == 2
      assert selection.scenario_snapshot == @poker_scenario
      assert selection.correct == 1
    end

    test "puzzle choices answer immediately and continue endlessly without lesson completion", %{conn: conn, course: course, user: user} do
      puzzle_course = course_fixture(%{school_id: course.school_id, slug: "holdem-puzzles-preflop"})
      first_lesson = lesson_fixture(%{course_id: puzzle_course.id, order: 1})
      second_lesson = lesson_fixture(%{course_id: puzzle_course.id, order: 2})

      first_step =
        lesson_step_fixture(%{
          lesson_id: first_lesson.id,
          order: 1,
          content: "Puzzle one?",
          poker_scenario: put_in(@poker_scenario, ["question", "prompt"], "Puzzle one?")
        })

      second_step =
        lesson_step_fixture(%{
          lesson_id: second_lesson.id,
          order: 1,
          content: "Puzzle two?",
          poker_scenario: put_in(@poker_scenario, ["question", "prompt"], "Puzzle two?")
        })

      for step <- [first_step, second_step] do
        step_option_fixture(%{lesson_step_id: step.id, title: "Fold", correct?: false, score: 30, score_label: "Review"})
        step_option_fixture(%{lesson_step_id: step.id, title: "Call", correct?: false, score: 70, score_label: "Reasonable"})
        step_option_fixture(%{lesson_step_id: step.id, title: "Raise", correct?: true, score: 100, score_label: "Strong"})
      end

      {:ok, lv, _html} = live(conn, ~p"/c/#{puzzle_course.slug}/#{first_lesson.id}")

      refute has_element?(lv, "header .bg-teal-400")
      refute has_element?(lv, "input[type='radio']")
      refute has_element?(lv, "h1", "Lesson complete")
      assert has_element?(lv, "button[phx-click='choose-option']")

      initial_step_id = lv |> render() |> then(&Regex.run(~r/name="step_id" value="(\d+)"/, &1)) |> Enum.at(1) |> String.to_integer()

      lv
      |> element("button[phx-click='choose-option']", "Raise")
      |> render_click()

      assert has_element?(lv, "div[role='alert'] h3", "Strong choice")
      assert has_element?(lv, "button[phx-click='next-puzzle']", "Next puzzle")

      selection = Repo.get_by!(UserSelection, user_id: user.id, step_id: initial_step_id)
      assert selection.acknowledged?

      lv |> element("button[phx-click='next-puzzle']") |> render_click()

      next_step_id = lv |> render() |> then(&Regex.run(~r/name="step_id" value="(\d+)"/, &1)) |> Enum.at(1) |> String.to_integer()
      assert next_step_id != initial_step_id
      assert has_element?(lv, "button[phx-click='choose-option']")
      refute has_element?(lv, "h1", "Lesson complete")
      refute Repo.get_by(UserLesson, user_id: user.id, lesson_id: first_lesson.id)
      refute Repo.get_by(UserLesson, user_id: user.id, lesson_id: second_lesson.id)
    end

    test "shows the structured hand context before the learner chooses", %{conn: conn, course: course} do
      lesson = lesson_fixture(%{course_id: course.id})

      step =
        lesson_step_fixture(%{
          lesson_id: lesson.id,
          content: "Question prompt",
          kind: :quiz,
          order: 1,
          poker_scenario: @poker_scenario
        })

      step_option_fixture(%{lesson_step_id: step.id, title: "Fold", score: 30, score_label: "Questionable", correct?: false})
      step_option_fixture(%{lesson_step_id: step.id, title: "Call", score: 70, score_label: "Reasonable", correct?: true})
      step_option_fixture(%{lesson_step_id: step.id, title: "Raise", score: 100, score_label: "Strong", correct?: true})

      {:ok, lv, _html} = live(conn, ~p"/c/#{course.slug}/#{lesson.id}")

      assert has_element?(lv, "section[aria-label='Poker scenario']")
      assert has_element?(lv, "h2", "What should Hero do?")
      assert has_element?(lv, "p", "Cutoff")
      refute has_element?(lv, "p", "No cards dealt yet")
      assert has_element?(lv, "img[src='/images/poker/pokertable-removebg-preview.png']")
      assert has_element?(lv, "span[aria-label='Ace of spades']")
      assert has_element?(lv, "span[aria-label='King of diamonds']")
      assert has_element?(lv, "img[src='/images/poker/suits/spade.png']")
      assert has_element?(lv, "img[src='/images/poker/suits/diamond.png']")
      assert has_element?(lv, "label", "Raise")
      refute has_element?(lv, "section[aria-label='Poker scenario']", "River")
    end

    test "renders the community board as illustrated, color-coded cards", %{conn: conn, course: course} do
      question =
        HoldemCurriculum.tracks()
        |> Enum.flat_map(& &1.lessons)
        |> Enum.flat_map(& &1.questions)
        |> Enum.find(&(&1.poker_scenario["street"] == "flop" and length(&1.poker_scenario["board"]) == 3))

      lesson = lesson_fixture(%{course_id: course.id})
      step = lesson_step_fixture(%{lesson_id: lesson.id, content: question.content, poker_scenario: question.poker_scenario})
      Enum.each(question.options, &step_option_fixture(Map.put(&1, :lesson_step_id, step.id)))

      {:ok, lv, _html} = live(conn, ~p"/c/#{course.slug}/#{lesson.id}")

      board_cards = Enum.map_join(question.poker_scenario["board"], ", ", &card_accessible/1)
      hero_cards = Enum.map_join(question.poker_scenario["hero"]["hole_cards"], ", ", &card_accessible/1)

      assert has_element?(lv, "img[src='/images/poker/pokertable-removebg-preview.png']")
      assert has_element?(lv, "img[src='/images/poker/suits/club.png']")
      assert has_element?(lv, "span[role='img'][aria-label='#{card_accessible(Enum.at(question.poker_scenario["board"], 0))}']")
      assert has_element?(lv, "div[role='group'][aria-label='Community cards: #{board_cards}']")
      position = question.poker_scenario["hero"]["position"] |> String.replace("_", " ") |> String.capitalize()
      hero_label = "Hero · #{position} · #{hero_cards}"
      assert has_element?(lv, "div[role='group'][aria-label='#{hero_label}']")
    end

    test "restores unacknowledged feedback after refresh and then resumes the lesson", %{conn: conn, course: course, user: user} do
      lesson = lesson_fixture(%{course_id: course.id})
      first_step = lesson_step_fixture(%{lesson_id: lesson.id, content: "Saved question", order: 1})
      option = step_option_fixture(%{lesson_step_id: first_step.id, correct?: true, title: "Answer"})
      lesson_step_fixture(%{lesson_id: lesson.id, content: "Next question", kind: :readonly, order: 2})

      {:ok, lv, _html} = live(conn, ~p"/c/#{course.slug}/#{lesson.id}")
      lv |> form(@select_form, %{selected_option: option.id}) |> render_submit()

      assert Repo.get_by(UserSelection, user_id: user.id, step_id: first_step.id)

      {:ok, feedback_resumed_lv, _html} = live(conn, ~p"/c/#{course.slug}/#{lesson.id}")
      assert has_element?(feedback_resumed_lv, "blockquote p", "Saved question")
      assert has_element?(feedback_resumed_lv, "h3", "Well done!")

      feedback_resumed_lv |> form(@select_form) |> render_submit()

      assert has_element?(feedback_resumed_lv, "blockquote p", "Next question")

      render_submit(feedback_resumed_lv, "next", %{"step_id" => to_string(first_step.id), "selected_option" => to_string(option.id)})

      assert has_element?(feedback_resumed_lv, "blockquote p", "Next question")

      {:ok, resumed_lv, _html} = live(conn, ~p"/c/#{course.slug}/#{lesson.id}")
      assert has_element?(resumed_lv, "blockquote p", "Next question")
    end

    test "displays a 10 score when the lesson has only one readonly step", %{conn: conn, course: course} do
      lesson = lesson_fixture(%{course_id: course.id})
      lesson_step_fixture(%{lesson_id: lesson.id, content: "read only step", kind: :readonly})

      {:ok, lv, _html} = live(conn, ~p"/c/#{course.slug}/#{lesson.id}")

      assert has_element?(lv, "blockquote p", "read only step")
      lv |> form(@select_form) |> render_submit()
      assert_redirected(lv, ~p"/c/#{course.slug}/#{lesson.id}/completed")

      {:ok, view, _html} = live(conn, ~p"/c/#{course.slug}/#{lesson.id}/completed")

      assert has_element?(view, "h1", "Perfect!")
      assert has_element?(view, "span", "10.0")
      assert has_element?(view, "p", "You got all the answers correct!")
    end
  end

  defp assert_403(conn, course) do
    lesson = lesson_fixture(%{course_id: course.id})
    assert_error_sent 403, fn -> get(conn, ~p"/c/#{course.slug}/#{lesson.id}") end
  end

  defp card_accessible(<<rank::binary-size(1), suit::binary-size(1)>>) do
    rank_name =
      %{
        "2" => "Two",
        "3" => "Three",
        "4" => "Four",
        "5" => "Five",
        "6" => "Six",
        "7" => "Seven",
        "8" => "Eight",
        "9" => "Nine",
        "T" => "Ten",
        "J" => "Jack",
        "Q" => "Queen",
        "K" => "King",
        "A" => "Ace"
      }[rank] || rank

    suit_name = %{"s" => "spades", "h" => "hearts", "d" => "diamonds", "c" => "clubs"}[suit]
    "#{rank_name} of #{suit_name}"
  end

  defp assert_first_step(lv, lessons) do
    assert has_element?(lv, ~s|blockquote p:fl-icontains("step 1!")|)
    assert has_element?(lv, ~s|button *:fl-icontains("confirm")|)

    step = hd(lessons)
    first_option = hd(step.options)

    assert has_element?(lv, ~s|input[id="select-option-#{first_option.id}"]|)
    refute has_element?(lv, "textarea")

    lv |> form(@select_form, %{selected_option: get_incorrect_option(step.options)}) |> render_submit()

    assert has_element?(lv, ~s|div[role="alert"] h4:fl-icontains("feedback 2!")|)
  end

  defp assert_second_step(lv, lessons) do
    lv |> form(@select_form) |> render_submit()

    refute has_element?(lv, ~s|blockquote p:fl-icontains("step 1!")|)
    assert has_element?(lv, ~s|blockquote p:fl-icontains("step 2!")|)

    step = Enum.at(lessons, 1)
    file_url = Storage.get_url(step.image)

    assert has_element?(lv, ~s|img[src="#{file_url}"]|)
  end

  # credo:disable-for-next-line Credo.Check.Refactor.ABCSize
  defp assert_third_step(lv, lessons) do
    lv |> form(@select_form) |> render_submit()

    refute has_element?(lv, ~s|blockquote p:fl-icontains("step 1!")|)
    refute has_element?(lv, ~s|blockquote p:fl-icontains("step 2!")|)
    assert has_element?(lv, ~s|blockquote p:fl-icontains("step 3!")|)
    assert has_element?(lv, ~s|button *:fl-icontains("confirm")|)

    step = Enum.at(lessons, 2)
    first_option = hd(step.options)

    assert has_element?(lv, ~s|input[id="select-option-#{first_option.id}"]|)

    lv |> form(@select_form, %{selected_option: get_incorrect_option(step.options)}) |> render_submit()

    assert has_element?(lv, ~s|div[role="alert"] h4:fl-icontains("feedback 2!")|)
  end

  # credo:disable-for-next-line Credo.Check.Refactor.ABCSize
  defp assert_fourth_step(lv, lessons) do
    lv |> form(@select_form) |> render_submit()

    refute has_element?(lv, ~s|blockquote p:fl-icontains("step 1!")|)
    refute has_element?(lv, ~s|blockquote p:fl-icontains("step 2!")|)
    refute has_element?(lv, ~s|blockquote p:fl-icontains("step 3!")|)
    assert has_element?(lv, ~s|blockquote p:fl-icontains("step 4!")|)
    assert has_element?(lv, ~s|button *:fl-icontains("confirm")|)

    step = Enum.at(lessons, 3)
    first_option = hd(step.options)

    assert has_element?(lv, ~s|input[id="select-option-#{first_option.id}"]|)

    lv |> form(@select_form, %{selected_option: get_correct_option(step.options)}) |> render_submit()

    assert has_element?(lv, ~s|div[role="alert"] h3:fl-icontains("well done!")|)
  end

  defp assert_fifth_step(conn, lv, lessons, course) do
    lv |> form(@select_form) |> render_submit()

    assert has_element?(lv, ~s|blockquote p:fl-icontains("step 5!")|)
    assert has_element?(lv, ~s|button *:fl-icontains("next step")|)

    step = Enum.at(lessons, 4)

    assert {:ok, updated_lv, _html} =
             lv
             |> form(@select_form)
             |> render_submit()
             |> follow_redirect(conn, ~p"/c/#{course.slug}/#{step.lesson_id}/completed")

    assert has_element?(updated_lv, "h1", "Not bad!")
    assert has_element?(updated_lv, "span", "6.0")
    assert has_element?(updated_lv, "p", "You got 3 out of 5 answers right.")
  end

  defp generate_steps(lesson) do
    Enum.each(1..5, fn order ->
      content = "step #{order}!"
      image = if order == 2, do: "img.png"
      kind = if order == 5, do: :readonly, else: :quiz

      step = lesson_step_fixture(%{lesson_id: lesson.id, kind: kind, content: content, image: image, order: order})

      # Make sure it works even when the last step doesn't have options.
      unless order == 5, do: generate_options(step, order)
    end)
  end

  defp generate_options(_step, 2), do: nil

  defp generate_options(step, _step_order) do
    Enum.each(1..5, fn order ->
      image = if order == 2, do: "img.png"
      feedback = unless order == 4, do: "feedback #{order}!"
      correct? = order == 1 or order == 4

      step_option_fixture(%{lesson_step_id: step.id, correct?: correct?, image: image, feedback: feedback, title: "option #{order}!"})
    end)
  end

  defp get_correct_option(options), do: Enum.find(options, fn option -> option.correct? end).id
  defp get_incorrect_option(options), do: Enum.find(options, fn option -> not option.correct? end).id
end
