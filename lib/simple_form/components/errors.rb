module SimpleForm
  module Components
    module Errors
      def error(wrapper_options = nil)
        error_text if has_errors?
      end

      def full_error(wrapper_options = nil)
        full_error_text if options[:error] != false && has_errors?
      end

      def has_errors?
        object && object.respond_to?(:errors) && errors.present?
      end

      protected

      def error_text
        text = has_error_in_options? ? options[:error] : errors.send(error_method)

        "#{html_escape(options[:error_prefix])} #{text}".lstrip.html_safe
      end

      def full_error_text
        text = has_error_in_options? ? options[:error] : full_errors.send(error_method)
        text.html_safe
      end

      def error_method
        options[:error_method] || SimpleForm.error_method
      end

      def errors
        @errors ||= (errors_on_attribute + errors_on_association).compact
      end

      def full_errors
        @full_errors ||= (full_errors_on_attribute + full_errors_on_association).compact
      end

      def errors_on_attribute
        object.errors[attribute_name]
      end

      def full_errors_on_attribute
        object.errors.full_messages_for(attribute_name)
      end

      def errors_on_association
        reflection ? object.errors[reflection.name] : []
      end

      def full_errors_on_association
        reflection ? object.full_messages_for(reflection.name) : []
      end

      def has_error_in_options?
        options[:error] && !options[:error].nil?
      end
    end
  end
end
