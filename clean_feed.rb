#!/usr/bin/ruby
require 'rubygems'
require 'classifier'
require 'nokogiri'
require 'sanitize'
require 'chronic'
require 'rss'

# Set up a decent HTML sanitizer (to purge the feedburner ads)
SANITIZE_CONF = {
  :elements => %w[
    b blockquote br cite code em i li mark ol p pre
    s small strike strong sub sup u ul var
  ],
  :attributes => {
    'blockquote' => ['cite'],
  },
  :protocols => {
    'blockquote' => {'cite' => ['http', 'https', :relative]},
  }
}

# Train the filter. 
b = Classifier::Bayes.new 'moderation', 'noteworthy', 'service-status' 
xml = Nokogiri::XML(open('training.xml'))
xml.search('/root/data').each do |data|
  b.train data.search('category').first.content.to_s, data.search('text').first.content.to_s
end

# Parse the feed and copy it to a new feed.
rj_feed = Nokogiri::Slop(open('http://feeds.feedburner.com/RiftJunkies-RiftDeveloperTrackerFeed').read)
clean_feed = RSS::Maker.make('2.0') do |m|
  m.channel.title = 'Rift Dev Tracker (via RiftJunkies)'
  m.channel.link = 'http://www.riftjunkies.com/dev-tracker/'
  m.channel.description = 'A cleaned-up RiftJunkies devtracker feed. Moderation-related posts (thread cleanup/closure notices) and service status posts should be gone.'

  rj_feed.rss.channel.item.each do |item|
    # For some reason, this attribute isn't available in the sloppy structure.
    # The sanitizing is mainly to remove the stupid feedburner junk.
    desc = Sanitize.clean(item.search('description').first.content, SANITIZE_CONF)

    if ['noteworthy'].include? b.classify(desc).downcase
      i = m.items.new_item
      i.title = item.title.content
      i.link = item.link.content
      i.description = desc 
      i.date = Chronic.parse(item.date.content) # to lazy to use strptime
      i.author = item.dev.content
      
      # wtf ...
      category = RSS::Maker::RSS20::Items::Item::Categories::Category.new nil 
      category.content = item.forum.content
      i.categories << category

    end
  end
end

File.open('current.rss',"w") {|f| f.write(clean_feed) }
