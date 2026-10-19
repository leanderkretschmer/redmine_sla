# SLA Business Hours Calendar
module RedmineSla
  module Calendar
    def self.calculate(comment_time, response_time_minutes, sod_hour: 7, eod_hour: 18,
                       puffer_minutes: 120, exclude_weekends: true, holidays: [])
      comment_time = comment_time.to_time
      internal_eod = comment_time + response_time_minutes * 60
      internal_eod = internal_eod.change(hour: eod_hour, min: 0, sec: 0) - puffer_minutes * 60
      internal_deadline = [internal_eod, comment_time + response_time_minutes * 60].min
      internal_deadline = comment_time + 86400 if internal_deadline < comment_time

      {
        calculated_deadline: comment_time + response_time_minutes * 60,
        internal_deadline: internal_deadline
      }
    end

    def self.add_business_minutes(start_time, minutes, sod_hour: 7, eod_hour: 18,
                                  exclude_weekends: true, holidays: [])
      current_time = start_time.to_time
      remaining = minutes.to_i
      minutes_per_day = (eod_hour - sod_hour) * 60

      while remaining > 0
        if exclude_weekends && (current_time.wday == 0 || current_time.wday == 6)
          current_time = next_monday(current_time)
          remaining = minutes.to_i
          next
        end

        if holidays.include?(current_time.to_date)
          current_time = next_monday(current_time)
          remaining = minutes.to_i
          next
        end

        sod = current_time.change(hour: sod_hour, min: 0, sec: 0)
        eod = current_time.change(hour: eod_hour, min: 0, sec: 0)

        if current_time < sod
          current_time = sod
          next
        end

        if current_time >= eod
          current_time = next_monday(current_time)
          remaining = minutes.to_i
          next
        end

        minutes_left = (eod - current_time).to_i / 60
        if remaining <= minutes_left
          current_time += remaining * 60
          remaining = 0
        else
          remaining -= minutes_left
          current_time = next_monday(current_time)
          current_time = current_time.change(hour: sod_hour, min: 0, sec: 0)
        end
      end
      current_time
    end

    def self.next_monday(time)
      days_ahead = (7 - time.wday) % 7
      days_ahead = 7 if days_ahead == 0
      time + days_ahead * 86400
    end
  end
end
