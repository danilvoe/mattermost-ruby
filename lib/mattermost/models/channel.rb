class Channel < Base

  def save
    defined?(self.id) ? update : create_channel
  end

  def name 
    @name ||= self.display_name.gsub(" ", '-')
  end

  # Delete a channel
  def delete
    Mattermost.post("/channels/#{self.id}/delete")
  end
  alias_method :destroy, :delete 

  # Get channel info
  def info
    Mattermost.get("/channels/#{self.id}/")
  end

  # Returns posts for the channel _before_ a given post.id 
  # 
  # @param before [string] to get posts before a given post id
  def posts(before = nil)
    uri = "/channels/#{self.id}/posts"
    uri += "/#{before}" if before 
    uri += "/0/60?_=#{Time.now.to_i}"
    request = Mattermost.get("/channels/#{self.id}/posts/0/60?_=#{Time.now.to_i}")
    response = {}
    request.parsed_response['posts'].each do |_, post|
      response[k] = Post.new(post)
    end
    response
  end

  # Get the users in a channel
  def get_channel_extra_info(member_limit = nil)
    uri = "/channels/#{self.id}/extra_info"
    uri += "/#{member_limit}" if member_limit
    request = Mattermost.get(uri)
    response = {}
    response['id'] = request.parsed_response['id']
    response['member_count'] = request.parsed_response['member_count']
    response['members'] = []
    request.parsed_response['members'].each do |user|
      response['members'] << User.new(user)
    end
    response
  end
  alias_method :users, :get_channel_extra_info

  # Join the channel with your authenticated user
  # If you're looking to add a user to a channel, see #add_member
  def join
    Mattermost.post("/channels/#{self.id}/join")
  end

  # Leave the channel with your authenticated user
  # If you're looking to remove a user from a channel, see #remove_member
  def leave
    Mattermost.post("/channels/#{self.id}/leave")
  end

  # Add a user to a channel
  # Send a user object or a user_id
  def add_member(user)
    user_id = user.is_a? User ? user.id : user
    Mattermost.post("/channels/#{self.id}/add", :body => {:user_id => user_id})
  end
  alias_method :add_user, :add_member 

  # Add a user to a channel
  # Send a user object or a user_id
  def remove_member(user)
    user_id = user.is_a? User ? user.id : user
    Mattermost.post("/channels/#{self.id}/remove", :body => {:user_id => user_id})
  end
  alias_method :remove_user, :remove_member 

  def update_last_viewed_at
    Mattermost.post("/channels/#{self.id}/update_last_viewed_at")
  end

  def update_attributes(attributes = {})
    raise NotImplementedError
    Mattermost.post("/channels/update")
  end

  # Update the channel's header. I really hate that they have a specific
  # method for this.
  def update_header(header)
    Mattermost.post("/teams/#{Mattermost.team.id}/channels/#{self.id}/update_header", :body => {:channel_id => self.id, :channel_header => header}.to_json)
  end

  # Update the channel's purpose. I really hate that they have a specific
  # method for this.
  def update_purpose(purpose)
    Mattermost.post("/teams/#{Mattermost.team.id}/channels/#{self.id}/update_purpose", :body => {:channel_id => self.id, :channel_purpose => purpose}.to_json)
  end

  def self.default_attributes
    {:display_name => String, :team_id => String, :type => Integer, :purpose => String}
  end

  protected
  def create_channel
    Mattermost.post("/channels/create", 
      :body => {
        :display_name => self.display_name, 
        :name => self.name,
        :team_id => Mattermost::Team.id,
        :purpose => self.purpose,
        :type => self.type 
        }.to_json)
   end
end