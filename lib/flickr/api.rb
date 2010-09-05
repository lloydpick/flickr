module Flickr
  # Flickr client class. Requires an API key
  class Api
    attr_reader :api_key, :auth_token
    attr_accessor :user

    HOST = 'api.flickr.com'
    HOST_URL = 'http://' + HOST
    API_PATH = '/services/rest'

    # To use the Flickr API you need an api key 
    # (see http://www.flickr.com/services/api/misc.api_keys.html), and the flickr 
    # client object shuld be initialized with this. You'll also need a shared
    # secret code if you want to use authentication (e.g. to get a user's
    # private photos)
    # There are two ways to initialize the Flickr client. The preferred way is with
    # a hash of params, e.g. 'api_key' => 'your_api_key', 'shared_secret' => 
    # 'shared_secret_code'. The older (deprecated) way is to pass an ordered series of 
    # arguments. This is provided for continuity only, as several of the arguments
    # are no longer usable ('email', 'password')
    def initialize(api_key_or_params=nil, shared_secret=nil)
      @host = HOST_URL
      @api = API_PATH
      if api_key_or_params.is_a?(Hash)
        @api_key = api_key_or_params['api_key']
        @shared_secret = api_key_or_params['shared_secret']
        @auth_token = api_key_or_params['auth_token']
      else
        @api_key = api_key_or_params
        @shared_secret = shared_secret
      end
    end

    # Gets authentication token given a Flickr frob, which is returned when user
    # allows access to their account for the application with the api_key which
    # made the request
    def get_token_from(frob)
      auth_response = request("auth.getToken", :frob => frob)['auth']
      @auth_token = auth_response['token']
      @user = User.new( 'id' => auth_response['user']['nsid'], 
                        'username' => auth_response['user']['username'],
                        'name' => auth_response['user']['fullname'],
                        'client' => self)
      @auth_token
    end

    # Implements flickr.urls.lookupGroup and flickr.urls.lookupUser
    def find_by_url(url)
      response = urls_lookupUser('url'=>url) rescue urls_lookupGroup('url'=>url) rescue nil
      (response['user']) ? User.new(response['user']['id'], @api_key) : Group.new(response['group']['id'], @api_key) unless response.nil?
    end

    # Implements flickr.photos.getRecent and flickr.photos.search
    def photos(*criteria)
      criteria ? photos_search(*criteria) : recent
    end

    # flickr.photos.getRecent
    # 100 newest photos from everyone
    def recent
      photos_request('photos.getRecent')
    end

    def photos_search(params={})
      photos_request('photos.search', params)
    end
    alias_method :search, :photos_search
    
    # Implements flickr.photos.comments.getList and flickr.photosets.comments.getList
    def comments_for_photo(id)
      comments_request("photos.comments.getList", {"photo_id" => id})
    end
    
    def comments_for_photoset(id)
      comments_request("photosets.comments.getList", {"photoset_id" => id})
    end

    # Gets public photos with a given tag
    def tag(tag)
      photos('tags'=>tag)
    end

    # Implements flickr.people.findByEmail and flickr.people.findByUsername. 
    def users(lookup=nil)
      user = people_findByEmail('find_email'=>lookup)['user'] rescue people_findByUsername('username'=>lookup)['user']
      return User.new("id" => user["nsid"], "username" => user["username"], "client" => self)
    end

    # Implements flickr.groups.search
    def groups(group_name, options={})
      collection = groups_search({"text" => group_name}.merge(options))['groups']['group']
      collection = [collection] if collection.is_a? Hash

      collection.collect { |group| Group.new( "id" => group['nsid'], 
                                              "name" => group['name'], 
                                              "eighteenplus" => group['eighteenplus'],
                                              "client" => self) }
    end

    def photoset(photoset_id)
      Photoset.new(photoset_id, @api_key)
    end

    # Implements flickr.tags.getRelated
    def related_tags(tag)
      tags_getRelated('tag'=>tag)['tags']['tag']
    end

    # Implements flickr.photos.licenses.getInfo
    def licenses
      photos_licenses_getInfo['licenses']['license']
    end

    # Returns url for user to login in to Flickr to authenticate app for a user
    def login_url(perms, extra = nil)
      if extra
        "http://flickr.com/services/auth/?api_key=#{@api_key}&perms=#{perms}&extra=#{extra}&api_sig=#{signature_from('api_key'=>@api_key, 'perms' => perms, 'extra' => extra)}"
      else
        "http://flickr.com/services/auth/?api_key=#{@api_key}&perms=#{perms}&api_sig=#{signature_from('api_key'=>@api_key, 'perms' => perms)}"
      end
    end

    # Implements everything else.
    # Any method not defined explicitly will be passed on to the Flickr API,
    # and return an XmlSimple document. For example, Flickr#test_echo is not 
    # defined, so it will pass the call to the flickr.test.echo method.
    def method_missing(method_id, params={})
      request(method_id.id2name.gsub(/_/, '.'), params)
    end

    # Does an HTTP GET on a given URL and returns the response body
    def http_get(url)
      Net::HTTP.get_response(URI.parse(url)).body.to_s
    end

    # Takes a Flickr API method name and set of parameters; returns an XmlSimple object with the response
    def request(method, params={})
      url = request_url(method, params)
      response = XmlSimple.xml_in(http_get(url), { 'ForceArray' => false })
      raise response['err']['msg'] if response['stat'] != 'ok'
      response
    end

    # acts like request but returns a PhotoCollection (a list of Photo objects)
    def photos_request(method, params={})
      photos = request(method, params)
      PhotoCollection.new(photos, @api_key)
    end
    
    def comments_request(method, params={})
      comments = request(method, params)
      return CommentCollection.new(comments, @api_key)
    end

    # Builds url for Flickr API REST request from given the flickr method name 
    # (exclusing the 'flickr.' that begins each method call) and params (where
    # applicable) which should be supplied as a Hash (e.g 'user_id' => "foo123")
    def request_url(method, params={})
      method = 'flickr.' + method
      url = "#{@host}#{@api}/?api_key=#{@api_key}&method=#{method}"
      params.merge!('api_key' => @api_key, 'method' => method, 'auth_token' => @auth_token)
      signature = signature_from(params) 

      url = "#{@host}#{@api}/?" + params.merge('api_sig' => signature).collect { |k,v| "#{k}=" + CGI::escape(v.to_s) unless v.nil? }.compact.join("&")
    end

    def signature_from(params={})
      return unless @shared_secret # don't bother getting signature if no shared_secret
      request_str = params.reject {|k,v| v.nil?}.collect {|p| "#{p[0].to_s}#{p[1]}"}.sort.join # build key value pairs, sort in alpha order then join them, ignoring those with nil value
      return Digest::MD5.hexdigest("#{@shared_secret}#{request_str}")
    end
  end
end