# encoding=utf-8

require 'pismo/title_matches'
require 'pismo/description_matches'
require 'pismo/lede_matches'


module Pismo
  # Internal attributes are different pieces of data we can extract from a document's content
  module InternalAttributes
    PHRASIE = Phrasie::Extractor.new

    TITLE_SEPARATORS_REGEX = /\s(\p{Pd}|\:|\p{Pf}|\||\:\:|\.)\s/

    FAVICON_MATCHES = [
      ['link[@rel="fluid-icon"]', lambda { |el| el.attr('href') }],      # Get a Fluid icon if possible..
      ['link[@rel="shortcut icon"]', lambda { |el| el.attr('href') }],
      ['link[@rel="icon"]', lambda { |el| el.attr('href') }]
    ]

    def titles
      if @all_titles.nil?
        title_candidates_from_doc = @doc.match(TITLE_MATCHES) # returns an array
        from_doc_title = nil
        # get title with more words
        title_candidates_from_doc.each do |title|
          from_doc_title = title if from_doc_title.nil?
          from_doc_title = title if from_doc_title.length < title.length
        end

        #in order of likley accuracy: og:title, html_title, document matches
        @all_titles ||= {
          og_title: og_title,
          html_title: html_title,
          from_doc: from_doc_title
        }
      end

      @all_titles
    end

    # Returns the title of the page/content
    def title
      @title ||= Utilities.longest_common_substring_in_array(titles.values) 
      @title = titles[:og_title] unless title_ok?
      @title = titles[:html_title] unless title_ok?
      @title = titles[:from_doc] unless title_ok?

      @title
    end

    private def title_ok?
      !@title.nil? && @title.split(' ').length > 1 
    end

    # title from OG tags, if any
    def og_title
      begin
        meta = doc.css("meta[property~='og:title']")

        meta.each do |item|
          next if item["content"].empty?

          return item["content"]
        end
      rescue
        log "Error getting OG tag: #{$!}"
      end
      nil
    end

    # HTML title
    def html_title
      @html_title ||= begin
        if title = @doc.match('title').first
          strip_site_name_and_separators_from(title)
        else
          nil
        end
      end
    end

    def strip_site_name_and_separators_from(title)
      parts = title.split(TITLE_SEPARATORS_REGEX)
      longest = parts.max_by(&:length)
      return longest
    end

    # Returns the "description" of the page, usually comes from a meta tag
    def descriptions
      @all_descriptions ||= @doc.match DESCRIPTION_MATCHES
    end

    def description
      descriptions.first
    end

    # Returns the "lede(s)" or first paragraph(s) of the story/page
    LEDE_EXTRACTOR = /^(.*?[\.\!\?]\s){1,3}/m
    def ledes
      @all_ledes ||= begin
        matches = @doc.match(LEDE_MATCHES).map do |lede|
          # TODO: Improve sentence extraction - this is dire even if it "works for now"
          case lede
          when String
            (lede[LEDE_EXTRACTOR] || lede).to_s.strip
          when Array
            lede.map { |l| l.to_s[LEDE_EXTRACTOR].strip || l }.uniq
          end
        end

        if matches.empty?
          if reader_doc and all_sentences = reader_doc.sentences(4)
            unless all_sentences.empty?
              matches.push all_sentences.join(' ')
            end
          end
        end

        matches.uniq
      end
    end

    def lede
      ledes.first
    end

    # Returns a string containing the first [limit] sentences as determined by the Reader algorithm
    def sentences(limit = 3)
      reader_doc && !reader_doc.sentences.empty? ? reader_doc.sentences(limit).join(' ') : nil
    end

    # Returns any images with absolute URLs in the document
    def images(limit = 3)
      if @options[:image_extractor]
        extractor = ImageExtractor.new(self, @url, {
          :min_width => @options[:min_image_width],
          :min_height => @options[:min_image_height],
          :logger => @options[:logger]
          })
        extractor.get_best_images limit
      else
        reader_doc && !reader_doc.images.empty? ? reader_doc.images(limit) : nil
      end
    end

    def videos(limit = 1)
      reader_doc && !reader_doc.videos.empty? ? reader_doc.videos(limit) : nil
    end

 # Returns the tags or categories of the page/content
    def tags
      css_selectors = [
                       '.watch-info-tag-list a',  # YouTube
                       '.entry .tags a',          # Livejournal
                       'a[rel~=tag]',             # Wordpress and many others
                       'a.tag',                   # Tumblr
                       '.tags a',
                       '.labels a',
                       '.categories a',
                       '.topics a'
                      ]

      tags = []

      # grab the first one we get results from
      css_selectors.each do |css_selector|
        tags += @doc.css(css_selector)
        break if tags.any?
      end

      # convert from Nokogiri Element objects to strings
      tags.map!(&:inner_text)

      # remove "#" from hashtag-like tags
      tags.map! { |t| t.gsub(/^#/, '') }

      tags
    end

    # Returns the "keyword phrases" in the document (not the meta keywords - they're next to useless now)
    DEFAULT_KEYWORD_OPTIONS = { :limit => 20, :minimum_score => "1%" }
    def keywords(options = {})
      options = DEFAULT_KEYWORD_OPTIONS.merge(options)
      text = [title, description, body].join(" ")
      phrases = PHRASIE.phrases(text, :occur => options[:minimum_score]).map {|phrase, occur, strength| [phrase.downcase, occur] }
      phrases.
        delete_if {|phrase, occur| occur < 2 }.
        sort_by   {|phrase, occur| occur     }.
        reverse.first(options[:limit])
      Hash[phrases]
    end

    def reader_doc
      @reader_doc ||= Reader.create(@doc.to_s, @options)
    end

    # Returns body text as determined by Reader algorithm
    def body
      @body ||= reader_doc.content(true).strip
    end

    # Returns body text as determined by Reader algorithm WITH basic HTML formatting intact
    def html_body
      @html_body ||= reader_doc.content.strip
    end

    # Returns URL to the site's favicon
    def favicon
      @favicon ||= begin
        url = @doc.match(FAVICON_MATCHES).first
        if url and @url and !url.start_with? "http"
          url = URI.join(@url , url).to_s
        end
        url
      end
    end
  end
end
