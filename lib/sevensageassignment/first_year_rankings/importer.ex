defmodule Sevensageassignment.FirstYearRankings.Importer do
  alias Sevensageassignment.Repo
  alias Sevensageassignment.FirstYearRankings.FirstYearRanking
  require NimbleCSV.RFC4180, as: CSV

  @doc """
  Imports law school rankings data from a CSV file into the database.

  ## Parameters

    * `file_path` - The path to the CSV file containing the rankings data.
      Expected column order: rank, school, first_year_class, l75, l50, l25,
      g75, g50, g25, gre75v, gre50v, gre25v, gre75q, gre50q, gre25q,
      gre75w, gre50w, gre25w

  ## Examples

      iex> Sevensageassignment.ImportRankings.import_from_csv("priv/repo/7sage-test-data.csv")
      :ok

  ## Details

  - Skips the header row of the CSV file
  - Converts empty strings to `nil` values
  - Processes data in batches of 100 for improved performance
  - Uses `on_conflict: :nothing` to skip records that would violate unique constraints,
    allowing the script to be run multiple times without creating duplicates
  """
  def import_from_csv(file_path) do
    file_path
    |> File.stream!()
    |> CSV.parse_stream()
    # Skip the header row
    |> Stream.drop(1)
    |> Stream.map(fn row ->
      [
        rank,
        school,
        first_year_class,
        l75,
        l50,
        l25,
        g75,
        g50,
        g25,
        gre75v,
        gre50v,
        gre25v,
        gre75q,
        gre50q,
        gre25q,
        gre75w,
        gre50w,
        gre25w
      ] = row

      now = DateTime.utc_now() |> DateTime.truncate(:second)

      %{
        rank: parse_integer(rank),
        school: school,
        first_year_class: parse_integer(first_year_class),
        l75: parse_integer(l75),
        l50: parse_integer(l50),
        l25: parse_integer(l25),
        g75: parse_decimal(g75),
        g50: parse_decimal(g50),
        g25: parse_decimal(g25),
        gre75v: parse_integer(gre75v),
        gre50v: parse_integer(gre50v),
        gre25v: parse_integer(gre25v),
        gre75q: parse_integer(gre75q),
        gre50q: parse_integer(gre50q),
        gre25q: parse_integer(gre25q),
        gre75w: parse_decimal(gre75w),
        gre50w: parse_decimal(gre50w),
        gre25w: parse_decimal(gre25w),
        # timestamps at aren't auto-included on insert_all,
        inserted_at: now,
        # so we add it in manually here.
        updated_at: now
      }
    end)
    # Process in batches of 100
    |> Stream.chunk_every(100)
    |> Stream.each(fn batch ->
      # insert all but skip any with conflicts
      Repo.insert_all(FirstYearRanking, batch, on_conflict: :nothing)
    end)
    |> Stream.run()
  end

  defp parse_integer(""), do: nil

  defp parse_integer(str) do
    case Integer.parse(str) do
      {num, _} -> num
      :error -> nil
    end
  end

  defp parse_decimal(""), do: nil

  defp parse_decimal(str) do
    case Decimal.parse(str) do
      # This returns just the Decimal struct
      {decimal, _remainder} -> decimal
      :error -> nil
    end
  end
end
