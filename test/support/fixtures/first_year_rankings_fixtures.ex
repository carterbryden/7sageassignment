defmodule Sevensageassignment.FirstYearRankingsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Sevensageassignment.FirstYearRankings` context.
  """

  @doc """
  Generate a first_year_ranking.
  """
  def first_year_ranking_fixture(attrs \\ %{}) do
    {:ok, first_year_ranking} =
      attrs
      |> Enum.into(%{
        first_year_class: 42,
        g25: "120.5",
        g50: "120.5",
        g75: "120.5",
        gre25q: 42,
        gre25v: 42,
        gre50q: 42,
        gre50v: 42,
        gre50w: "120.5",
        gre75q: 42,
        gre75v: 42,
        gre75w: "120.5",
        l25: 42,
        l50: 42,
        l75: 42,
        rank: 42,
        school: "some school"
      })
      |> Sevensageassignment.FirstYearRankings.create_first_year_ranking()

    first_year_ranking
  end
end
