require 'pp'
require 'erubis'
require 'digest/md5'

module Sprinkle::Package
  module Rendering
    extend ActiveSupport::Concern

    included do
      self.send :include, Helpers
    end

    def template(src, context=binding)
      eruby = Erubis::Eruby.new(src)
      output = eruby.result(context)
    rescue Object => e
      raise Sprinkle::Errors::TemplateError.new(e, src, context)
    end
    
    def render(filename, context=binding)
      contents=File.read(expand_filename(filename))
      template(contents, context)
    end
    
    # Helper methods can be called from inside your package and 
    # verification code
    module Helpers
      # return the md5 of a string (as a hex string)
      def md5(s)
        Digest::MD5.hexdigest(s)
      end
    end
    
    private 
    
    def search_paths(n)
      return [n] if File.exist?(n)
      p = []
      package_dir = File.dirname(caller[2].split(":").first)
      # if ./ is used assume the path is relative to the package
      return [package_dir] if n =~ %r{./}
      p << File.join(cwd,"templates")
      p << File.expand_path("./templates")
      p.uniq
    end
    
    def expand_filename(n) #:nodoc:
      name = n
      paths = search_paths(n).map do |p| 
        [File.join(p,name),File.join(p,"#{name}.erb")]
      end.flatten
      paths.each do |f|
        return f if File.exist?(f)
      end
      puts "RESOLVED SEARCH PATHS"
      pp paths
      raise "template not found: #{n}"
    end

  end
end