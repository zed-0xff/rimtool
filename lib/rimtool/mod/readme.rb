# frozen_string_literal: true

module RimTool
  class Mod
    class Readme
      def initialize text, mod
        @text = text
        @mod = mod
      end

      def to_steam
        Redcarpet::Markdown
          .new(RimTool::SteamRenderer, fenced_code_blocks: true, lax_spacing: false)
          .render(File.read("README.md"))
          .strip
          .gsub("\n\n\n", "\n\n")
          .gsub("[/img][/url]\n[url", "[/img][/url] [url") # make "You may also like" images block horizontal
          .gsub("\n\n[olist]", "\n[olist]")                # lists have too big default upper margin# 
          .gsub("\n\n[list]",  "\n[list]")
          .gsub(%r_\[img\]((?!http).+?)\[/img\]_) do |x|
            img_bname = File.basename($1) # "screens/yada6.jpg" -> "yada6.jpg"
            if (steam_img = @mod.yada_details.dig("AdditionalPreviews", "li").find{ |x| x['OriginalFileName'] == img_bname })
              "[img]" + steam_img['URLOrVideoID'] + "[/img]"
            else
              STDERR.puts "[?] img #{img_bname} not found on steam".yellow
              x
            end
          end
      end
    end
  end
end
