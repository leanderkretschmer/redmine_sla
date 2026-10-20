# Geschäftszeiten-Kalender: rechnet Reaktionsfristen in Arbeitsminuten
# (zwischen SOD und EOD, ohne Wochenenden/Feiertage) auf Zeitpunkte um.
module RedmineSla
  class SlaCalendar
    MAX_LOOKAHEAD_DAYS = 400

    attr_reader :sod_hour, :eod_hour, :puffer_minutes, :exclude_weekends, :holidays, :zone

    def initialize(sod_hour: 7, eod_hour: 18, puffer_minutes: 120,
                   exclude_weekends: true, holidays: [], zone: nil)
      @sod_hour = sod_hour.to_i.clamp(0, 23)
      @eod_hour = eod_hour.to_i.clamp(1, 24)
      @eod_hour = [@sod_hour + 1, 24].min if @eod_hour <= @sod_hour
      @puffer_minutes = [puffer_minutes.to_i, 0].max
      @exclude_weekends = exclude_weekends ? true : false
      @holidays = holidays.map(&:to_date).to_set
      @zone = zone || RedmineSla.time_zone
    end

    # Liefert { calculated_deadline:, internal_deadline: } für einen externen
    # Kommentar zum Zeitpunkt +start_time+ mit +response_minutes+ Reaktionsfrist.
    # Die interne Frist liegt spätestens +puffer_minutes+ vor Feierabend des
    # Fristtags, damit die Antwort nicht auf die letzte Minute fällt.
    def deadlines_for(start_time, response_minutes)
      start = localize(start_time)
      calculated = add_business_minutes(start, response_minutes)
      internal = calculated
      if puffer_minutes.positive?
        latest = end_of_business(calculated) - puffer_minutes.minutes
        internal = latest if latest < calculated
        internal = calculated if internal <= start
      end
      { calculated_deadline: calculated, internal_deadline: internal }
    end

    def business_day?(date)
      date = date.to_date
      return false if exclude_weekends && (date.saturday? || date.sunday?)

      !holidays.include?(date)
    end

    def add_business_minutes(start_time, minutes)
      current = normalize_start(localize(start_time))
      remaining = minutes.to_i
      return current if remaining <= 0

      MAX_LOOKAHEAD_DAYS.times do
        available = ((end_of_business(current) - current) / 60).floor
        return current + remaining.minutes if remaining <= available

        remaining -= available
        current = next_business_day_start(current)
      end
      current
    end

    private

    def localize(time)
      time.in_time_zone(zone)
    end

    def start_of_business(time)
      time.change(hour: sod_hour, min: 0, sec: 0)
    end

    def end_of_business(time)
      eod_hour >= 24 ? time.change(hour: 0, min: 0, sec: 0) + 1.day : time.change(hour: eod_hour, min: 0, sec: 0)
    end

    # Verschiebt einen Zeitpunkt auf den nächsten Moment innerhalb der Geschäftszeit.
    def normalize_start(time)
      t = time
      MAX_LOOKAHEAD_DAYS.times do
        unless business_day?(t.to_date)
          t = next_business_day_start(t)
          next
        end
        return start_of_business(t) if t < start_of_business(t)
        return t if t < end_of_business(t)

        t = next_business_day_start(t)
      end
      t
    end

    def next_business_day_start(time)
      date = time.to_date + 1
      steps = 0
      until business_day?(date) || steps > MAX_LOOKAHEAD_DAYS
        date += 1
        steps += 1
      end
      zone.local(date.year, date.month, date.day, sod_hour, 0, 0)
    end
  end
end
