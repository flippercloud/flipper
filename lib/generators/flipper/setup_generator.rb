require 'rails/generators/active_record'

module Flipper
  module Generators
    class SetupGenerator < ::Rails::Generators::Base
      desc 'Peform any necessary steps to install Flipper'
      source_paths << File.expand_path('templates', __dir__)

      class_option :token, type: :string, default: nil, aliases: '-t',
        desc: "Your personal environment token for Flipper Cloud"

      def generate_initializer
        template 'initializer.rb', 'config/initializers/flipper.rb'
      end

      def generate_active_record
        invoke 'flipper:active_record' if defined?(Flipper::Adapters::ActiveRecord)
      end

      def configure_cloud_token
        return unless options[:token]

        configure_with_dotenv || configure_with_credentials
      end

      private

      def configure_with_dotenv
        ['.env.development', '.env.local', '.env'].detect do |file|
          next unless exists?(file)
          append_to_file file, "\nFLIPPER_CLOUD_TOKEN=#{options[:token]}\n"
        end
      end

      def configure_with_credentials
        return unless exists?("config/credentials.yml.enc") && (ENV["RAILS_MASTER_KEY"] || exists?("config/master.key"))

        content = "flipper:\n  cloud_token: #{options[:token]}\n"
        action InjectIntoEncryptedFile.new(self, Rails.application.credentials, content, after: /\z/)
      end

      # Check if a file exists in the destination root
      def exists?(path)
        File.exist?(File.expand_path(path, destination_root))
      end

      # Action to inject content into ActiveSupport::EncryptedFile
      class InjectIntoEncryptedFile < Thor::Actions::InjectIntoFile
        def initialize(base, encrypted_file, data, config)
          @encrypted_file = encrypted_file
          super(base, encrypted_file.content_path, data, config)
        end

        def content
          @content ||= @encrypted_file.read
        end

        def replace!(regexp, string, force)
          if force || !replacement_present?
            success = content.gsub!(regexp, string)
            @encrypted_file.write content unless pretend?
            success
          end
        end
      end
    end
  end
end
