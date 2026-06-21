require 'feedjira'
require 'httparty'
require 'jekyll'

module ExternalPosts
  class ExternalPostsGenerator < Jekyll::Generator
    safe true
    priority :high

    def generate(site)
      if site.config['external_sources'] != nil
        # ponytail: cross-posts share a title -> first source wins as the main
        # entry; later sources with the same slug become "alt_sources" links.
        docs_by_slug = {}
        site.config['external_sources'].each do |src|
          p "Fetching external posts from #{src['name']}:"
          xml = HTTParty.get(src['rss_url']).body
          feed = Feedjira.parse(xml)
          feed.entries.each do |e|
            p "...fetching #{e.url}"
            slug = e.title.downcase.strip.gsub(' ', '-').gsub(/[^\w-]/, '')
            if docs_by_slug.key?(slug)
              existing = docs_by_slug[slug]
              existing.data['alt_sources'] ||= []
              existing.data['alt_sources'] << { 'name' => src['name'], 'url' => e.url }
              next
            end
            path = site.in_source_dir("_posts/#{slug}.md")
            doc = Jekyll::Document.new(
              path, { :site => site, :collection => site.collections['posts'] }
            )
            doc.data['external_source'] = src['name'];
            doc.data['feed_content'] = e.content;
            doc.data['title'] = "#{e.title}";
            doc.data['description'] = e.summary;
            doc.data['date'] = e.published;
            doc.data['redirect'] = e.url;
            site.collections['posts'].docs << doc
            docs_by_slug[slug] = doc
          end
        end
      end
    end
  end

end
