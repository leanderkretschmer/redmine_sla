class CreateSlaHolidays < ActiveRecord::Migration[6.1]
  def change
    create_table :sla_holidays do |t|
      t.string :name, null: false
      t.date :date, null: false
      t.references :project, foreign_key: true, null: true

      t.timestamps
    end

    add_index :sla_holidays, :date
  end
end
