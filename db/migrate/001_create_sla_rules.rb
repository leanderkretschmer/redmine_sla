class CreateSlaRules < ActiveRecord::Migration[6.1]
  def change
    create_table :sla_rules do |t|
      t.string :name, null: false
      t.text :description
      t.references :project, foreign_key: true, null: true
      t.references :tracker, foreign_key: { to_table: :trackers }, null: true
      t.references :issue_status, foreign_key: { to_table: :issue_statuses }, null: true, as: :status

      t.integer :priority, null: false, default: 1
      t.integer :resolution_time_minutes
      t.integer :response_time_minutes

      t.timestamps
    end

    add_index :sla_rules, :priority
    add_index :sla_rules, [:project_id, :tracker_id, :status_id]
  end
end
