# Unterscheidet "echte" (interne) Nutzer von externen Absendern.
# Intern sind die im Human-Resources-Plugin hinterlegten Mitarbeiter
# (Anstellungsart/Eintrittsdatum gesetzt oder Zeit-/Abwesenheitsbuchungen),
# optional zusätzlich Administratoren und Mitglieder einer konfigurierten Gruppe.
# Alle anderen (Mail-Absender, TYPO3-/API-Nutzer, Anonymous) gelten als extern.
module RedmineSla
  module InternalUsers
    CACHE_TTL_SECONDS = 60

    class << self
      def internal?(user)
        return false if user.nil? || !user.is_a?(User) || user.anonymous?

        internal_ids.include?(user.id)
      end

      def external?(user)
        !internal?(user)
      end

      def internal_ids
        now = Time.now
        if @ids.nil? || @cached_at.nil? || (now - @cached_at) > CACHE_TTL_SECONDS
          @ids = compute_ids
          @cached_at = now
        end
        @ids
      end

      def reset!
        @ids = nil
        @cached_at = nil
      end

      def hr_available?
        defined?(::HrUserSetting) && ::HrUserSetting.table_exists?
      rescue StandardError
        false
      end

      private

      def compute_ids
        ids = hr_available? ? hr_user_ids : ::User.active.where(type: 'User').pluck(:id)
        ids |= ::User.active.where(type: 'User', admin: true).pluck(:id) if admins_internal?
        if (group = internal_group)
          ids |= group.users.pluck(:id)
        end
        ids.to_set
      rescue StandardError => e
        RedmineSla.log(:error, "InternalUsers: #{e.class}: #{e.message}")
        Set.new
      end

      # Mitarbeiter laut Human-Resources-Plugin
      def hr_user_ids
        ids = []
        cols = ::HrUserSetting.column_names
        scope = ::HrUserSetting.none
        scope = scope.or(::HrUserSetting.where.not(hr_employment_type_id: nil)) if cols.include?('hr_employment_type_id')
        scope = scope.or(::HrUserSetting.where.not(employment_started_on: nil)) if cols.include?('employment_started_on')
        ids |= scope.pluck(:user_id)
        ids |= ::HrWorkEntry.distinct.pluck(:user_id) if defined?(::HrWorkEntry) && ::HrWorkEntry.table_exists?
        ids |= ::HrAbsence.distinct.pluck(:user_id) if defined?(::HrAbsence) && ::HrAbsence.table_exists?
        ids
      end

      def admins_internal?
        RedmineSla.setting(:admins_internal, '1').to_s == '1'
      end

      def internal_group
        id = RedmineSla.setting(:internal_group_id).to_i
        id.positive? ? ::Group.find_by(id: id) : nil
      end
    end
  end
end
