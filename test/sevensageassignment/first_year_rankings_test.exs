defmodule Sevensageassignment.FirstYearRankingsTest do
  use Sevensageassignment.DataCase

  alias Sevensageassignment.FirstYearRankings

  describe "first_year_rankings" do
    alias Sevensageassignment.FirstYearRankings.FirstYearRanking

    import Sevensageassignment.FirstYearRankingsFixtures

    @invalid_attrs %{
      rank: nil,
      school: nil,
      first_year_class: nil,
      l75: nil,
      l50: nil,
      l25: nil,
      g75: nil,
      g50: nil,
      g25: nil,
      gre75v: nil,
      gre50v: nil,
      gre25v: nil,
      gre75q: nil,
      gre50q: nil,
      gre25q: nil,
      gre75w: nil,
      gre50w: nil
    }

    test "list_first_year_rankings/0 returns all first_year_rankings" do
      first_year_ranking = first_year_ranking_fixture()
      assert FirstYearRankings.list_first_year_rankings() == [first_year_ranking]
    end

    test "get_first_year_ranking!/1 returns the first_year_ranking with given id" do
      first_year_ranking = first_year_ranking_fixture()

      assert FirstYearRankings.get_first_year_ranking!(first_year_ranking.id) ==
               first_year_ranking
    end

    test "create_first_year_ranking/1 with valid data creates a first_year_ranking" do
      valid_attrs = %{
        rank: 42,
        school: "some school",
        first_year_class: 42,
        l75: 42,
        l50: 42,
        l25: 42,
        g75: "120.5",
        g50: "120.5",
        g25: "120.5",
        gre75v: 42,
        gre50v: 42,
        gre25v: 42,
        gre75q: 42,
        gre50q: 42,
        gre25q: 42,
        gre75w: "120.5",
        gre50w: "120.5"
      }

      assert {:ok, %FirstYearRanking{} = first_year_ranking} =
               FirstYearRankings.create_first_year_ranking(valid_attrs)

      assert first_year_ranking.rank == 42
      assert first_year_ranking.school == "some school"
      assert first_year_ranking.first_year_class == 42
      assert first_year_ranking.l75 == 42
      assert first_year_ranking.l50 == 42
      assert first_year_ranking.l25 == 42
      assert first_year_ranking.g75 == Decimal.new("120.5")
      assert first_year_ranking.g50 == Decimal.new("120.5")
      assert first_year_ranking.g25 == Decimal.new("120.5")
      assert first_year_ranking.gre75v == 42
      assert first_year_ranking.gre50v == 42
      assert first_year_ranking.gre25v == 42
      assert first_year_ranking.gre75q == 42
      assert first_year_ranking.gre50q == 42
      assert first_year_ranking.gre25q == 42
      assert first_year_ranking.gre75w == Decimal.new("120.5")
      assert first_year_ranking.gre50w == Decimal.new("120.5")
    end

    test "create_first_year_ranking/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} =
               FirstYearRankings.create_first_year_ranking(@invalid_attrs)
    end

    test "update_first_year_ranking/2 with valid data updates the first_year_ranking" do
      first_year_ranking = first_year_ranking_fixture()

      update_attrs = %{
        rank: 43,
        school: "some updated school",
        first_year_class: 43,
        l75: 43,
        l50: 43,
        l25: 43,
        g75: "456.7",
        g50: "456.7",
        g25: "456.7",
        gre75v: 43,
        gre50v: 43,
        gre25v: 43,
        gre75q: 43,
        gre50q: 43,
        gre25q: 43,
        gre75w: "456.7",
        gre50w: "456.7"
      }

      assert {:ok, %FirstYearRanking{} = first_year_ranking} =
               FirstYearRankings.update_first_year_ranking(first_year_ranking, update_attrs)

      assert first_year_ranking.rank == 43
      assert first_year_ranking.school == "some updated school"
      assert first_year_ranking.first_year_class == 43
      assert first_year_ranking.l75 == 43
      assert first_year_ranking.l50 == 43
      assert first_year_ranking.l25 == 43
      assert first_year_ranking.g75 == Decimal.new("456.7")
      assert first_year_ranking.g50 == Decimal.new("456.7")
      assert first_year_ranking.g25 == Decimal.new("456.7")
      assert first_year_ranking.gre75v == 43
      assert first_year_ranking.gre50v == 43
      assert first_year_ranking.gre25v == 43
      assert first_year_ranking.gre75q == 43
      assert first_year_ranking.gre50q == 43
      assert first_year_ranking.gre25q == 43
      assert first_year_ranking.gre75w == Decimal.new("456.7")
      assert first_year_ranking.gre50w == Decimal.new("456.7")
    end

    test "update_first_year_ranking/2 with invalid data returns error changeset" do
      first_year_ranking = first_year_ranking_fixture()

      assert {:error, %Ecto.Changeset{}} =
               FirstYearRankings.update_first_year_ranking(first_year_ranking, @invalid_attrs)

      assert first_year_ranking ==
               FirstYearRankings.get_first_year_ranking!(first_year_ranking.id)
    end

    test "delete_first_year_ranking/1 deletes the first_year_ranking" do
      first_year_ranking = first_year_ranking_fixture()

      assert {:ok, %FirstYearRanking{}} =
               FirstYearRankings.delete_first_year_ranking(first_year_ranking)

      assert_raise Ecto.NoResultsError, fn ->
        FirstYearRankings.get_first_year_ranking!(first_year_ranking.id)
      end
    end

    test "change_first_year_ranking/1 returns a first_year_ranking changeset" do
      first_year_ranking = first_year_ranking_fixture()
      assert %Ecto.Changeset{} = FirstYearRankings.change_first_year_ranking(first_year_ranking)
    end
  end
end
