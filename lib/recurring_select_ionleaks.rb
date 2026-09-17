require "recurring_select_ionleaks/engine"
require "ice_cube"

module RecurringSelectIonleaks

  def self.dirty_hash_to_rule(params)
      
    if params.is_a? IceCube::Rule
      params
    else
      params = JSON.parse(params, quirks_mode: true) if params.is_a?(String)
      if params.nil?
        nil
      else
        params = params.symbolize_keys
        rules_hash = filter_params(params)
        IceCube::Rule.from_hash(rules_hash)
      end

    end
  end

  # Human description of a rule, in the CURRENT I18n locale.
  #
  # ice_cube localises `rule.to_s` (it ships de/es/fr/it/ja/nl/pt-BR/ru/sv), but the hour and
  # minute validations come back as a clause the caller does not want ("... on the 9th hour of
  # the day on the 0th minute of the hour"). This used to be cut off with an English regex and
  # replaced by a hardcoded English "at N hours", so any other locale kept its own hour clause
  # AND gained an English one.
  #
  # Instead of cutting the clause out of the sentence, describe a rule that never had it: the
  # time is read from the validations and rendered separately through I18n. Nothing here is
  # language-specific any more.
  def self.clean_rule_text(rule, clock24)
    hour_of_day = rule.validations[:hour_of_day].try(:first).try(:hour) || 0
    schedule    = rule_without_time_of_day(rule).to_s

    if clock24.to_b
      # Zero-padded except midnight - that is what this has always printed.
      hour = hour_of_day
      hour = "0" + hour.to_s if hour < 10 && hour != 0
      I18n.t("recurring_select.at_hour_24",
             rule: schedule, hour: hour, default: "%{rule} at %{hour} hours")
    else
      digit, meridiem = convert_to_am_or_pm(hour_of_day)
      # The am/pm marker is itself wording: rails-i18n carries time.am / time.pm, and a host
      # app may have narrowed them (Breeze uses "vorm." / "nachm."). English keeps "9am" with
      # no space; the other locales separate the two, hence a format key rather than concat.
      meridiem = I18n.t("time.#{meridiem}", default: meridiem)
      time = I18n.t("recurring_select.time_12",
                    hour: digit, meridiem: meridiem, default: "%{hour}%{meridiem}")
      I18n.t("recurring_select.at_time_12",
             rule: schedule, time: time, default: "%{rule} at %{time}")
    end
  end

  # Kept so an older caller does not break; the name was only ever accurate for English.
  def self.clean_english_rule(rule, clock24)
    clean_rule_text(rule, clock24)
  end

  # The same rule with the time-of-day validations removed, so `to_s` describes the recurrence
  # alone. Falls back to the original rule if the round-trip through the hash fails.
  def self.rule_without_time_of_day(rule)
    hash        = rule.to_hash
    validations = hash[:validations] || hash["validations"]
    return rule if validations.nil?

    validations = validations.dup
    [:hour_of_day, :minute_of_hour, :second_of_minute].each do |key|
      validations.delete(key)
      validations.delete(key.to_s)
    end
    IceCube::Rule.from_hash(hash.merge(validations: validations))
  rescue StandardError
    rule
  end

  def self.is_valid_rule?(possible_rule)
    return true if possible_rule.is_a?(IceCube::Rule)
    return false if possible_rule.blank?

    if possible_rule.is_a?(String)
      begin
        JSON.parse(possible_rule)
        return true
      rescue JSON::ParserError
        return false
      end
    end

    # TODO: this should really have an extra step where it tries to perform the final parsing
    return true if possible_rule.is_a?(Hash)

    false #only a hash or a string of a hash can be valid
  end

  private

  def self.filter_params(params)

    params.reject!{|key, value| value.blank? || value=="null" }

    params[:interval] = params[:interval].to_i if params[:interval]
    params[:week_start] = params[:week_start].to_i if params[:week_start]

    params[:validations] ||= {}
    params[:validations].symbolize_keys!

    if params[:validations][:day]
      params[:validations][:day] = params[:validations][:day].collect(&:to_i)
    end

    if params[:validations][:day_of_month]
      params[:validations][:day_of_month] = params[:validations][:day_of_month].collect(&:to_i)
    end

    if params[:validations][:hour_of_day]
      if params[:validations][:hour_of_day].is_a? Array
        params[:validations][:hour_of_day] = params[:validations][:hour_of_day][0].to_i
      else
        params[:validations][:hour_of_day] = params[:validations][:hour_of_day].to_i
      end
    end

    if params[:validations][:minute_of_hour]
      if params[:validations][:minute_of_hour].is_a? Array
        params[:validations][:minute_of_hour] = params[:validations][:minute_of_hour][0].to_i
      else
        params[:validations][:minute_of_hour] = params[:validations][:minute_of_hour].to_i
      end
    end


    # this is soooooo ugly
    if params[:validations][:day_of_week]
      params[:validations][:day_of_week] ||= {}
      if params[:validations][:day_of_week].length > 0 and not params[:validations][:day_of_week].keys.first =~ /\d/
        params[:validations][:day_of_week].symbolize_keys!
      else
        originals = params[:validations][:day_of_week].dup
        params[:validations][:day_of_week] = {}
        originals.each{|key, value|
          params[:validations][:day_of_week][key.to_i] = value
        }
      end
      params[:validations][:day_of_week].each{|key, value|
        params[:validations][:day_of_week][key] = value.collect(&:to_i)
      }
    end

    if params[:validations][:day_of_year]
      params[:validations][:day_of_year] = params[:validations][:day_of_year].collect(&:to_i)
    end

    params
  end

  def self.convert_to_am_or_pm(digit)
    if digit < 12
      if digit == 0
        [12, "am"]
      else
        [digit, "am"]
      end
    else
      if digit == 12 
        [12, "pm"]
      else
        [digit-12, "pm"]
      end
    end
  end
end
