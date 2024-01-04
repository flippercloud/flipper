require "flipper/cli"

RSpec.describe Flipper::CLI do
  # Infer the command from the description
  subject(:argv) do
    descriptions = self.class.parent_groups.map {|g| g.metadata[:description_args] }.reverse.flatten.drop(1)
    descriptions.map { |arg| arg.split }.flatten
  end

  subject { run argv }

  before do
    ENV["FLIPPER_REQUIRE"] = "./spec/fixtures/environment"
  end


  describe "enable" do
    describe "feature" do
      it do
        expect(subject).to have_attributes(status: 0, stdout: /"feature" is fully enabled/)
        expect(Flipper).to be_enabled(:feature)
      end
    end

    describe "-a User;1 feature" do
      it do
        expect(subject).to have_attributes(status: 0, stdout: /"feature" is enabled for 1 actor/)
        expect(Flipper).to be_enabled(:feature, Flipper::Actor.new("User;1"))
      end
    end

    describe "feature -g admins" do
      it do
        expect(subject).to have_attributes(status: 0, stdout: /"feature" is enabled for 1 group/)
        expect(Flipper.feature('feature').enabled_groups.map(&:name)).to eq([:admins])
      end
    end

    describe "feature -p 30" do
      it do
        expect(subject).to have_attributes(status: 0, stdout: /"feature" is enabled for 30% of actors/)
        expect(Flipper.feature('feature').percentage_of_actors_value).to eq(30)
      end
    end

    describe "feature -t 50" do
      it do
        expect(subject).to have_attributes(status: 0, stdout: /"feature" is enabled for 50% of time/)
        expect(Flipper.feature('feature').percentage_of_time_value).to eq(50)
      end
    end
  end

  describe "disable" do
    describe "feature" do
      before { Flipper.enable :feature }

      it do
        expect(subject).to have_attributes(status: 0, stdout: /"feature" is disabled/)
        expect(Flipper).not_to be_enabled(:feature)
      end
    end

    describe "feature -g admins" do
      before { Flipper.enable_group(:feature, :admins) }

      it do
        expect(subject).to have_attributes(status: 0, stdout: /"feature" is disabled/)
        expect(Flipper.feature('feature').enabled_groups).to be_empty
      end
    end
  end

  describe "list" do
    before do
      Flipper.enable :foo
      Flipper.disable :bar
    end

    it "lists features" do
      expect(subject).to have_attributes(status: 0, stdout: /foo.*fully enabled/)
      expect(subject).to have_attributes(status: 0, stdout: /bar.*disabled/)
    end
  end

  ["-h", "--help", "help"].each do |arg|
    describe arg do
      it { should have_attributes(status: 0, stdout: /Usage: flipper/) }

      it "should list subcommands" do
        %w(enable disable list).each do |subcommand|
          expect(subject.stdout).to match(/#{subcommand}/)
        end
      end
    end
  end

  describe "help enable" do
    it { should have_attributes(status: 0, stdout: /Usage: flipper enable \[options\] <feature>/) }
  end

  describe "nope" do
    it { should have_attributes(status: 1, stderr: /Unknown command: nope/) }
  end

  describe "show foo" do
    before { Flipper.enable :foo }

      it { should have_attributes(status: 0, stdout: /foo.*fully enabled/) }
  end

  def run(argv)
    original_stdout = $stdout
    original_stderr = $stderr

    $stdout = StringIO.new
    $stderr = StringIO.new
    status = 0

    begin
      Flipper::CLI.run(argv)
    rescue SystemExit => e
      status = e.status
    end

    OpenStruct.new(status: status, stdout: $stdout.string, stderr: $stderr.string)
  ensure
    $stdout = original_stdout
    $stderr = original_stderr
  end
end
