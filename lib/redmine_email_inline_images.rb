module RedmineEmailInlineImages
    VERSION = '1.0.0'

    class << self
      def setup
    
        # Hooks
        RedmineEmailInlineImages::InlineHooks
      end

      def legacy_setup
        require_relative 'inline_hooks'
        require_relative 'lib/redmine_email_inline_images/mail_handler_patch'

        # Add module to MailHandler class if not added before
        unless MailHandler.include? RedmineEmailInlineImages::MailHandlerPatch
          MailHandler.send(:include, RedmineEmailInlineImages::MailHandlerPatch)
        end
      end
    end
end