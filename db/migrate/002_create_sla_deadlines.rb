class CreateSlaDeadlines < ActiveRecord::Migration[6.1]
  def change
    create_table :sla_deadlines do |t|
      t.references :issue, foreign_key: { to_table: :issues }, null: false
      t.references :sla_rule, foreign_key: { to_table: :sla_rules }, null: true
      t.references :issue_note, foreign_key: { to_table: :notes }, null: true

      # Tracking
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
  end
end
