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

        if obj.is_a?(Issue)
          # Rails.logger.info "InlineMailHandler: issue ##{obj.id} passed"  
          # route/path to attachments
          # need to get this from redmine installation
          path = "/attachments/download"
          
          obj.reload
          last_journal_id = obj.last_journal_id
          if last_journal_id.nil?
            description = obj.description            
            # Rails.logger.info "InlineMailHandler: no last_journal find"
          else
            last_journal = Journal.find(last_journal_id) 
            # Rails.logger.info "InlineMailHandler: last_journal ##{last_journal.id} find"
            description = last_journal.notes
          end                  
                   
          obj.attachments.each do |att|
            str_r = Regexp.escape(att.filename)
            str_r = "\\[(?:image|cid).?:.?#{str_r}(?:[@A-Z\\d\\.]*)\\]"
            regex = Regexp.new(str_r)
            if @images.has_value?(att.filename)              
              description.scan(regex).each do |match|
                tmp_desc = description.gsub(match, "#{@strOpen}#{path}/#{att.id}/#{att.filename}#{@strClose}")
                # tmp_desc = description.gsub(match, "#{@strOpen}#{att.filename}#{@strClose}")
                description = tmp_desc
              end        
              # Rails.logger.info "InlineMailHandler: description ##{description}"
            end
          end
          
          if last_journal_id.nil? 
            # Rails.logger.info "InlineMailHandler: obj.save!"
            obj.description = description
            obj.save!
          else            
            # Rails.logger.info "InlineMailHandler: last_journal.save"
            last_journal.notes = description
            last_journal.save
          end          
        end        
      end 
    end # module InstanceMethods
  end # module MailHandlerPatch
end # module RedmineEmailInlineImages
