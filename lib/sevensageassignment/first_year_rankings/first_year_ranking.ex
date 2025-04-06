defmodule Sevensageassignment.FirstYearRankings.FirstYearRanking do
  use Ecto.Schema
  import Ecto.Changeset

  schema "first_year_rankings" do
    field :rank, :integer
    field :school, :string
    field :first_year_class, :integer
    field :l75, :integer
    field :l50, :integer
    field :l25, :integer
    field :g75, :decimal
    field :g50, :decimal
    field :g25, :decimal
    field :gre75v, :integer
    field :gre50v, :integer
    field :gre25v, :integer
    field :gre75q, :integer
    field :gre50q, :integer
    field :gre25q, :integer
    field :gre75w, :decimal
    field :gre50w, :decimal

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(first_year_ranking, attrs) do
    first_year_ranking
    |> cast(attrs, [:rank, :school, :first_year_class, :l75, :l50, :l25, :g75, :g50, :g25, :gre75v, :gre50v, :gre25v, :gre75q, :gre50q, :gre25q, :gre75w, :gre50w])
    |> validate_required([:rank, :school, :first_year_class, :l75, :l50, :l25, :g75, :g50, :g25, :gre75v, :gre50v, :gre25v, :gre75q, :gre50q, :gre25q, :gre75w, :gre50w])
  end
end
