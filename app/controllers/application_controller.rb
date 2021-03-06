# Filters added to this controller will be run for all controllers in the application.
# Likewise, all the methods added will be available for all controllers.
class ApplicationController < ActionController::Base

before_filter :set_locale

def set_locale
  # if params[:locale] is nil then I18n.default_locale will be used
  I18n.locale = params[:locale]
end

def default_url_options(options={})
  logger.debug "default_url_options is passed options: #{options.inspect}\n"
  { :locale => I18n.locale }
end

end