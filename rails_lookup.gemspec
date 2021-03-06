# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{rails_lookup}
  s.version = "0.0.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 1.2") if s.respond_to? :required_rubygems_version=
  s.authors = [%q{Nimrod Priell}]
  s.date = %q{2011-08-06}
  s.description = %q{Lookup tables with ruby-on-rails
--------------------------------

By: Nimrod Priell

This gem adds an ActiveRecord macro to define memory-cached, dynamically growing, normalized lookup tables for entity 'type'-like objects. Or in plain English - if you want to have a table containing, say, ProductTypes which can grow with new types simply when you refer to them, and not keep the Product table containing a thousand repeating 'type="book"' entries - sit down and try to follow through.

Motivation
----------

A [normalized DB][1] means that you want to keep types as separate tables, with foreign keys pointing from your main entity to its type. For instance, instead of 
ID          | car_name        | car_type
1           | Chevrolet Aveo  | Compact
2           | Ford Fiesta     | Compact
3           | BMW Z-5         | Sports

You want to have two tables:
ID  | car_name        | car_type_id
1   | Chevrolet Aveo  | 1
2   | Ford Fiesta     | 1
3   | BMW Z-5         | 2

And

car_type_id | car_type_name 
1           | Compact
2           | Sports

The pros/cons of a normalized DB can be discussed elsewhere. I'd just point out a denormalized solution is most useful in settings like [column oriented DBMSes][2]. For the rest of us folks using standard databases, we usually want to use lookups.

The usual way to do this with ruby on rails is
* Generate a CarType model using `rails generate model CarType name:string`
* Link between CarType and Car tables using `belongs_to` and `has_many`

Then to work with this you can transparently read the car type:

    car = Car.all.first
    car.car_type.name # returns "Compact"

Ruby does an awesome job of caching the results for you, so that you'll probably not hit the DB every time you get the same car type from different car objects.

You can even make this shorter, by defining a delegate to car_type_name from CarType:

*in car_type_name.rb*
    
    delegate :name, :to => :car, :prefix => true

And now you can access this as 

    car.car_type_name

However, it's less pleasant to insert with this technique:

    car.car_type.car_type_name = "Sports"
    car.car_type.save!
    #Now let's see what happened to the OTHER compact car
    Car.all.second.car_type_name #Oops, returns "Sports"

Right, what are we doing? We should've used

    car.update_attributes(car_type: CarType.find_or_create_by_name(name: "Sports"))

Okay. Probably want to shove that into its own method rather than have this repeated in the code several times. But you also need a helper method for creating cars that way…

Furthermore, ruby is good about caching, but it caches by the exact query used, and the cache expires after the controller action ends. You can configure more advanced caches, perhaps.

The thing is all this can get tedious if you use a normalized structure where you have 15 entities and each has at least one 'type-like' field. That's a whole lot of dangling Type objects. What you really want is an interface like this:

    car.all.first
    car.car_type #return "Compact"
    car.car_type = "Sports" #No effect on car.all.second, just automatically use the second constant
    car.car_type = "Sedan" #Magically create a new type

Oh, and it'll be nice if all of this is cached and you can define car types as constants (or symbols). You obviously still want to be able to run:

    CarType.where (:id > 3) #Just an example of supposed "arbitrary" SQL involving a real live CarType class

But you wanna minimize generating these numerous type classes. If you're like me, you don't even want to see them lying around in app/model. Who cares about them?

I've looked thoroughly for a nice rails solution to this, but after failing to find one, I created my own rails metaprogramming hook.

Installation
------------

The result of this hook is that you get the exact syntax described above, with only two lines of code (no extra classes or anything):
In your ActiveRecord object simply add

    require 'active_record/lookup'
    class Car < ActiveRecord::Base
      #...
      include ActiveRecord::Lookup
      lookup :car_type
      #...
    end

That's it. the generated CarType class (which you won't see as a car_type.rb file, obviously, as it is generated in real-time), contains some nice methods to look into the cache as well: So you can call

    CarType.id_for "Sports" #Returns 2
    CarType.name_for 1 #Returns "Compact"

and you can still hack at the underlying ID for an object, if you need to:

    car = car.all.first
    car.car_type = "Sports"
    car.car_type_id #Returns 2
    car.car_type_id = 1
    car.car_type #Returns "Compact"

The only remaining thing is to define your migrations for creating the actual database tables. After all, that's something you only want to do once and not every time this class loads, so this isn't the place for it. However, it's easy enough to create your own scaffolds so that 

     rails generate migration create_car_type_lookup_for_car

will automatically create the migration

    class CreateCarTypeLookupForCar < ActiveRecord::Migration
      def self.up
        create_table :car_types do |t|
          t.string :name
          t.timestamps #Btw you can remove these, I don't much like them in type tables anyway
        end
    
        remove_column :cars, :car_type #Let's assume you have one of those now…
        add_column :cars, :car_type_id, :integer #Maybe put not_null constraints here.
      end

      def self.down
        drop_table :car_types
        add_column :cars, :car_type, :string
        remove_column :cars, :car_type_id
      end
    end

I'll let you work out the details for actually migrating the data yourself. 

[1] http://en.wikipedia.org/wiki/Database_normalization
[2] http://en.wikipedia.org/wiki/Column-oriented_DBMS

I hope this helped you and saved a lot of time and frustration. Follow me on twitter: @nimrodpriell

}
  s.email = %q{@nimrodpriell}
  s.extra_rdoc_files = [%q{README}, %q{lib/active_record/lookup.rb}]
  s.files = [%q{README}, %q{Rakefile}, %q{lib/active_record/lookup.rb}, %q{rails_lookup.gemspec}]
  s.homepage = %q{http://github.com/Nimster/RailsLookup/}
  s.rdoc_options = [%q{--line-numbers}, %q{--inline-source}, %q{--title}, %q{Rails_lookup}, %q{--main}, %q{README}]
  s.require_paths = [%q{lib}]
  s.rubyforge_project = %q{rails_lookup}
  s.rubygems_version = %q{1.8.7}
  s.summary = %q{Lookup table macro for ActiveRecords}

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
