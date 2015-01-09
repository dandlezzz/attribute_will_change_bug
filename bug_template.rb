unless File.exist?('Gemfile')
  File.write('Gemfile', <<-GEMFILE)
    source 'https://rubygems.org'
    gem 'rails', github: 'rails/rails'
    gem 'arel', github: 'rails/arel'
    gem 'sqlite3'
  GEMFILE

  system 'bundle'
end

require 'bundler'
Bundler.setup(:default)

require 'active_record'
require 'minitest/autorun'
require 'logger'

# This connection will do for database-independent bug reports.
ActiveRecord::Base.establish_connection(adapter: 'sqlite3', database: ':memory:')
ActiveRecord::Base.logger = Logger.new(STDOUT)

ActiveRecord::Schema.define do
  create_table :posts do |t|
  end

  create_table :comments do |t|
    t.integer :post_id
  end
end

class Post < ActiveRecord::Base
  has_many :comments
  attr_accessor :non_persisted_attribute
  before_save :before_save_callback


  def before_save_callback
    #mark non-persisted attribute as dirty
    attribute_will_change!(:non_persisted_attribute)
    #do some work\
  end

  def arel_attributes_with_values(attribute_names)
      # this is a fix, comment out this line and things will break. I don't know if 
      # this is the most performant way to do things here but we probably do need
      # to check the changes attribute to make sure that it only send real attribute names to the database.
      attribute_names.reject!{ |attr_name| !self.attributes.keys.include?(attr_name) }
      
      super
  end
end

class Comment < ActiveRecord::Base
  belongs_to :post
end

class BugTest < Minitest::Test
  def test_association_stuff
    post = Post.create!
    post.comments << Comment.create!

    assert_equal 1, post.comments.count
    assert_equal 1, Comment.count
    assert_equal post.id, Comment.first.post.id
  end
end