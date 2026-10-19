# SLA Calendar - handles business hours, holidays, and deadline calculation
module SlaCalendar
  # Calculate the internal deadline given an external comment time and SLA settings
  #
  # Args:
  #   comment_time: Time when the external comment was received
  #   response_time_minutes: SLA response time in minutes
  #   sod_hour: Start of day (e.g., 7)
  #   eod_hour: End of day (e.g., 18)
  #   puffer_minutes: Buffer before EOD (e.g., 120 = 2 hours)
  #   exclude_weekends: Whether to skip weekends
  #   holidays: Array of holiday dates to skip
  #
  # Returns:
  #   Hash with :calculated_deadline and :internal_deadline
  def self.calculate(comment_time, response_time_minutes, sod_hour: 7, eod_hour: 18,
                     puffer_minutes: 120, exclude_weekends: true, holidays: [])
    comment_time = comment_time.to_time
    sod_hour = sod_hour.to_i
    eod_hour = eod_hour.to_i
    puffer_minutes = puffer_minutes.to_i

    # Calculate the raw deadline (add response time to comment time)
    raw_deadline = comment_time + response_time_minutes * 60

    # If raw deadline is within business hours and after buffer, clamp to EOD - buffer
    internal_deadline = clamp_to_internal_deadline(raw_deadline, comment_time, sod_hour,
                                                    eod_hour, puffer_minutes, exclude_weekends, holidays)

    {
      calculated_deadline: raw_deadline,
      internal_deadline: internal_deadline
    }
  end

  # Add business minutes to a start time, skipping non-business hours
  # This is used to add response_time_minutes to comment_time
  def self.add_business_minutes(start_time, minutes, sod_hour: 7, eod_hour: 18,
                                 exclude_weekends: true, holidays: [])
    sod_hour = sod_hour.to_i
    eod_hour = eod_hour.to_i
    minutes_per_business_day = (eod_hour - sod_hour) * 60

    current_time = start_time.to_time
    remaining = minutes.to_i

    while remaining > 0
      # Skip weekends
      if exclude_weekends && (current_time.wday == 0 || current_time.wday == 6)
        current_time = next_monday(current_time)
        remaining = minutes.to_i # Reset for new day
        next
      end

      # Skip holidays
      if holidays.include?(current_time.to_date)
        current_time = next_working_day(current_time, exclude_weekends, holidays)
        remaining = minutes.to_i
        next
      end

      # Calculate business hours remaining today
      sod = current_time.change(hour: sod_hour, min: 0, sec: 0)
      eod = current_time.change(hour: eod_hour, min: 0, sec: 0)

      if current_time < sod
        current_time = sod
        next
      end

      if current_time >= eod
        current_time = next_working_day(current_time, exclude_weekends, holidays)
        remaining = minutes.to_i
        next
      end

      minutes_left_today = (eod - current_time).to_i / 60

      if remaining <= minutes_left_today
        current_time += remaining * 60
        remaining = 0
      else
        remaining -= minutes_left_today
        current_time = next_working_day(current_time, exclude_weekends, holidays)
        current_time = current_time.change(hour: sod_hour, min: 0, sec: 0)
      end
    end

    current_time
  end

  private

  def self.next_monday(time)
    days_ahead = (7 - time.wday) % 7
    days_ahead = 7 if days_ahead == 0
    time + days_ahead * 86400
  end

  def self.next_working_day(time, exclude_weekends, holidays)
    candidate = time + 86400 # Next day
    while true
      break if !exclude_weekends || (candidate.wday != 0 && candidate.wday != 6) && !holidays.include?(candidate.to_date)
      candidate += 86400
    end
    candidate
  end

  def self.clamp_to_internal_deadline(raw_deadline, comment_time, sod_hour, eod_hour,
                                       puffer_minutes, exclude_weekends, holidays)
    sod_hour = sod_hour.to_i
    eod_hour = eod_hour.to_i
    puffer_minutes = puffer_minutes.to_i

    internal_eod = raw_deadline.change(hour: eod_hour, min: 0, sec: 0) - puffer_minutes * 60

    # Clamp internal deadline to EOD - buffer, but not before comment time
    internal_deadline = [internal_eod, raw_deadline].min

    # If internal deadline is before comment time, move to next business day
    if internal_deadline < comment_time
      # Find the next working day where internal_eod would be after comment
      candidate = comment_time + 86400
      while true
        candidate_date = candidate.to_date
        is_holiday = holidays.include?(candidate_date)
        is_weekend = exclude_weekends && (candidate.wday == 0 || candidate.wday == 6)

        if !is_weekend && !is_holiday
          next_internal_eod = candidate.change(hour: eod_hour, min: 0, sec: 0) - puffer_minutes * 60
          return next_internal_eod
        end

        candidate += 86400
      end
    end

    internal_deadline
  end
end
