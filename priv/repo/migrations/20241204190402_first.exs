defmodule Helpdesk.Repo.Migrations.First do
  @moduledoc """
  Updates resources based on their most recent snapshots.

  This file was autogenerated with `mix ash_postgres.generate_migrations`
  """

  use Ecto.Migration

  def up do
    create table(:tickets, primary_key: false) do
      add(:id, :uuid, null: false, default: fragment("gen_random_uuid()"), primary_key: true)
      add(:subject, :text, null: false)

      add(:inserted_at, :utc_datetime_usec,
        null: false,
        default: fragment("(now() AT TIME ZONE 'utc')")
      )

      add(:updated_at, :utc_datetime_usec,
        null: false,
        default: fragment("(now() AT TIME ZONE 'utc')")
      )

      add(
        :parent_id,
        references(:tickets,
          column: :id,
          name: "tickets_parent_id_fkey",
          type: :uuid,
          prefix: "public"
        )
      )
    end
  end

  def down do
    drop(constraint(:tickets, "tickets_parent_id_fkey"))

    drop(table(:tickets))
  end
end