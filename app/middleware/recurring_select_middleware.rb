require "ice_cube"

class RecurringSelectMiddleware

  def initialize(app)
    @app = app
  end

  def call(env)
    regexp = /^\/recurring_select\/translate\/(.*)/
    if env["PATH_INFO"] =~ regexp
      requested = env["PATH_INFO"].scan(regexp).first.first
      request = Rack::Request.new(env)
      params = request.params
      params.symbolize_keys!

      # with_locale, not `I18n.locale =`. This middleware answers and returns without ever
      # calling the app below it, so an assignment would leave the thread on that locale for
      # whatever request it serves next. Unknown locales fall back rather than raising.
      locale = locale_for(requested)

      I18n.with_locale(locale) do
        if params and params[:rule_type]
          clock24 = request.env['HTTP_X_CLOCK24']

          rule = RecurringSelectIonleaks.dirty_hash_to_rule(params)
          [200, {"Content-Type" => "text/html"}, [RecurringSelectIonleaks.clean_rule_text(rule, clock24)]]
        else
          [200, {"Content-Type" => "text/html"}, [""]]
        end
      end
    else
      @app.call(env)
    end
  end

  private

  # The locale segment comes straight off the URL, so treat it as untrusted: anything the app
  # does not know about is served in the default locale instead of raising InvalidLocale.
  def locale_for(requested)
    candidate = requested.to_s[/\A[A-Za-z]{2,3}(?:-[A-Za-z0-9]{2,8})?\z/]
    return I18n.default_locale if candidate.nil?

    sym = candidate.to_sym
    I18n.available_locales.include?(sym) ? sym : I18n.default_locale
  end

end
