module RedmineEmailInlineImages
  module MailHandlerPatch

    def self.included(base) # :nodoc:
      base.send(:include, InstanceMethods)
      
      base.class_eval do
        alias_method :email_parts_to_text_default, :email_parts_to_text
        alias_method :email_parts_to_text, :email_parts_to_text_with_inline_images

        alias_method :add_attachments_default, :add_attachments
        alias_method :add_attachments, :add_attachments_with_inline_images
      end
    end

    module InstanceMethods
      private
      @images
      @strOpen
      @strClose

      def initialize
        @images = {}
        case Setting.text_formatting
        when 'common_mark'
          @strOpen = "![]("
          @strClose = ")"
        when 'markdown'
          @strOpen = "![]("
          @strClose = ")"
        when 'textile'
          @strOpen = "!"
          @strClose = "!"
        else
          @strOpen = ""
          @strClose = ""
        end
      end

      # Find all images inside message
      def email_parts_to_text_with_inline_images(parts)  
        email.all_parts.each do |part|
            if part['Content-ID']
                if part['Content-ID'].respond_to?(:element)
                    content_id = part['Content-ID'].element.message_ids[0]
                else
                    content_id = part['Content-ID'].value.gsub(%r{(^<|>$)}, '')
                end
                image = part.header['Content-Type'].parameters['name']
                @images["cid:#{content_id}"] = image
            end
        end

        
        email_parts_to_text_default(parts)
      end

      # update issue inline images with full path
      # to prevent overlapping names when replies come in
      def add_attachments_with_inline_images(obj)
        add_attachments_default(obj)
        obj.reload

        # route/path to attachments
        # need to get this from redmine installation
        path = "/attachments/download"

        obj.attachments.each do |att|
          if @images.has_value?(att.filename)
            str_r = Regexp.escape("[image: #{att.filename}]")
            regex = Regexp.new(str_r)
            obj.description.scan(regex).each do |match|
              # tmp_desc = obj.description.gsub(match, "#{@strOpen}#{path}/#{att.id}/#{att.filename}#{@strClose}")
              tmp_desc = obj.description.gsub(match, "#{@strOpen}#{att.filename}#{@strClose}")
              obj.description = tmp_desc
            end
          end
        end

        obj.save!
      end      
    end # module InstanceMethods
  end # module MailHandlerPatch
end # module RedmineEmailInlineImages
