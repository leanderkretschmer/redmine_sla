# Bundesweite gesetzliche Feiertage in Deutschland (ohne länderspezifische).
module RedmineSla
  module GermanHolidays
    class << self
      # Ostersonntag nach der Gauß'schen Osterformel (gregorianisch).
      def easter_sunday(year)
        a = year % 19
        b = year / 100
        c = year % 100
        d = b / 4
        e = b % 4
        f = (b + 8) / 25
        g = (b - f + 1) / 3
        h = (19 * a + b - d - g + 15) % 30
        i = c / 4
        k = c % 4
        l = (32 + 2 * e + 2 * i - h - k) % 7
        m = (a + 11 * h + 22 * l) / 451
        month = (h + l - 7 * m + 114) / 31
        day = ((h + l - 7 * m + 114) % 31) + 1
        Date.new(year, month, day)
      end

      # Liefert [[Datum, Name], ...] sortiert nach Datum.
      def national(year)
        easter = easter_sunday(year)
        [
          [Date.new(year, 1, 1), 'Neujahr'],
          [easter - 2, 'Karfreitag'],
          [easter + 1, 'Ostermontag'],
          [Date.new(year, 5, 1), 'Tag der Arbeit'],
          [easter + 39, 'Christi Himmelfahrt'],
          [easter + 50, 'Pfingstmontag'],
          [Date.new(year, 10, 3), 'Tag der Deutschen Einheit'],
          [Date.new(year, 12, 25), '1. Weihnachtstag'],
          [Date.new(year, 12, 26), '2. Weihnachtstag']
        ].sort_by(&:first)
      end
    end
  end
end
