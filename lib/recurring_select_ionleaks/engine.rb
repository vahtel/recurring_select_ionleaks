module RecurringSelectIonleaks 
  class Engine < Rails::Engine
    
    initializer "recurring_select_ionleaks.extending_form_builder" do |app|
    # config.to_prepare do
      ActionView::Helpers::FormHelper.send(:include, RecurringSelectHelper::FormHelper)
      ActionView::Helpers::FormOptionsHelper.send(:include, RecurringSelectHelper::FormOptionsHelper)
      ActionView::Helpers::FormBuilder.send(:include, RecurringSelectHelper::FormBuilder)
    end
    
    initializer "recurring_select_ionleaks.connecting_middleware" do |app|
      app.middleware.use RecurringSelectMiddleware # insert_after ActionDispatch::ParamsParser, 
    end
    
  end
end
