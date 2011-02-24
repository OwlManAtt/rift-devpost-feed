require 'rubygems'
require 'classifier'
require 'sanitize'
require 'rss'
require 'builder'

# Sample data
rss = RSS::Parser.parse(open('sample.rss'), false)
training_data = {
  0 => :moderation,
  1 => :moderation,
  2 => :moderation,
  3 => :moderation,
  4 => :moderation,
  5 => :moderation,
  6 => :noteworthy,
  7 => :noteworthy,
}

b = Classifier::Bayes.new 'moderation', 'noteworthy' 
#training_data.each {|i,category| b.train category.to_s, rss.items[i].description}

xml = ''
builder = Builder::XmlMarkup.new(:target => xml, :indent => 2)
builder.instruct!(:xml, :encoding => "UTF-8")
builder.root do |r| 
  train = training_data.map do |i,category| 
    r.data do |d|
      d.category category.to_s
      d.text Sanitize.clean(rss.items[i].description)
    end
  end
end

File.open('training.xml', 'w') {|f| f.write(xml) }

#puts b.classify rss.items[14].description
