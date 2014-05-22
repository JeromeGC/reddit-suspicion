require 'ruby-progressbar'
require 'yaml'
require 'csv'
require 'obscenity'
require_relative 'classes'

posts = []
images = []
image_ids = []
users = []
usernames = []

puts 'Loading posts.'

CSV.foreach 'submissions.csv' do |row|
	next if row[0].start_with?("#")
	image_ids << row[0].to_i
	usernames << row[12]
	posts << SuspiciousPost.new(row[0], row[1], row[3], row[4], row[5], row[6], row[7], row[8], row[10], row[11], row[12])
	
	# uncomment this line for demo
	 break if posts.length > 1000
end

puts "Number of posts: #{posts.length}"

puts 'Loading comments (this might take around an hour).'
progressbar = ProgressBar.create(:total => posts.length)

posts.each do |post|
  post.load_comments
  progressbar.progress += 1
end

puts 'Loading user info (this might take a few hours, depending on your internet connection).'

usernames.uniq.each do |name|
  users << User.new(name)
end

progressbar = ProgressBar.create(:total => users.length)

users.each do |user|
	user.find_user_info
  posts.each do |post|
    if user.name == post.username
      post.user = user
    end
  end
  progressbar.progress += 1
end

puts 'All info loaded.'
puts 'Scanning comments.'

Obscenity.configure do |config|
  config.blacklist   = 'blacklist.yml'
  config.replacement = :stars
end

progressbar = ProgressBar.create(:total => posts.length)

posts.each do |post|
  if post.comments
    File.open "redditHtmlData/#{post.comments}" do |f|
      post.swear_count += 1 if Obscenity.profane?(f.readline)
    end
  end
  progressbar.progress += 1
end

posts.each do |post|
  post.raise_suspicion
end

image_ids.uniq.each do |id|
  images << Image.new(id)
end

images.each do |img|
  posts.each do |post|
    if post.img_id == img.id
      img.posts << post
    end
  end
  
  img.calculate_suspicion
end

images.sort_by! { |img| -img.suspicion }

images[0..6].each do |img|
  puts img.to_string
end

fname = "output#{Time.now.to_i}.txt"
outf = File.new(fname, 'w')

images.each do |img|
  outf.puts img.to_string
end

outf.close

puts "Done. Full results available in #{fname}."
