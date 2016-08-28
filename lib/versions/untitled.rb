require 'helper'
require 'property'

class Version < ActiveRecord::Base
  self.table_name = :versions
  include Versions::Auto

  def should_clone?
    if changed?
      true
    else
      false
    end
  end
end

class Page < ActiveRecord::Base
  self.table_name = :pages
  include Versions::Multi
  has_multiple :versions, :class_name => 'Version'

  include Property
  store_properties_in :version

  property do |p|
    p.text 'history'
    p.string 'author', :default => 'John Malkovitch'
  end
end

page = Page.create('history' => 'His Story')

page.update_attributes('history' => 'TOTO')