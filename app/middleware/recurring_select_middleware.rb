require "ice_cube"

class RecurringSelectMiddleware

  def initialize(app)
    @app = app
  end

  def call(env)
    regexp = /^\/recurring_select\/translate\/(.*)/
    if env["PATH_INFO"] =~ regexp
      I18n.locale = env["PATH_INFO"].scan(regexp).first.first
      request = Rack::Request.new(env)
      params = request.params
      params.symbolize_keys!
      
      if params and params[:rule_type]
        clock24 = request.env['HTTP_X_CLOCK24']
        
        rule = RecurringSelectIonleaks.dirty_hash_to_rule(params)
        [200, {"Content-Type" => "text/html"}, [RecurringSelectIonleaks.clean_english_rule(rule,clock24)]]
      else
        [200, {"Content-Type" => "text/html"}, [""]]
      end
    else
      @app.call(env)
    end
  end


end
