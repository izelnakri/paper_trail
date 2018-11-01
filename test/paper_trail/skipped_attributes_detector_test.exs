defmodule PaperTrailTest.SkippedAttributesDetector do
  use ExUnit.Case

  alias PaperTrail.SkippedAttributesDetector
  alias SimpleCompany, as: Company
  alias SimplePerson, as: Person

  test "call/1 returns list with skipped attrs for Company module" do
    assert SkippedAttributesDetector.call(Company) == [:twitter]
  end

  test "call/1 returns empty list for Person module" do
    assert SkippedAttributesDetector.call(Person) == []
  end

  test "call/1 raises FunctionClauseError for empty Map" do
    assert_raise FunctionClauseError, fn ->
      SkippedAttributesDetector.call(%{})
    end
  end

  test "call/1 raises ArgumentError when result of 'paper_trail_skip' is not a list" do
    defmodule TestPaperTrailSkip do
      def paper_trail_skip, do: "not a list"
    end

    assert_raise ArgumentError, fn ->
      SkippedAttributesDetector.call(TestPaperTrailSkip)
    end
  end
end
