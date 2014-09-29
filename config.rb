# --- GENERAL SETTINGS ---------------------------------------------------------

Time.zone = 'London'

# Asset paths
set :css_dir, 'css'
set :js_dir, 'js'
set :images_dir, 'img'

activate :syntax, :line_numbers => true

# --- COMPASS SETTINGS ---------------------------------------------------------

compass_config do |config|
  config.output_style = :compact
end

# --- BLOG SETTINGS ------------------------------------------------------------

activate :blog do |blog|
  blog.paginate = true
  blog.layout = 'article_layout'
  blog.tag_template = 'blog/tag.html'
  
  blog.sources = 'blog/{year}-{month}-{day}-{title}.html'
  blog.permalink = 'blog/{year}/{month}/{day}/{title}.html'
end

# --- GOOGLE ANALYTICS ---------------------------------------------------------

activate :google_analytics do |ga|
  ga.tracking_id = 'UA-53730825-1' # Replace with your property ID.
end

# --- SITEMAPS -----------------------------------------------------------------

activate :search_engine_sitemap

# --- TEMPLATE HELPER METHODS --------------------------------------------------

helpers do
  # Output a css class if the given regex matches
  def if_path(regex, classes = 'pure-menu-selected')
    regex =~ current_page.url ? classes : ''
  end

  # Output a 'list' of tag links
  def tag_link_list(current_article)
    tags = current_article.tags
    links = tags.inject([]) do |result, tag|
      result << "#{link_to(tag, tag_path(tag))}"
    end

    links.join(' &middot; ')
  end

  # Format dates how I want them
  def format_date(date)
    date.strftime("%d %B %Y")
  end
end

# --- DEVELOPMENT AND BUILD SETTINGS -------------------------------------------

# Pretty URLs (must be activated _after_ other extension)
activate :directory_indexes

configure :development do
  # Reload the browser automatically whenever files change
  activate :livereload
  # Do not concat/minify assets, load each one on its own.
  set :debug_assets, true

  activate :disqus do |d|
    d.shortname = 'staging-float64'
  end
end

configure :build do
  activate :minify_css

  activate :disqus do |d|
    d.shortname = 'float64'
  end

  # activate :minify_javascript
  # activate :asset_hash # (cache buster)
  # activate :relative_assets
end

#after_build do
#  system('htmlbeautifier build/*/*.html')
#  system(%q{find build/ -name '*.html' -exec htmlbeautifier '{}' +})
#end

# --- DEPLOYMENT ---------------------------------------------------------------

activate :deploy do |deploy|
  deploy.build_before = true
  deploy.method       = :rsync
  deploy.host         = 'float64.uk'
  deploy.path         = '/srv/vhost/float64.uk'
  deploy.clean        = true
end
