# This script was pulled from https://gist.github.com/vitobotta/888709
# So full credit goes to vitobotta. Thanks, open source community.
#
# How to run this script:
#
#  $ ruby -r './lib/wordpress' -e 'WordPress::import("wordpress", "homestead", "secret", "wp", "localhost", 3306)'
#
# where:
#  "wordpress" is database name
#  "homestead" is the database username
#  "secret" is the database password
#  "wp" is the table prefix (default "wp")
#  "localhost" is the database host (default "localhost")
#  3306 is the mysql server's tcp port (default 3306)
#
# Before run this script, install dependencies.
#  $ gem install hpricot
#  $ wget https://raw.githubusercontent.com/cousine/downmark_it/master/downmark_it.rb -O ./lib/downmark_it.rb
#

%w(rubygems sequel fileutils yaml active_support/inflector).each{|g| require g}

require File.join(File.dirname(__FILE__), "downmark_it")

module WordPress
  def self.import(database, user, password, table_prefix = 'wp', host = 'localhost', port = 3306)
    db = Sequel.connect(:adapter => 'mysql2', :host => host, :port => port, :database => database, :user => user, :password => password, :encoding => 'utf8')

    %w(_posts _drafts).each{|folder| FileUtils.mkdir_p folder}

    # Get the contents of wp_posts table.
    query = <<-EOS
        SELECT  post_title, post_name, post_date, post_content, post_excerpt, ID, guid, post_status, post_type, post_status,
             (  SELECT  guid
              FROM  #{table_prefix}_posts
              WHERE ID = (  SELECT  meta_value
                    FROM  #{table_prefix}_postmeta
                    WHERE   post_id = post.ID AND meta_key = "_thumbnail_id") ) AS post_image
        FROM #{table_prefix}_posts AS post
        WHERE  post_type = 'post'
    EOS

    # Get the contents of wp_term_taxonomy table.
    categories_and_tags_query = <<-EOS
      SELECT t.taxonomy, term.name, term.slug
        FROM        #{table_prefix}_term_relationships AS tr
        INNER JOIN  #{table_prefix}_term_taxonomy AS t ON t.term_taxonomy_id = tr.term_taxonomy_id
        INNER JOIN  #{table_prefix}_terms AS term ON term.term_id = t.term_id
        WHERE       tr.object_id = %d
        ORDER BY    tr.term_order
    EOS

    # wp_terms.slug and wp_posts.post_name written in Korean are terrible.
    # The following is the pattern to generate correctly formatted slugs on the fly.
    pattern_special_chars = /(?<chars>`|~|!|@|#|\$|%|\^|&|\*|\(|\)|\[|\]|\.|\\|\/|:|;|"|'|,|\.|<|>|\?)/
    pattern_white_spaces  = /(?<spaces>\s+)/

    db[query].each do |post|
      title      = post[:post_title]
      slug       = post[:post_title]
          .downcase.gsub(pattern_special_chars, "").gsub(pattern_white_spaces, "-")
      date       = post[:post_date]
      content    = DownmarkIt.to_markdown post[:post_content]
      status     = post[:post_status]
      name       = "%02d-%02d-%02d-%s.md" % [date.year, date.month, date.day, slug]
      categories = []
      post_tags  = []

      puts title

      db[categories_and_tags_query % post[:ID]].each do |category_or_tag|
        eval(category_or_tag[:taxonomy].pluralize) << category_or_tag[:name]
            .downcase.gsub(pattern_special_chars, "").gsub(pattern_white_spaces, "-")
        # eval(category_or_tag[:taxonomy].pluralize) << {
        #   "title"    => category_or_tag[:name],
        #   "slug"     => category_or_tag[:slug],
        #   "autoslug" => category_or_tag[:name].downcase.gsub(" ", "-")
        # }
      end

      data = {
         'layout'        => 'post',
         'title'         => title.to_s,
         'date'          => date.to_s,
         # 'excerpt'       => post[:post_excerpt].to_s,
         # 'wordpress_id'  => post[:ID],
         # 'wordpress_url' => post[:guid],
         'categories'    => categories,
         'tags'          => post_tags
       }.delete_if { |k,v| v.nil? || v == ''}.to_yaml

      File.open("#{status == 'publish' ? '_posts' : '_drafts'}/#{name}", "w") do |f|
        f.puts data
        f.puts "---"
        f.puts content
      end
    end
  end
end
