# Todo:
# flickr.groups.pools.add
# flickr.groups.pools.getContext
# flickr.groups.pools.getGroups
# flickr.groups.pools.getPhotos
# flickr.groups.pools.remove
module Flickr
  class Group
    attr_reader :id, :client, :description, :name, :eighteenplus, :members, :online, :privacy, :url#, :chatid, :chatcount

    def initialize(id_or_params_hash=nil, api_key=nil)
      if id_or_params_hash.is_a?(Hash)
        id_or_params_hash.each { |k,v| self.instance_variable_set("@#{k}", v) } # convert extra_params into instance variables
      else
        @id = id_or_params_hash
        @api_key = api_key      
        @client = Flickr::Api.new @api_key
      end
    end

    # Implements flickr.groups.getInfo and flickr.urls.getGroup
    # private, once we can call it as needed
    def getInfo
      info = @client.groups_getInfo('group_id'=>@id)['group']
      @name = info['name']
      @members = info['members']
      @online = info['online']
      @privacy = info['privacy']
      # @chatid = info['chatid']
      # @chatcount = info['chatcount']
      @url = @client.urls_getGroup('group_id'=>@id)['group']['url']
      self
    end

  end
end
