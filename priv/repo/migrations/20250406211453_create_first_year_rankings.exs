defmodule Sevensageassignment.Repo.Migrations.CreateFirstYearRankings do
  use Ecto.Migration

  def change do
    create table(:first_year_rankings) do
      add :rank, :integer
      add :school, :string
      add :first_year_class, :integer
      add :l75, :integer
      add :l50, :integer
      add :l25, :integer
      add :g75, :decimal
      add :g50, :decimal
      add :g25, :decimal
      add :gre75v, :integer
      add :gre50v, :integer
      add :gre25v, :integer
      add :gre75q, :integer
      add :gre50q, :integer
      add :gre25q, :integer
      add :gre75w, :decimal
      add :gre50w, :decimal

      timestamps(type: :utc_datetime)
    end
  end
end
