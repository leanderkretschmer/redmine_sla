# Manuell aus der SLA-Betrachtung herausgenommene Auslöser (Ticket oder einzelner Kommentar).
class CreateSlaExclusions < ActiveRecord::Migration[6.1]
  def up
    return if table_exists?(:sla_exclusions)

    create_table :sla_exclusions do |t|
      t.integer :issue_id, null: false
      t.integer :journal_id, null: true
      t.integer :user_id, null: true
      t.string :reason
      t.timestamps
    end
    add_index :sla_exclusions, [:issue_id, :journal_id], unique: true
    add_foreign_key :sla_exclusions, :issues, column: :issue_id, on_delete: :cascade
  end

  def down
    drop_table :sla_exclusions if table_exists?(:sla_exclusions)
  end
end
