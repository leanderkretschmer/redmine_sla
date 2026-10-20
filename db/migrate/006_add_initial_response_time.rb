# Zwei Fristen: Reaktionszeit für neue Tickets und Antwortzeit auf Kommentare.
class AddInitialResponseTime < ActiveRecord::Migration[6.1]
  def up
    unless column_exists?(:sla_settings, :initial_response_time_minutes)
      add_column :sla_settings, :initial_response_time_minutes, :integer
    end
    # Bestehende Projekt-SLAs behalten ihr Verhalten: bisherige Frist gilt zunächst für beides.
    execute 'UPDATE sla_settings SET initial_response_time_minutes = response_time_minutes WHERE initial_response_time_minutes IS NULL'
    change_column_null :sla_settings, :initial_response_time_minutes, false

    unless column_exists?(:sla_rules, :initial_response_time_minutes)
      add_column :sla_rules, :initial_response_time_minutes, :integer
    end
  end

  def down
    remove_column :sla_rules, :initial_response_time_minutes if column_exists?(:sla_rules, :initial_response_time_minutes)
    remove_column :sla_settings, :initial_response_time_minutes if column_exists?(:sla_settings, :initial_response_time_minutes)
  end
end
