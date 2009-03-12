module GNamedScopeFilters
  module ViewHelpers
    
    # Guilded component.  This is an unordered list of filters that use named scopes within an ActiveRecord model
    # to filter a list.  It is not tied to a table or list specifically as it simply manipulates the url, resulting 
    # in a manipulation of a list or table.
    # 
    # *parameters*
    # :ar_obj_col_or_class:: The ActiveRecord object, collection or class to make the filters from.  Warning:
    #   if you use anything but the class and the collection or object comes up nil or empty, then you will 
    #   not have filters renderred.  The prefferred way is to use the class unless you cannot due to dynamic reasons.
    #   
    # *options*
    # :id:: (Required) This will be the id of the ul returned that wraps the filters.
    # :class:: This will be the id of the ul returned that wraps the filters.  Defaults to 'filters.'
    # :selected_class:: This will be the class that is used to show whih filter is selected.  Defaults to 'selected.'
    # :only:: This is the filters to include.  Can be an array or string (for one filter).
    # :include_count:: True if you would like a span created within each filter list item containg the count for
    #   items in that filter.
    # :scoped_by:: This is the ActiveRecord object that this list is scoped by.  For instance, if an account
    #   has many users and this is the user list for said acccount, then you would use :scoped_by => @account.
    #   This will scope the user list with filter to that account.  It will also change the path helper from
    #   users_path to account_users_path, unless you overrode the path helper with :list_path_helper.
    # :list_path_helper:: This is a string or symbol for the list path helper to use.  You will need to override
    #   if your object is namespaced.
    # :polymorphic:: A string representing the name of the type to use if the current type is just a polymorphic 
    #   association table, etc.  For instance
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

      scoped_by = options.delete( :scoped_by )
      polymorphic_type = options.delete( :polymorphic_type ).to_s if options.has_key?( :polymorphic_type )
      polymorphic_as = options.delete( :polymorphic_as ).to_s if options.has_key?( :polymorphic_as )

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

      if options[:list_path_helper]
        list_path_helper = options[:list_path_helper].to_s
      elsif scoped_by
        list_path_helper = "#{scoped_by.class.to_s.underscore}_#{klass.to_s.tableize}_path"
      else
        list_path_helper = "#{klass.to_s.tableize}_path"
      end

      html = ''

      return html if filters.empty?

      html << "<ul id=\"#{options[:id].to_s}\" class=\"#{options[:class].to_s}\">"

      # Handle the all filter
      link_text = "All"

      if options[:include_count]
        if scoped_by   
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

      filter_options = {}
      filter_options.merge!( :order => params[:order] ) if params[:order]

      html << "<li>"
      html << link_to( link_text, @controller.send( list_path_helper, filter_options ), 
                :class => "#{params[:filter].nil? ? options[:selected_class] : ''}" )

      filters.each do |filter|
        throw "You must define a named scope of '#{filter.to_s}' in order to render a named scope filter for it" unless klass.respond_to?( filter.to_sym )
        link_text = filter.to_s.humanize

        if options[:include_count]

          if scoped_by

            scoped_finder = klass.to_s.tableize if scoped_finder.nil? || scoped_finder.empty?

            if polymorphic_type

              # If there is a named scope finder defined on the root klass that can get the 
              # polymorpic assocaited objects, the use it
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

        filter_options.merge!( :filter => filter )

        html << "<li>"
        html << link_to( link_text, @controller.send( list_path_helper, filter_options ), 
                :class => "#{params[:filter] == filter.to_s ? options[:selected_class] : ''}" )
        html << "</li>"
      end

      html << "</ul>"
      html
    end
    
  end
end