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
  """
  def import_from_csv(file_path) do
    Importer.import_from_csv(file_path)
  end

  @doc """
  Searches for distinct school names using a case-insensitive LIKE query.
  Returns a list of distinct matching school names, ordered alphabetically.
  Limits results to 10 by default.
  """
  def search_schools(term, limit \\ 10) do
    like_term = "%" <> String.downcase(term) <> "%"

    FirstYearRanking
    |> where([r], fragment("lower(?) LIKE ?", r.school, ^like_term))
    # Select only the school name
    |> select([r], r.school)
    # Get unique names
    |> distinct(true)
    # Order by name
    |> order_by(asc: :school)
    |> limit(^limit)
    # Returns a list of school name strings
    |> Repo.all()
  end

  @doc """
  Retrieves all FirstYearRanking records for a specific school,
  ordered by year (first_year_class ascending).
  """
  def get_rankings_by_school(school_name) when is_binary(school_name) do
    FirstYearRanking
    |> where([r], r.school == ^school_name)
    |> order_by(asc: :first_year_class)
    |> Repo.all()
  end

  def get_rankings_by_school(_), do: []

  @doc """
  Retrieves the most recent FirstYearRanking record for a specific school.
  Returns nil if the school has no records.
  """
  def get_latest_ranking_by_school(school_name) when is_binary(school_name) do
    FirstYearRanking
    |> where([r], r.school == ^school_name)
    # Order by year descending
    |> order_by(desc: :first_year_class)
    # Get only the latest one
    |> limit(1)
    # Fetch a single record or nil
    |> Repo.one()
  end

  def get_latest_ranking_by_school(_), do: nil
end
