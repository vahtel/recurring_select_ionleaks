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

  def self.clean_english_rule(rule,clock24)
    
    if clock24.to_b
      hour = (rule.validations[:hour_of_day].try(:first).try(:hour) || 0)
    else
      hour = convert_to_am_or_pm(rule.validations[:hour_of_day].try(:first).try(:hour) || 0)
    end
    
    minute = format('%02d', rule.validations[:minute_of_hour].try(:first).try(:minute) || 0)

    split_time_string = rule.to_s.split(/on the \d(th|rd|st|nd) hour/)
    if split_time_string.count == 1
      split_time_string = rule.to_s.split(/on the \d\d(th|rd|st|nd) hour/)
    end
    beginning_of_string = split_time_string.try(:first)
    
    if clock24.to_b
      if hour < 10
        hour = "0"+hour.to_s unless hour == 0
      end  
      return "#{beginning_of_string} at #{hour} hours"
      
    else
      return "#{beginning_of_string} at #{hour[0]}#{hour[1]}"
    end  
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
