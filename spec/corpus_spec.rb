describe "Corpus test" do
  context "corpus of HTML documents" do
    let(:corpus) do
      corpus = {}
      Dir[HTML_DIRECTORY + "/*.html"].each do |filename|
        corpus[File.basename(filename).sub(/\.html$/, '').to_sym] = File.read(filename)
      end
      corpus
    end

    let(:metadata) do
      YAML.load(open(HTML_DIRECTORY + "/metadata_expected.yaml"))
    end

    let(:reader_metadata) do
      YAML.load(open(HTML_DIRECTORY + "/reader_expected.yaml"))
    end

    let(:readers) do
      readers = {}
      Dir[HTML_DIRECTORY + "/readers/*_expected.txt"].each do |filename|
        expected_file_name = File.basename(filename).sub('_expected.txt', '')
        readers[expected_file_name.to_sym] = File.read(filename)
      end
      readers
    end

    it "passes basic sanitization and result in Nokogiri documents" do
      corpus.values.each do |html|
        doc = Pismo::Document.new(html)
        expect(doc.html.length).to be > 1000
        expect(doc.doc).to be_a(Nokogiri::HTML::Document)
      end
    end

    it 'passes metadata extraction tests' do
      metadata.each do |file, expected|
        doc = Pismo::Document.new(corpus[file])
        expected.each do |k, v|
          expected_value = v
          expect(doc.send(k)).to eq(expected_value)
        end
      end
    end

    it 'passes base reader content extraction tests' do
      reader_metadata.each do |file, expected|
        doc = Pismo::Reader.create(corpus[file])
        expect(doc.sentences(2)).to eq(expected)
      end
    end

    it 'passes reader content extraction tests' do 
      readers.each do |reader, expected|
        doc = Pismo::Document.new(corpus[reader], reader: reader)
        expect(doc.body[0..1000]).to eq(expected[0..1000])
      end
    end
  end
end
