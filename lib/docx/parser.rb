require 'docx/containers'
require 'docx/elements'
require 'nokogiri'
require 'zip'

module Docx
  class Parser
    attr_reader :xml, :doc, :zip
    
    def initialize(path)
      @zip = Zip::File.open(path)
      @xml = @zip.read('word/document.xml')
      @doc = Nokogiri::XML(@xml)
      if block_given?
        yield self
        @zip.close
      end
    end
    
    def paragraphs
      @doc.xpath('//w:document//w:body//w:p').map { |p_node| parse_paragraph_from p_node }
    end

    # Returns hash of bookmarks
    def bookmarks
      bkmrks_hsh = Hash.new
      bkmrks_ary = @doc.xpath('//w:bookmarkStart').map { |b_node| parse_bookmark_from b_node }
      # auto-generated by office 2010
      bkmrks_ary.reject! {|b| b.name == "_GoBack" }
      bkmrks_ary.each {|b| bkmrks_hsh[b.name] = b }
      bkmrks_hsh
    end
    
    private
    
    # generate Elements::Containers::Paragraph from paragraph XML node
    def parse_paragraph_from(p_node)
      Elements::Containers::Paragraph.new(p_node)
    end

    # generate Elements::Bookmark from bookmark XML node
    def parse_bookmark_from(b_node)
      Elements::Bookmark.new(b_node)
    end
  end
end
