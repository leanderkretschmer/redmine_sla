class CreateSlaDeadlines < ActiveRecord::Migration[6.1]
  def up
    drop_table :sla_deadlines if table_exists?(:sla_deadlines)

    create_table :sla_deadlines do |t|
      t.integer :issue_id, null: false
      t.bigint :sla_rule_id, null: true
      t.bigint :issue_note_id, null: true

      t.datetime :external_comment_time, null: false
      t.datetime :calculated_deadline, null: false
      t.datetime :internal_deadline, null: false
      t.string :response_status, default: 'pending', null: false
      t.datetime :responded_at

      t.timestamps
    end

    add_index :sla_deadlines, [:issue_id, :response_status]
    add_index :sla_deadlines, [:internal_deadline]
    add_index :sla_deadlines, [:response_status]

    add_foreign_key :sla_deadlines, :issues, column: :issue_id, on_delete: :cascade
    add_foreign_key :sla_deadlines, :sla_rules, column: :sla_rule_id, on_delete: :nullify
    # FK zu :notes — übersprungen (bigint vs int(11))
  end

  def down
    drop_table :sla_deadlines
  end
end
