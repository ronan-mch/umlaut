# A Rails view helper module, which over-rides #url_for and some other
# rails url-generating methods, so that they can be forced to generate
# absolute URLs if a controller iVar is set to say so. 
#
# This is used by our partial HTML api responses, so make sure html snippets
# have absolute URLs in them. 

module Umlaut::UrlGeneration
  
  # Over-ride to allow default forcing of urls with hostnames.
  # This is neccesary for our partial_html_sections service
  # to work properly. Just set @generate_url_with_host = true
  # in your controller, and urls will be generated with hostnames
  # for the remainder of that action. 
  def url_for(argument = {})
    argument = add_locale(argument)
    if @generate_urls_with_host
      case argument
      when Hash
        # Force only_path = false if not already set
        argument[:only_path] = false if argument[:only_path].nil?
        return super(argument)
      when String
        # We already have a straight string, if it looks relative,
        # absolutize it. 
        if argument.starts_with?("/")
          return root_url.chomp("/") + argument
        else
          return super(argument)
        end
      when :back
        return super(argument)
      else
        # polymorphic, we want to force polymorphic_url instead
        # of default polymorphic_path         
        return polymorphic_url(argument)
      end    
    else
      # @generate_urls_with_host not set, just super
      super(argument)
    end    
  end

  # We don't know what datatype argument is
  # so we need to add the locale in a special way
  def add_locale(argument)
    Rails.logger.debug "argument is #{argument.inspect}"
    locale = I18n.locale.to_s
    case argument
      when Hash
        argument[:locale] = locale
      when String
        argument.include? '?' ? argument += '&': argument += '?'
        argument += "locale=#{locale}"
    end
    argument
  end

  # over-ride path_to_image to generate complete urls with hostname and everything
  # if @generate_url_with_host is set. This makes image_tag generate
  # src with full url with host. See #url_for
  def path_to_image(source)
    path = super(source)
    if @generate_urls_with_host
      protocol =  request.protocol()
      path = protocol + request.host_with_port() + path
    end
    return path
  end
  # Rails2 uses 'path_to_image' instead, that's what we have to override,
  # we used to use image_path, so let's alias that too. 
  alias :image_path :path_to_image

  
  # We want stylesheets and javascripts to do the exact same thing,
  # magic of polymorphous super() makes it work:
  def path_to_stylesheet(source)
    path = super
    if @generate_urls_with_host    
      path = request.protocol() + request.host_with_port() + path
    end
    return path
  end

  def path_to_javascript(source)
    path = super
    if @generate_urls_with_host    
      path = request.protocol() + request.host_with_port() + path
    end
    return path
  end  

end
