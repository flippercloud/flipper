# Requires the following methods
# subject
# read_key(key)
# write_key(key, value)
shared_examples_for 'a flipper adapter' do
  describe "#write" do
    let(:separator)  { Flipper::Gate::Separator }

    it "sets key to value in store" do
      subject.write('foo', true)
      read_key('foo').should be_true
    end

    it "works with separator" do
      subject.write("foo#{separator}bar", true)
      read_key("foo#{separator}bar").should be_true
    end
  end

  describe "#read" do
    it "returns nil if key not in store" do
      subject.read('foo').should be_nil
    end

    it "returns value if key in store" do
      write_key 'foo', 'bar'
      subject.read('foo').should eq('bar')
    end
  end

  describe "#delete" do
    it "deletes key" do
      write_key 'foo', 'bar'
      subject.delete('foo')
      read_key('foo').should be_nil
    end
  end

  describe "#set_add" do
    it "adds value to store" do
      subject.set_add('foo', 1)
      read_key('foo').should eq(Set[1])
    end

    it "does not add same value more than once" do
      subject.set_add('foo', 1)
      subject.set_add('foo', 1)
      subject.set_add('foo', 1)
      subject.set_add('foo', 2)
      read_key('foo').should eq(Set[1, 2])
    end
  end

  describe "#set_delete" do
    it "removes value from set if key in store" do
      write_key 'foo', Set[1, 2]
      subject.set_delete('foo', 1)
      read_key('foo').should eq(Set[2])
    end

    it "works fine if key not in store" do
      subject.set_delete('foo', 'bar')
    end
  end

  describe "#set_members" do
    it "defaults to empty set" do
      subject.set_members('foo').should eq(Set.new)
    end

    it "returns set if in store" do
      write_key 'foo', Set[1, 2]
      subject.set_members('foo').should eq(Set[1, 2])
    end
  end
end
