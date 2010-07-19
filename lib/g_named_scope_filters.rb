$:.unshift(File.dirname(__FILE__)) unless
  $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

require 'g_named_scope_filters/view_helpers'

module GNamedScopeFilters
  VERSION = '1.0.6'
end

if defined?( ActionView::Base )
  ActionView::Base.send( :include, GNamedScopeFilters::ViewHelpers ) unless ActionView::Base.include?( GNamedScopeFilters::ViewHelpers )
end