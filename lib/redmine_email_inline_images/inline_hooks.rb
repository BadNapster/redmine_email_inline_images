module RedmineEmailInlineImages
  class InlineHooks < Redmine::Hook::Listener
    def after_plugins_loaded(_context = {})
      return if Rails.version < '6.0'

      # Add module to MailHandler class if not added before
      unless MailHandler.include? RedmineEmailInlineImages::MailHandlerPatch
        MailHandler.send(:include, RedmineEmailInlineImages::MailHandlerPatch)
      end
    end      
  end
end