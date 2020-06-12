require 'helper'

RSpec.describe Flipper::UI::Configuration do
  let(:configuration) { described_class.new }

  describe "#actors" do
    it "has default text" do
      expect(configuration.actors.title).to eq("Actors")
      expect(configuration.actors.description).to eq("Enable actors using the form above.")
    end

    it "can be updated" do
      configuration.actors.title = "Actors Section"
      expect(configuration.actors.title).to eq("Actors Section")
    end
  end

  describe "#groups" do
    it "has default text" do
      expect(configuration.groups.title).to eq("Groups")
      expect(configuration.groups.description).to eq("Enable groups using the form above.")
    end
  end

  describe "#percentage_of_actors" do
    it "has default text" do
      expect(configuration.percentage_of_actors.title).to eq("Percentage of Actors")
      expect(configuration.percentage_of_actors.description).to eq("Percentage of actors functions independently of percentage of time. If you enable 50% of Actors and 25% of Time then the feature will always be enabled for 50% of users and occasionally enabled 25% of the time for everyone.")
    end
  end

  describe "#percentage_of_time" do
    it "has default text" do
      expect(configuration.percentage_of_time.title).to eq("Percentage of Time")
      expect(configuration.percentage_of_time.description).to eq("Percentage of actors functions independently of percentage of time. If you enable 50% of Actors and 25% of Time then the feature will always be enabled for 50% of users and occasionally enabled 25% of the time for everyone.")
    end
  end

  describe "#delete" do
    it "has default text" do
      expect(configuration.delete.title).to eq("Danger Zone")
      expect(configuration.delete.description).to eq("Deleting a feature removes it from the list of features and disables it for everyone.")
    end
  end

  describe "#banner_text" do
    it "has no default" do
      expect(configuration.banner_text).to eq(nil)
    end

    it "can be updated" do
      configuration.banner_text = 'Production Environment'
      expect(configuration.banner_text).to eq('Production Environment')
    end
  end

  describe "#banner_class" do
    it "has default color" do
      expect(configuration.banner_class).to eq('danger')
    end

    it "can be updated" do
      configuration.banner_class = 'info'
      expect(configuration.banner_class).to eq('info')
    end

    it "raises if set to invalid value" do
      expect { configuration.banner_class = :invalid_class }
        .to raise_error(Flipper::InvalidConfigurationValue)
    end
  end

  describe "#application_breadcrumb_href" do
    it "has default value" do
      expect(configuration.application_breadcrumb_href).to eq(nil)
    end

    it "can be updated" do
      configuration.application_breadcrumb_href = 'http://www.myapp.com'
      expect(configuration.application_breadcrumb_href).to eq('http://www.myapp.com')
    end
  end

  describe "#feature_creation_enabled" do
    it "has default value" do
      expect(configuration.feature_creation_enabled).to eq(true)
    end

    it "can be updated" do
      configuration.feature_creation_enabled = false
      expect(configuration.feature_creation_enabled).to eq(false)
    end
  end

  describe "#feature_removal_enabled" do
    it "has default value" do
      expect(configuration.feature_removal_enabled).to eq(true)
    end

    it "can be updated" do
      configuration.feature_removal_enabled = false
      expect(configuration.feature_removal_enabled).to eq(false)
    end
  end

  describe "#fun" do
    it "has default value" do
      expect(configuration.fun).to eq(true)
    end

    it "can be updated" do
      configuration.fun = false
      expect(configuration.fun).to eq(false)
    end
  end

  describe "#descriptions_source" do
    it "has default value" do
      expect(configuration.descriptions_source.call(%w[foo bar])).to eq({})
    end

    context "descriptions source is provided" do
      it "can be updated" do
        configuration.descriptions_source = lambda do |_keys|
          YAML.load_file(FlipperRoot.join('spec/support/descriptions.yml'))
        end
        keys = %w[some_awesome_feature foo]
        result = configuration.descriptions_source.call(keys)
        expected = {
          "some_awesome_feature" => "Awesome feature description",
        }
        expect(result).to eq(expected)
      end
    end
  end
end
