RSpec.describe 'README' do
  # rubydoc.info renders the README from the gem, which doesn't package docs/ or
  # examples/, so relative targets 404 there. In-page anchors are fine.
  it 'uses absolute urls for images and links' do
    readme = File.read(File.expand_path('../../README.md', __dir__))
    targets = readme.scan(/\]\(([^)\s]+)\)/).flatten

    expect(targets).not_to be_empty
    expect(targets.reject { |target| target.start_with?('http://', 'https://', '#') }).to eq([])
  end
end
