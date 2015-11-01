# encoding: utf-8

describe Pismo::Document do
  it "could process an IO/File object" do
    doc = Pismo::Document.new(open(HTML_DIRECTORY + "/rubyinside.html"))
    expect(doc.doc).to be_a(Nokogiri::HTML::Document)
  end

  context "when given very basic Pismo document" do
    let(:doc) do
      Pismo::Document.new(%{<html><body><h1>Hello</h1></body></html>})
    end

    it "should pass sanitization" do
      doc_html = %{<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN" "http://www.w3.org/TR/REC-html40/loose.dtd">\n<html><body><h1>Hello</h1></body></html>\n}
      expect(doc.html).to eq(doc_html)
    end

    it 'should result in a Nokogiri document' do
      expect(doc.doc).to be_a(Nokogiri::HTML::Document)
    end
  end # context basic pismo doc

  context 'when given real world blog post' do
    let(:doc) do
      Pismo::Document.new(open(HTML_DIRECTORY + '/rubyinside.html'))
    end

    let(:title) { "CoffeeScript: A New Language With A Pure Ruby Compiler" }

    it 'should have a title' do
      expect(doc.title).to eq(title)
    end

    it 'provides a title extracted from an og:title meta tag' do
      expect(doc.og_title).to eq(title)
    end

    it 'provides a title extracted from the html title tag, stripped of the site name' do
      expect(doc.html_title).to eq(title)
    end

    it 'strip separators and site names from title strings' do
      site_name = 'RubyInside'
      separators = ['–', '-', ':', '›', '»', '|', '::', '.']
      separators.each do |separator|
        title_with_separator = "#{site_name} #{separator} #{title}"
        stripped_title = doc.strip_site_name_and_separators_from(title_with_separator)
        expect(stripped_title).to eq(title)
      end
    end

    it 'could suggest keywords' do
      keywords = {
        "code" => 4,
        "coffeescript" => 3,
        "compiler" => 2,
        "github" => 2,
        "javascript" => 2,
        "ruby" => 5
      }
      expect(doc.keywords).to eq(keywords)
    end

    context "with relative images" do
      context "all_images option set to true" do
        let(:doc) do
          Pismo::Document.new(open(HTML_DIRECTORY + "/relative_imgs.html"), all_images: true)
        end

        it 'should get relative images' do
          image = '/wp-content/uploads/2010/01/coffeescript.png'
          expect(doc.images).to include(image)
        end
      end # all_images set to true
    end # with relative images

    context 'with videos' do
      let(:doc) do
        Pismo::Document.new(open(HTML_DIRECTORY + '/videos.html'))
      end

      it 'should have the embeded video' do
        videos = doc.videos
        expect(videos.count).to eq(1)
        expect(videos.first['src']).to eq('http://www.youtube.com/v/dBtYXFXa5Ig?fs=1&hl=en_US&rel=0&color1=0xFFFFFF&color2=0xFFFFFF&border=0')
      end
    end # with videos
  end # context basic blog post
end
