# Unterscheidet "echte" (interne) Nutzer von externen Absendern.
# Intern sind die im Human-Resources-Plugin hinterlegten Mitarbeiter:
# Nutzer mit Anstellungsart/Eintrittsdatum oder mit Zeit-/Abwesenheitsbuchungen.
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
        if hr_available?
          ids = []
          cols = ::HrUserSetting.column_names
          scope = ::HrUserSetting.none
          scope = scope.or(::HrUserSetting.where.not(hr_employment_type_id: nil)) if cols.include?('hr_employment_type_id')
          scope = scope.or(::HrUserSetting.where.not(employment_started_on: nil)) if cols.include?('employment_started_on')
          ids |= scope.pluck(:user_id)
          ids |= ::HrWorkEntry.distinct.pluck(:user_id) if defined?(::HrWorkEntry) && ::HrWorkEntry.table_exists?
          ids |= ::HrAbsence.distinct.pluck(:user_id) if defined?(::HrAbsence) && ::HrAbsence.table_exists?
          ids.to_set
        else
          # Fallback ohne HR-Plugin: aktive, nicht gesperrte Benutzerkonten.
          ::User.active.where(type: 'User').pluck(:id).to_set
        end
      rescue StandardError => e
        RedmineSla.log(:error, "InternalUsers: #{e.class}: #{e.message}")
        Set.new
      end
    end
  end
end
