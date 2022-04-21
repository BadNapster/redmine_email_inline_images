require 'redmine'

Redmine::Plugin.register :redmine_email_inline_images do
  name 'Redmine email inline images plugin'
  author 'credativ Ltd'
  description 'Handle inline images on incoming emails, so that they are included inline in the issue description'
  version '4.0.0'
  requires_redmine :version_or_higher => '4.0.0'
end


if Rails.version > '6.0'
  ActiveSupport.on_load(:active_record) { RedmineEmailInlineImages.setup }
else
  Rails.configuration.to_prepare { RedmineEmailInlineImages.legacy_setup }
end
