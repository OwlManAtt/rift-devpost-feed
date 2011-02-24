#!/usr/bin/ruby
require 'rubygems'
require 'classifier'
require 'nokogiri'
require 'rss'

# Sample data
b = Classifier::Bayes.new 'moderation', 'noteworthy' 
xml = Nokogiri::XML(open('training.xml'))
xml.search('/root/data').each do |data|
  b.train data.search('category').first.content, data.search('text').first.content
end

rj_feed = RSS::Parser.parse(open('http://feeds.feedburner.com/RiftJunkies-RiftDeveloperTrackerFeed'), false)
clean_feed = RSS::Maker.make('2.0') do |m|
  m.channel.title = 'Rift Dev Tracker (via RiftJunkies)'
  m.channel.link = 'http://www.riftjunkies.com/dev-tracker/'
  m.channel.description = 'A cleaned-up RiftJunkies devtracker feed. Moderation-related posts (thread cleanup/closure notices) should be gone.'

  rj_feed.items.each do |item|
    unless b.classify(item.description) == 'moderation'
      i = m.items.new_item
      i.title = item.title
      i.link = item.link
      i.description = item.description
      i.date = item.date    
    end
  end
end

File.open('current.rss',"w") {|f| f.write(clean_feed) }
