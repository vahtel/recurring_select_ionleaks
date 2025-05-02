# Explicitly require the files to prevent autoloading during initialization
require_relative '../../app/helpers/recurring_select_helper'
require_relative '../../app/middleware/recurring_select_middleware'

module RecurringSelectIonleaks 
  class Engine < Rails::Engine
    # Initializer for extending FormBuilder, Helpers are now pre-required
    initializer "recurring_select_ionleaks.extending_form_builder" do |app|
      ActionView::Helpers::FormHelper.send(:include, RecurringSelectHelper::FormHelper)
      ActionView::Helpers::FormOptionsHelper.send(:include, RecurringSelectHelper::FormOptionsHelper)
      ActionView::Helpers::FormBuilder.send(:include, RecurringSelectHelper::FormBuilder)
    end
    
    # Initializer for connecting middleware, Middleware class is now pre-required
    initializer "recurring_select_ionleaks.connecting_middleware" do |app|
      app.middleware.use RecurringSelectMiddleware
    end
    
  end
end
