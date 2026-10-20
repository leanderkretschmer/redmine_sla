# Platziert den SLA-Block auf "Meine Seite" automatisch unterhalb von "Beobachtete Tickets"
# (bzw. am Ende der linken Spalte). Geschieht einmalig; entfernt der Nutzer den Block,
# wird er nicht erneut hinzugefügt.
module RedmineSla
  module MyControllerPatch
    BLOCK = 'sla_overview'.freeze
    ANCHOR_BLOCK = 'issueswatched'.freeze
    PREF_FLAG = 'redmine_sla_block_placed_v2'.freeze

    def self.prepended(base)
      base.before_action :redmine_sla_place_block, only: [:page]
    end

    private

    def redmine_sla_place_block
      user = User.current
      return unless user.logged?

      pref = user.pref
      return if pref[PREF_FLAG]

      layout = pref.my_page_layout.deep_dup
      layout.each_value { |blocks| blocks.delete(BLOCK) }

      group = layout.find { |_, blocks| blocks.include?(ANCHOR_BLOCK) }&.first
      if group
        blocks = layout[group]
        blocks.insert(blocks.index(ANCHOR_BLOCK) + 1, BLOCK)
      else
        layout['left'] = Array(layout['left']) + [BLOCK]
      end

      pref.my_page_layout = layout
      pref[PREF_FLAG] = true
      pref.save
    rescue StandardError => e
      RedmineSla.log(:warn, "MyControllerPatch: #{e.class}: #{e.message}")
    end
  end
end
