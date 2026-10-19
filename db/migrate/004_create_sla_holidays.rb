class CreateSlaHolidays < ActiveRecord::Migration[6.1]
  def up
    drop_table :sla_holidays if table_exists?(:sla_holidays)
    create_table :sla_holidays do |t|
      t.string :name, null: false
      t.date :date, null: false
      t.integer :project_id, null: true

      t.timestamps
    end

    add_index :sla_holidays, :date
    add_foreign_key :sla_holidays, :projects, column: :project_id, on_delete: :nullify
  end

  def down
    drop_table :sla_holidays
  end
end
