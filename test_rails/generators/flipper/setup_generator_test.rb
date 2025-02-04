require "helper"
require "generators/flipper/setup_generator"

class SetupGeneratorTest < Rails::Generators::TestCase
  tests Flipper::Generators::SetupGenerator
  ROOT = File.expand_path("../../../tmp/generators", __dir__)
  destination ROOT
  setup :prepare_destination

  test "invokes flipper:active_record generator if ActiveRecord adapter defined" do
    begin
      load 'flipper/adapters/active_record.rb'
      run_generator
      assert_migration "db/migrate/create_flipper_tables.rb"
    ensure
      Flipper::Adapters.send(:remove_const, :ActiveRecord)
    end
  end

  test "generates an initializer" do
    run_generator
    assert_file 'config/initializers/flipper.rb', /Flipper\.configure/
  end

  test "does not invoke flipper:active_record generator if ActiveRecord adapter not defined" do
    # Ensure adapter not defined
    Flipper::Adapters.send(:remove_const, :ActiveRecord) rescue nil

    run_generator
    assert_no_migration "db/migrate/create_flipper_tables.rb"
  end

  %w(.env.development .env.local .env).each do |file|
    test "configures Flipper Cloud token in #{file} if it exists" do
      File.write("#{ROOT}/#{file}", "")
      run_generator %w(--token abc123)
      assert_file file, /^FLIPPER_CLOUD_TOKEN=abc123$/m
    end
  end

  test "configures Flipper Cloud token in .env.development before .env" do
    File.write("#{ROOT}/.env.development", "")
    File.write("#{ROOT}/.env", "")

    run_generator %w(--token abc123)
    assert_file ".env.development", /^FLIPPER_CLOUD_TOKEN=abc123$/m
    assert_file ".env", ""
  end

  test "does not write to .env if no token provided" do
    File.write("#{ROOT}/.env", "")
    run_generator
    assert_file ".env", ""
  end

  test "configures Flipper Cloud token in config/credentials.yml.enc if credentials.yml.enc exist" do
    Dir.chdir(ROOT) do
      FileUtils.mkdir_p("config")
      ENV["RAILS_MASTER_KEY"] = "a" * 32
      Rails.application = Class.new(Rails::Application)
      Rails.application.credentials.write("")

      run_generator %w(--token abc123)
      assert_file "config/credentials.yml.enc"
      expected_config = { flipper: { cloud_token: "abc123" } }
      assert_equal expected_config, Rails.application.credentials.config
    end
  end
end
