class CreateSlaSettings < ActiveRecord::Migration[6.1]
  def change
    create_table :sla_settings do |t|
      t.integer :project_id, null: true
      t.integer :response_time_minutes, null: false
      t.integer :puffer_minutes_before_eod, default: 120
      t.integer :eod_hour, default: 18
      t.integer :sod_hour, default: 7
      t.boolean :exclude_weekends, default: true
      t.boolean :exclude_holidays, default: true

      t.timestamps
    end

    add_index :sla_settings, :project_id
    add_foreign_key :sla_settings, :projects, column: :project_id, on_delete: :nullify
  end
end
