module SimpleForm
  module Inputs
    class Base
      extend I18nCache

      include SimpleForm::Helpers::Readonly
      include SimpleForm::Helpers::Required
      include SimpleForm::Helpers::Validators
      include SimpleForm::Helpers::Pattern

      include SimpleForm::Components::Disabled
      include SimpleForm::Components::Errors
      include SimpleForm::Components::Hints
      include SimpleForm::Components::LabelInput
      include SimpleForm::Components::Maxlength
      include SimpleForm::Components::Placeholders
      include SimpleForm::Components::Required

      attr_reader :attribute_name, :column, :input_type, :reflection,
                  :options, :input_html_options, :input_html_classes

      delegate :template, :object, :object_name, :lookup_model_names, :lookup_action, :to => :@builder

      class_attribute :default_options
      self.default_options = {}

      def self.enable(*keys)
        options = self.default_options.dup
        keys.each { |key| options.delete(key) }
        self.default_options = options
      end

      def self.disable(*keys)
        options = self.default_options.dup
        keys.each { |key| options[key] = false }
        self.default_options = options
      end

      disable :maxlength, :placeholder, :pattern

      def initialize(builder, attribute_name, column, input_type, options = {})
        @builder            = builder
        @attribute_name     = attribute_name
        @column             = column
        @input_type         = input_type
        @reflection         = options.delete(:reflection)
        @options            = self.class.default_options.merge(options)
        @required           = calculate_required

        # Notice that html_options_for receives a reference to input_html_classes.
        # This means that classes added dynamically to input_html_classes will
        # still propagate to input_html_options.
        @input_html_classes = [input_type, required_class, readonly_class].compact
        @input_html_options = html_options_for(:input, input_html_classes).tap do |o|
          o[:readonly]  = true if has_readonly?
          o[:autofocus] = true if has_autofocus?
        end
      end

      def input
        raise NotImplementedError
      end

      def input_options
        options
      end

      def has_autofocus?
        options[:autofocus]
      end

      private

      def add_size!
        input_html_options[:size] ||= [limit, SimpleForm.default_input_size].compact.min
      end

      def limit
        column && column.limit
      end

      # Find reflection name when available, otherwise use attribute
      def reflection_or_attribute_name
        reflection ? reflection.name : attribute_name
      end

      # Retrieve options for the given namespace from the options hash
      def html_options_for(namespace, extra)
        html_options = options[:"#{namespace}_html"] || {}
        html_options[:class] = (extra << html_options[:class]) if extra.present?
        html_options
      end

      # Lookup translations for the given namespace using I18n, based on object name,
      # actual action and attribute name. Lookup priority as follows:
      #
      #   simple_form.{namespace}.{model}.{action}.{attribute}
      #   simple_form.{namespace}.{model}.{attribute}
      #   simple_form.{namespace}.{attribute}
      #
      #  Namespace is used for :labels and :hints.
      #
      #  Model is the actual object name, for a @user object you'll have :user.
      #  Action is the action being rendered, usually :new or :edit.
      #  And attribute is the attribute itself, :name for example.
      #
      #  The lookup for nested attributes is also done in a nested format using
      #  both model and nested object names, such as follow:
      #
      #   simple_form.{namespace}.{model}.{nested}.{action}.{attribute}
      #   simple_form.{namespace}.{model}.{nested}.{attribute}
      #   simple_form.{namespace}.{nested}.{action}.{attribute}
      #   simple_form.{namespace}.{nested}.{attribute}
      #   simple_form.{namespace}.{attribute}
      #
      #  Example:
      #
      #    simple_form:
      #      labels:
      #        user:
      #          new:
      #            email: 'E-mail para efetuar o sign in.'
      #          edit:
      #            email: 'E-mail.'
      #
      #  Take a look at our locale example file.
      def translate(namespace, default='')
        return nil unless SimpleForm.translate

        model_names = lookup_model_names.dup
        lookups     = []

        while !model_names.empty?
          joined_model_names = model_names.join(".")
          model_names.shift

          lookups << :"#{joined_model_names}.#{lookup_action}.#{reflection_or_attribute_name}"
          lookups << :"#{joined_model_names}.#{reflection_or_attribute_name}"
        end
        lookups << :"#{attribute_name}" unless reflection
        lookups << default

        I18n.t(lookups.shift, :scope => :"simple_form.#{namespace}", :default => lookups).presence
      end

    end
  end
end
