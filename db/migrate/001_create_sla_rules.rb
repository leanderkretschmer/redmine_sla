class CreateSlaRules < ActiveRecord::Migration[6.1]
  def up
    drop_table :sla_rules if table_exists?(:sla_rules)
    create_table :sla_rules do |t|
      t.string :name, null: false
      t.text :description
      t.integer :project_id, null: true
      t.integer :tracker_id, null: true
      t.integer :status_id, null: true

      t.integer :priority, null: false, default: 1
      t.integer :resolution_time_minutes
      t.integer :response_time_minutes

      t.timestamps
    end

    add_index :sla_rules, :priority
    add_index :sla_rules, [:project_id, :tracker_id, :status_id]

    add_foreign_key :sla_rules, :projects, column: :project_id, on_delete: :nullify
    add_foreign_key :sla_rules, :trackers, column: :tracker_id, on_delete: :nullify
  end

  def down
    drop_table :sla_rules
  end
end
