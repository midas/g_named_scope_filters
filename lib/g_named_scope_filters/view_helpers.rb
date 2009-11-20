module GNamedScopeFilters
  module ViewHelpers
    
    # Guilded component.  This is an unordered list of filters that use named scopes within an ActiveRecord model
    # to filter a list.  It is not tied to a table or list specifically as it simply manipulates the url, resulting 
    # in a manipulation of a list or table.
    # 
    # === Parameters
    # :ar_obj_col_or_class:: The ActiveRecord object, collection or class to make the filters from.  Warning:
    #   if you use anything but the class and the collection or object comes up nil or empty, then you will 
    #   not have filters renderred.  The prefferred way is to use the class unless you cannot due to dynamic reasons.
    #   
    # === Options
    # +id+ - (Required) This will be the id of the ul returned that wraps the filters.
    # +class+ - This will be the id of the ul returned that wraps the filters.  Defaults to 'filters.'
    # +selected_class+ - This will be the class that is used to show whih filter is selected.  Defaults to 'selected.'
    # +only+ - This is the filters to include.  Can be an array or string (for one filter).
    # +include_count+ - True if you would like a span created within each filter list item containg the count for
    #   items in that filter.
    # +record_counts+ - A hash providing teh counts for each filter to override the built in counting funcitonality.
    # +include_all+ - True if you want the all filter to be renderred, otherwise false.  Defaults to true.
    # +all_label+ - The text to use for the All filter's label.  Defaults to 'All.'
    # +all_param+ - The param to pass for the all filter.  Set to :none or false for no filter parameter added to URL 
    #   when all selected.  Defaults to false.
    # +filter_param_key+ - The key for the filter param.  Defaults to 'filter.'  ie. &filter=something
    # +scoped_by+ - This is the ActiveRecord object that this list is scoped by.  For instance, if an account
    #   has many users and this is the user list for said acccount, then you would use :scoped_by => @account.
    #   This will scope the user list with filter to that account.  It will also change the path helper from
    #   users_path to account_users_path, unless you overrode the path helper with :list_path_helper.
    # +namespace+ - The name of the namespace being used for this resource.
    # +polymorphic_type+ - A string representing the name of the type to use if the current type is just a polymorphic 
    #   association table, etc.  For instance
    # +polymorphic_as+ -
    #
    def g_named_scope_filters( ar_obj_col_or_class, *args )
      options = args.extract_options!
      options.merge! :class => "filters" unless options.include?( :class )
      options.merge! :selected_class => "selected" unless options.include?( :selected_class )
      options.merge! :exclude_css => true, :exclude_js => true 

      if options[:only]
        if options[:only].is_a?( String ) || options[:only].is_a?( Symbol )
          filters = Array.new << options[:only]
        else
          filters = options[:only]
        end
      end
      options[:filters] = filters

      scoped_by = options[:scoped_by]
      polymorphic_type = options[:polymorphic_type]
      polymorphic_as = options[:polymorphic_as]
      record_counts = options[:record_counts]
      include_all = options[:include_all]
      include_all = true unless include_all == false
      all_label = options[:all_label] || 'All'
      all_param = options[:all_param]
      all_param = nil if all_param == :none || all_param == false
      filter_param_key = options[:filter_param_key] || 'filter'
      
      raise "You must provide the 'polymorphic_as' option if you provide the 'polymorphic_type' option." if polymorphic_type && !polymorphic_as

      Guilded::Guilder.instance.add( :named_scope_filters, options )

      # Resolve the class of the ActiveRecord descendant type
      if ar_obj_col_or_class.is_a?( Array )
        return '' if ar_obj_col_or_class.empty?
        klass = ar_obj_col_or_class[0].class
      elsif ar_obj_col_or_class.is_a?( Class )
        klass = ar_obj_col_or_class
      elsif ar_obj_col_or_class.is_a?( ActiveRecord::Base )
        klass = ar_obj_col_or_class.class
      else
        throw 'You must provide either an ActiveRecord object, collection or type in order to generate filters.'
      end

      path_helpers = Guilded::Rails::Helpers.resolve_rest_path_helpers( ar_obj_col_or_class, options )
      list_path_helper = path_helpers[:index_rest_helper]

      html = ''

      return html if filters.empty?

      # Resolve scoped by if it is an array
      scoped_by = scoped_by.last if scoped_by.is_a?( Array )
      
      html << "<ul id=\"#{options[:id].to_s}\" class=\"#{options[:class].to_s}\">"

      # Handle the all filter
      if include_all
        link_text = all_label

        if options[:include_count]
          if record_counts
            link_text << " <span>#{record_counts[:all]}</span>"
          elsif scoped_by   
            if polymorphic_type
              poly_scoped_finder = polymorphic_type.to_s.tableize
              link_text << " <span>#{scoped_by.send( poly_scoped_finder.to_sym ).count}</span>"
            else
              scoped_finder = klass.to_s.tableize
              link_text << " <span>#{scoped_by.send( scoped_finder.to_sym ).count}</span>"
            end
          else
            link_text << " <span>#{klass.count}</span>" 
          end
        end

        filter_options = []
        filter_options.push( :order => params[:order] ) if params[:order]
        filter_options.push( filter_param_key.to_sym => all_param ) if all_param # Send a param for 'All' filter

        html << "<li>"
        html << link_to( link_text, @controller.send( list_path_helper, *(path_helpers[:index_rest_args] + filter_options) ), 
                  :class => "#{params[:filter] == all_param.to_s ? options[:selected_class] : ''}" )
      end

      filters.each do |filter|
        throw "You must define a named scope of '#{filter.to_s}' in order to render a named scope filter for it" unless klass.respond_to?( filter.to_sym )
        link_text = filter.to_s.humanize

        if options[:include_count]
          if record_counts
            link_text << " <span>#{record_counts[filter.to_sym]}</span>"
          elsif scoped_by
            scoped_finder = klass.to_s.tableize if scoped_finder.nil? || scoped_finder.empty?

            if polymorphic_type
              # If there is a named scope finder defined on the root klass that can get the 
              # polymorpic associated objects, the use it
              if klass.respond_to?( poly_scoped_finder )
                link_text << " <span>#{scoped_by.send( scoped_finder.to_sym ).send( poly_scoped_finder.to_sym ).send( filter.to_sym ).count}</span>"
              else #otherwise, just use a AR's find
                link_text << " <span>#{scoped_by.send( scoped_finder.to_sym ).send( filter.to_sym ).find(:all, :conditions => { "#{polymorphic_as}_type".to_sym => polymorphic_type } ).size}</span>"
              end
            else
              link_text << " <span>#{scoped_by.send( scoped_finder.to_sym ).send( filter.to_sym ).count}</span>"
            end
          else
            link_text << " <span>#{klass.send( filter.to_sym ).count}</span>"
          end
        end

        filter_options = []
        #filter_options.merge!( :filter => filter )
        if filter_options[filter_options.size-1].is_a?( Hash )
          filter_options[filter_options.size-1].merge!( filter_param_key.to_sym => filter )
        else
          filter_options.push( filter_param_key.to_sym => filter )
        end

        html << "<li>"
        html << link_to( link_text, @controller.send( list_path_helper, *(path_helpers[:index_rest_args] + filter_options) ), 
                  :class => "#{params[:filter] == filter.to_s ? options[:selected_class] : ''}" )
        html << "</li>"
      end

      html << "</ul>"
      html
    end
    
  end
end