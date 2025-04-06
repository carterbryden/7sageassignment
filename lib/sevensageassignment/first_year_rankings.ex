defmodule Sevensageassignment.FirstYearRankings do
  @moduledoc """
  The FirstYearRankings context.
  """

  import Ecto.Query, warn: false
  alias Sevensageassignment.Repo

  alias Sevensageassignment.FirstYearRankings.FirstYearRanking
  alias Sevensageassignment.FirstYearRankings.Importer

  @doc """
  Returns the list of first_year_rankings.

  ## Examples

      iex> list_first_year_rankings()
      [%FirstYearRanking{}, ...]

  """
  def list_first_year_rankings do
    Repo.all(FirstYearRanking)
  end

  @doc """
  Gets a single first_year_ranking.

  Raises `Ecto.NoResultsError` if the First year ranking does not exist.

  ## Examples

      iex> get_first_year_ranking!(123)
      %FirstYearRanking{}

      iex> get_first_year_ranking!(456)
      ** (Ecto.NoResultsError)

  """
  def get_first_year_ranking!(id), do: Repo.get!(FirstYearRanking, id)

  @doc """
  Creates a first_year_ranking.

  ## Examples

      iex> create_first_year_ranking(%{field: value})
      {:ok, %FirstYearRanking{}}

      iex> create_first_year_ranking(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_first_year_ranking(attrs \\ %{}) do
    %FirstYearRanking{}
    |> FirstYearRanking.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a first_year_ranking.

  ## Examples

      iex> update_first_year_ranking(first_year_ranking, %{field: new_value})
      {:ok, %FirstYearRanking{}}

      iex> update_first_year_ranking(first_year_ranking, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_first_year_ranking(%FirstYearRanking{} = first_year_ranking, attrs) do
    first_year_ranking
    |> FirstYearRanking.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a first_year_ranking.

  ## Examples

      iex> delete_first_year_ranking(first_year_ranking)
      {:ok, %FirstYearRanking{}}

      iex> delete_first_year_ranking(first_year_ranking)
      {:error, %Ecto.Changeset{}}

  """
  def delete_first_year_ranking(%FirstYearRanking{} = first_year_ranking) do
    Repo.delete(first_year_ranking)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking first_year_ranking changes.

  ## Examples

      iex> change_first_year_ranking(first_year_ranking)
      %Ecto.Changeset{data: %FirstYearRanking{}}

  """
  def change_first_year_ranking(%FirstYearRanking{} = first_year_ranking, attrs \\ %{}) do
    FirstYearRanking.changeset(first_year_ranking, attrs)
  end

  @doc """
  Imports law school rankings data from a CSV file into the database.

  ## Parameters

    * `file_path` - The path to the CSV file containing the rankings data.
      Expected column order: rank, school, first_year_class, l75, l50, l25,
      g75, g50, g25, gre75v, gre50v, gre25v, gre75q, gre50q, gre25q,
      gre75w, gre50w, gre25w

  ## Examples

      iex> Sevensageassignment.FirstYearRankings.import_from_csv("priv/repo/7sage-test-data.csv")
      :ok

  ## Details

  - Skips the header row of the CSV file
  - Converts empty strings to `nil` values
  - Processes data in batches of 100 for improved performance
  - Uses `on_conflict: :nothing` to skip records that would violate unique constraints,
    allowing the script to be run multiple times without creating duplicates
  """
  def import_from_csv(file_path) do
    Importer.import_from_csv(file_path)
  end
end
