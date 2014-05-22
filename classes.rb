require 'open-uri'

class Image
  attr_accessor :id, :posts, :suspicion
  
  def initialize(id)
    @id = id
    @suspicion = 0
    @posts = []
  end
  
  def calculate_suspicion
    @posts.each do |post|
      @suspicion += post.suspicion
    end
    
    @posts.sort_by! { |post| -post.suspicion }
  end
  
  def to_string
    str = "------------------------------------------------------------------------------\n"
    str += "Image ID: #{id}\nSuspicion: #{suspicion}\nNumber of posts: #{posts.length}\n\n"
    @posts.each do |post|
      str += "#{post.to_string}\n\n"
    end
    str
  end
end

class SuspiciousPost
	attr_accessor :img_id, :unixtime, :tot_votes, :upvotes, :downvotes, :score, :nb_comments, :suspicion, :swear_count
	attr_accessor :title, :reddit_id, :subreddit, :username, :comments, :user

	def initialize(img_id, unixtime, title, tot_votes, reddit_id, upvotes, subreddit, downvotes, score, nbcomments, username)
		@img_id = img_id.to_i
		@unixtime = unixtime.to_i
		@tot_votes = tot_votes.to_i
		@upvotes = upvotes.to_i
		@downvotes = downvotes.to_i
		@score = score.to_i
		@nb_comments = nb_comments.to_i

		@title = title
		@reddit_id = reddit_id
		@subreddit = subreddit
		@username = username || ""

    @swear_count = 0
		@suspicion = 0
	end

  def load_comments
    if @reddit_id
      Dir.foreach('redditHtmlData').each do |f|
        if f.include?(@reddit_id)
          @comments = f
          break
        end
      end
    end
  end
  
  def raise_suspicion
    if @user.creation_date != 0
      # number of months between account creation and post
      @suspicion -= (@unixtime - @user.creation_date.to_i) / 2592000
    end
    if @username == ""
      @suspicion += 20
    end
    @suspicion -= @score
    @suspicion -= @user.karma
    @suspicion += @downvotes * 10 / @tot_votes
    @suspicion += @swear_count
  end

	def to_string
		"Reddit id: #{reddit_id}\nTitle: #{title}\nTime: #{Time.at(unixtime)}\nSubreddit: #{subreddit}\nUsername: #{username}\nTotal votes: #{tot_votes}\nUpvotes: #{upvotes}\nDownvotes: #{downvotes}\nScore: #{score}\nNumber of comments: #{nb_comments}\nNumber of swear words in comments: #{swear_count}\nSuspicion: #{suspicion}"
	end
end

class User
	attr_accessor :name, :karma, :creation_date

	def initialize(name)
		@name = name || ""
		@karma = 0
		@creation_date = 0
	end

	def find_user_info
		unless @name == ""
			begin
				open("http://www.reddit.com/user/" + @name) do |page|
					m = /comment-karma">(\d+)<.+datetime="(.{25})/.match(page.read)
					if m
						if m[1]
							@karma = m[1].to_i
						else
							@karma = 0
						end
						if m[2]
							@creation_date = Time.new(m[2][0, 4].to_i, m[2][5, 6].to_i, m[2][8, 9].to_i, m[2][11, 12].to_i, m[2][14, 15].to_i, m[2][17, 18].to_i, m[19, 24])
						else
							@creation_date = 0
						end
					end
				end
				return
			rescue OpenURI::HTTPError => e
				# Do nothing if page not found
			end
		end

		@karma = 0
		@creation_date = 0
	end
end