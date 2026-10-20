# Umbau auf projektgebundene SLA-Einstellungen und Journal-Verknüpfung der Fristen.
class ReworkSlaTables < ActiveRecord::Migration[6.1]
  def up
    # --- sla_deadlines: issue_note_id -> journal_id, zusätzliche Spalten
    if column_exists?(:sla_deadlines, :issue_note_id)
      if column_exists?(:sla_deadlines, :journal_id)
        remove_column :sla_deadlines, :issue_note_id
      else
        rename_column :sla_deadlines, :issue_note_id, :journal_id
      end
    end
    add_column :sla_deadlines, :journal_id, :integer unless column_exists?(:sla_deadlines, :journal_id)
    add_column :sla_deadlines, :project_id, :integer unless column_exists?(:sla_deadlines, :project_id)
    add_column :sla_deadlines, :responded_by_id, :integer unless column_exists?(:sla_deadlines, :responded_by_id)
    add_column :sla_deadlines, :response_journal_id, :integer unless column_exists?(:sla_deadlines, :response_journal_id)

    unless index_exists?(:sla_deadlines, [:project_id, :response_status], name: 'idx_sla_deadlines_project_status')
      add_index :sla_deadlines, [:project_id, :response_status], name: 'idx_sla_deadlines_project_status'
    end
    add_index :sla_deadlines, :journal_id unless index_exists?(:sla_deadlines, :journal_id)

    execute <<~SQL
      UPDATE sla_deadlines d
        JOIN issues i ON i.id = d.issue_id
         SET d.project_id = i.project_id
       WHERE d.project_id IS NULL
    SQL

    # --- sla_settings: genau ein Datensatz pro Projekt, Projekt verpflichtend
    execute 'DELETE FROM sla_settings WHERE project_id IS NULL'

    if foreign_key_exists?(:sla_settings, :projects)
      remove_foreign_key :sla_settings, :projects
    end
    if index_exists?(:sla_settings, :project_id) && !index_exists?(:sla_settings, :project_id, unique: true)
      remove_index :sla_settings, column: :project_id
    end
    change_column_null :sla_settings, :project_id, false
    add_index :sla_settings, :project_id, unique: true unless index_exists?(:sla_settings, :project_id, unique: true)
    add_foreign_key :sla_settings, :projects, column: :project_id, on_delete: :cascade

    # --- sla_rules: Reaktionsfrist ist Pflicht
    execute 'DELETE FROM sla_rules WHERE response_time_minutes IS NULL'
  end

  def down
    remove_foreign_key :sla_settings, :projects if foreign_key_exists?(:sla_settings, :projects)
    remove_index :sla_settings, column: :project_id if index_exists?(:sla_settings, :project_id)
    change_column_null :sla_settings, :project_id, true
    add_index :sla_settings, :project_id
    add_foreign_key :sla_settings, :projects, column: :project_id, on_delete: :nullify

    remove_index :sla_deadlines, name: 'idx_sla_deadlines_project_status' if index_exists?(:sla_deadlines, [:project_id, :response_status], name: 'idx_sla_deadlines_project_status')
    remove_index :sla_deadlines, :journal_id if index_exists?(:sla_deadlines, :journal_id)
    remove_column :sla_deadlines, :response_journal_id if column_exists?(:sla_deadlines, :response_journal_id)
    remove_column :sla_deadlines, :responded_by_id if column_exists?(:sla_deadlines, :responded_by_id)
    remove_column :sla_deadlines, :project_id if column_exists?(:sla_deadlines, :project_id)
    rename_column :sla_deadlines, :journal_id, :issue_note_id if column_exists?(:sla_deadlines, :journal_id)
  end
end
