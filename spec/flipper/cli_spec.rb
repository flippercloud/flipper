require "flipper/cli"

RSpec.describe Flipper::CLI do
  let(:stdout) { StringIO.new }
  let(:stderr) { StringIO.new }
  let(:cli) { Flipper::CLI.new(stdout: stdout, stderr: stderr) }

  Result = Struct.new(:status, :stdout, :stderr, keyword_init: true)

  before do
    # Prentend stdout/stderr a TTY to test colorization
    allow(stdout).to receive(:tty?).and_return(true)
    allow(stderr).to receive(:tty?).and_return(true)
  end

  # Infer the command from the description
  let(:argv) do
    descriptions = self.class.parent_groups.map {|g| g.metadata[:description_args] }.reverse.flatten.drop(1)
    descriptions.map { |arg| Shellwords.split(arg) }.flatten
  end

  subject do
    status = 0

    begin
      cli.run(argv)
    rescue SystemExit => e
      status = e.status
    end

    Result.new(status: status, stdout: stdout.string, stderr: stderr.string)
  end

  before do
    ENV["FLIPPER_REQUIRE"] = "./spec/fixtures/environment"
  end

  describe "enable" do
    describe "feature" do
      it do
        expect(subject).to have_attributes(status: 0, stdout: /feature.*\e\[32m.*enabled/)
        expect(Flipper).to be_enabled(:feature)
      end
    end

    describe "-a User;1 feature" do
      it do
        expect(subject).to have_attributes(status: 0, stdout: /feature.*\e\[33m.*enabled.*User;1/m)
        expect(Flipper).to be_enabled(:feature, Flipper::Actor.new("User;1"))
      end
    end

    describe "feature -g admins" do
      it do
        expect(subject).to have_attributes(status: 0, stdout: /feature.*enabled.*admins/m)
        expect(Flipper.feature('feature').enabled_groups.map(&:name)).to eq([:admins])
      end
    end

    describe "feature -p 30" do
      it do
        expect(subject).to have_attributes(status: 0, stdout: /feature.*enabled.*30% of actors/m)
        expect(Flipper.feature('feature').percentage_of_actors_value).to eq(30)
      end
    end

    describe "feature -t 50" do
      it do
        expect(subject).to have_attributes(status: 0, stdout: /feature.*enabled.*50% of time/m)
        expect(Flipper.feature('feature').percentage_of_time_value).to eq(50)
      end
    end

    describe %|feature -x '{"Equal":[{"Property":"flipper_id"},"User;1"]}'| do
      it do
        expect(subject).to have_attributes(status: 0, stdout: /feature.*enabled.*User;1/m)
        expect(Flipper.feature('feature').expression.value).to eq({ "Equal" => [ { "Property" => ["flipper_id"] }, "User;1" ] })
      end
    end

    describe %|feature -x invalid_json| do
      it do
        expect(subject).to have_attributes(status: 1, stderr: /JSON parse error/m)
      end
    end

    describe %|feature -x '{}'| do
      it do
        expect(subject).to have_attributes(status: 1, stderr: /Invalid expression/m)
      end
    end
  end

  describe "disable" do
    describe "feature" do
      before { Flipper.enable :feature }

      it do
        expect(subject).to have_attributes(status: 0, stdout: /feature.*disabled/)
        expect(Flipper).not_to be_enabled(:feature)
      end
    end

    describe "feature -g admins" do
      before { Flipper.enable_group(:feature, :admins) }

      it do
        expect(subject).to have_attributes(status: 0, stdout: /feature.*disabled/)
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
      expect(subject).to have_attributes(status: 0, stdout: /foo.*enabled/)
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

  describe "--nope" do
    it { should have_attributes(status: 1, stderr: /invalid option: --nope/) }
  end

  describe "show foo" do
    context "boolean" do
      before { Flipper.enable :foo }
      it { should have_attributes(status: 0, stdout: /foo.*enabled/) }
    end

    context "actors" do
      before { Flipper.enable_actor :foo, Flipper::Actor.new("User;1") }
      it { should have_attributes(status: 0, stdout: /User;1/) }
    end

    context "groups" do
      before { Flipper.enable_group :foo, :admins }
      it { should have_attributes(status: 0, stdout: /enabled.*admins/m) }
    end
  end
end
