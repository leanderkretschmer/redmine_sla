# Projektgebundene Sonderregeln und Feiertage werden mit dem Projekt gelöscht,
# statt durch ON DELETE SET NULL zu globalen Regeln/Feiertagen zu werden.
class CascadeProjectRulesAndHolidays < ActiveRecord::Migration[6.1]
  def up
    %i[sla_rules sla_holidays].each do |table|
      remove_foreign_key table, :projects if foreign_key_exists?(table, :projects)
      add_foreign_key table, :projects, column: :project_id, on_delete: :cascade
    end
  end

  def down
    %i[sla_rules sla_holidays].each do |table|
      remove_foreign_key table, :projects if foreign_key_exists?(table, :projects)
      add_foreign_key table, :projects, column: :project_id, on_delete: :nullify
    end
  end
end
