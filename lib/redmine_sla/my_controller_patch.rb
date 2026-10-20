# Blendet den SLA-Block beim ersten Aufruf von "Meine Seite" automatisch oben ein.
# Der Nutzer kann ihn danach wie jeden anderen Block entfernen; er wird nicht erneut hinzugefügt.
module RedmineSla
  module MyControllerPatch
    BLOCK = 'sla_overview'.freeze
    PREF_FLAG = 'redmine_sla_block_added'.freeze

    def self.prepended(base)
      base.before_action :redmine_sla_ensure_block, only: [:page]
    end

    private

    def redmine_sla_ensure_block
      user = User.current
      return unless user.logged?

      pref = user.pref
      return if pref[PREF_FLAG]

      layout = pref.my_page_layout.deep_dup
      unless layout.values.flatten.include?(BLOCK)
        layout['top'] = [BLOCK] + Array(layout['top'])
        pref.my_page_layout = layout
      end
      pref[PREF_FLAG] = true
      pref.save
    rescue StandardError => e
      RedmineSla.log(:warn, "MyControllerPatch: #{e.class}: #{e.message}")
    end
  end
end
