# Todo:
# logged_in?
# if logged in:
# flickr.blogs.getList
# flickr.favorites.add
# flickr.favorites.remove
# flickr.groups.browse
# flickr.photos.getCounts
# flickr.photos.getNotInSet
# flickr.photos.getUntagged
# flickr.photosets.create
# flickr.photosets.orderSets
# flickr.test.login
# uploading
module Flickr
  class User
    attr_reader :client, :id, :name, :location, :photos_url, :url, :count, :firstdate, :firstdatetaken

    # A Flickr::User can be instantiated in two ways. The old (deprecated) 
    # method is with an ordered series of values. The new method is with a 
    # params Hash, which is easier when a variable number of params are 
    # supplied, which is the case here, and also avoids having to constantly
    # supply nil values for the email and password, which are now irrelevant
    # as authentication is no longer done this way. 
    # An associated flickr client will also be generated if an api key is 
    # passed among the arguments or in the params hash. Alternatively, and
    # most likely, an existing client object may be passed in the params hash 
    # (e.g. 'client' => some_existing_flickr_client_object), and this is
    # what happends when users are initlialized as the result of a method 
    # called on the flickr client (e.g. flickr.users)
    def initialize(id_or_params_hash=nil, username=nil, email=nil, password=nil, api_key=nil)
      if id_or_params_hash.is_a?(Hash)
        id_or_params_hash.each { |k,v| self.instance_variable_set("@#{k}", v) } # convert extra_params into instance variables
      else
        @id = id_or_params_hash
        @username = username
        @email = email
        @password = password
        @api_key = api_key
      end
      @client ||= Flickr::Api.new('api_key' => @api_key, 'shared_secret' => @shared_secret, 'auth_token' => @auth_token) if @api_key
      @client.login(@email, @password) if @email and @password # this is now irrelevant as Flickr API no longer supports authentication this way
    end

    def username
      @username.nil? ? getInfo.username : @username
    end
    def name
      @name.nil? ? getInfo.name : @name
    end
    def location
      @location.nil? ? getInfo.location : @location
    end
    def count
      @count.nil? ? getInfo.count : @count
    end
    def firstdate
      @firstdate.nil? ? getInfo.firstdate : @firstdate
    end
    def firstdatetaken
      @firstdatetaken.nil? ? getInfo.firstdatetaken : @firstdatetaken
    end

    def photos_url
      @photos_url || getInfo.photos_url
    end

    # Builds url for user's profile page as per 
    # http://www.flickr.com/services/api/misc.urls.html
    def url
      "http://www.flickr.com/people/#{id}/"
    end

    def pretty_url
      @pretty_url ||= @client.urls_getUserProfile('user_id'=>@id)['user']['url']
    end

    # Implements flickr.people.getPublicGroups
    def groups
      collection = @client.people_getPublicGroups('user_id'=>@id)['groups']['group']
      collection = [collection] if collection.is_a? Hash
      collection.collect { |group| Group.new( "id" => group['nsid'], 
                                           "name" => group['name'],
                                           "eighteenplus" => group['eighteenplus'],
                                           "client" => @client) }
    end

    # Implements flickr.people.getPublicPhotos. Options hash allows you to add
    # extra restrictions as per flickr.people.getPublicPhotos docs, e.g. 
    # user.photos('per_page' => '25', 'extras' => 'date_taken')
    def photos(options={})
      @client.photos_request('people.getPublicPhotos', {'user_id' => @id}.merge(options))
      # what about non-public photos?
    end

    # Gets photos with a given tag
    def tag(tag)
      @client.photos('user_id'=>@id, 'tags'=>tag)
    end

    # Implements flickr.contacts.getPublicList and flickr.contacts.getList
    def contacts
      @client.contacts_getPublicList('user_id'=>@id)['contacts']['contact'].collect { |contact| User.new(contact['nsid'], contact['username'], nil, nil, @api_key) }
      #or
    end

    # Implements flickr.favorites.getPublicList
    def favorites
      @client.photos_request('favorites.getPublicList', 'user_id' => @id)
    end

    # Implements flickr.photosets.getList
    def photosets
      @client.photosets_getList('user_id'=>@id)['photosets']['photoset'].collect { |photoset| Photoset.new(photoset['id'], @api_key) }
    end

    # Implements flickr.tags.getListUser
    def tags
      @client.tags_getListUser('user_id'=>@id)['who']['tags']['tag'].collect { |tag| tag }
    end

  	# Implements flickr.tags.getListUserPopular
  	def popular_tags(count = 10)
  		@client.tags_getListUserPopular('user_id'=>@id, 'count'=> count)['who']['tags']['tag'].each { |tag_score| tag_score["tag"] = tag_score.delete("content") }
  	end

    # Implements flickr.photos.getContactsPublicPhotos and flickr.photos.getContactsPhotos
    def contactsPhotos
      @client.photos_request('photos.getContactsPublicPhotos', 'user_id' => @id)
    end

    def to_s
      @name
    end

    private
    # Implements flickr.people.getInfo, flickr.urls.getUserPhotos, and flickr.urls.getUserProfile
    def getInfo
      unless @info
        @info = @client.people_getInfo('user_id'=>@id)['person']
        @username = @info['username']
        @name = @info['realname']
        @location = @info['location']
        @photos_url = @info['photosurl']
        @count = @info['photos']['count']
        @firstdate = @info['photos']['firstdate']
        @firstdatetaken = @info['photos']['firstdatetaken']
      end
      self
    end
  end
end