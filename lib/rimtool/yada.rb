# frozen_string_literal: true
require 'nokogiri'
require 'nori'

module RimTool
  class YADA # https://github.com/zed-0xff/RW-YADA/

    PORT = CONFIG['yada_port'] || 8192

    class << self
      # query steam details if one or more mods
      def query_ugc_details *mods_or_ids
        ids = mods_or_ids.map{ |x| x.is_a?(Mod) ? x.id : x }
        raise "no ids given" if ids.empty?

        builder = Nokogiri::XML::Builder.new do |xml|
          xml.root("Class" => "zed_0xff.YADA.API.Request_QueryUGCDetailsRequest") {
            xml.ReturnAdditionalPreviews true
            xml.ReturnChildren true
            xml.ReturnKeyValueTags true
            xml.ReturnLongDescription true
            xml.ReturnMetadata true
            xml.ReturnOnlyIDs true
            xml.ReturnTotalOnly true
            xml.PublishedFileIds {
              ids.each do |id|
                xml.li id
              end
            }
          }
        end
        xml = builder.to_xml
        resp = Net::HTTP.post(URI("http://127.0.0.1:#{PORT}/"), xml)
        Nori.new.parse(resp.body)["Response"]
      end

      # update mod description on steam
      def update_item_description! mod
        builder = Nokogiri::XML::Builder.new do |xml|
          xml.root("Class" => "zed_0xff.YADA.API.Request_SetItemDescription") {
            xml.PublishedFileId mod.id
            xml.description mod.readme.to_steam
          }
        end
        xml = builder.to_xml
        resp = Net::HTTP.post(URI("http://127.0.0.1:#{PORT}/"), xml)
        puts resp.body
      end
    end
  end
end
