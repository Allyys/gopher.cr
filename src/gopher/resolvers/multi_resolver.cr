module Gopher
  class MultiResolver < Resolver
    getter routes
    private getter host, port

    @routes : Array(Route)

    def initialize(@host : String, @port : String, @relative_root : String = "")
      @routes = [] of Route
    end

    def add_resolver(path : String, resolver : Resolver, description : String = path)
      @routes << Route.new(path: path, resolver: resolver, description: description)
      self
    end

    def menu_entry_type
      MenuEntryType::Submenu
    end

    def resolve(req : RequestBody)
      if req.root?
        entries = routes.map do |route|
          resolver = route.resolver

          MenuEntry.new(entry_type: resolver.menu_entry_type, description: route.description, selector: route.path, host: host, port: port)
        end

        return Response.ok(Menu.new(entries))
      end

      last_result = nil

      debug "Selector is", req.relative_selector
      route = routes.find {|route| route.match req.relative_selector }

      if route.nil?
        return Response.error("Nothing was found that matched #{req.selector}")
      end

      new_request_body = RequestBody.new(req.relative_selector.lchop(route.path))
      
      result = route.resolver.resolve(new_request_body)
    end
  end
end
