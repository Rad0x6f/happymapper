HappyMapper
===========

Happymapper allows you to parse XML data and convert it quickly and easily into ruby data structures.

This project is a grandchild (a fork of a fork) of the great work done first by [jnunemaker](https://github.com/jnunemaker/happymapper) and then by [dam5s](http://github.com/dam5s/happymapper/).


Installation
------------

*Build the gem yourself:*

    $ git clone https://github.com/burtlo/happymapper
    $ cd happymapper
    $ gem build nokogiri-happymapper.gemspec
    $ gem install --local happymapper-X.X.X.gem

*For you [Bundler's](http://gembundler.com/) out there, you can add it to your Gemfile and then `bundle install`*

    gem 'happymapper', :git => "git://github.com/burtlo/happymapper.git"

Examples
--------

## Element Mapping

Let's start with a simple example to get our feet wet. Here we have a simple example of XML that defines some address information:

    <address>
      <street>Milchstrasse</street>
      <housenumber>23</housenumber>
      <postcode>26131</postcode>
      <city>Oldenburg</city>
      <country code="de">Germany</country>
    </address>

Happymapper will let you easily model this information as a class:

    require 'happymapper'

    class Address
      include HappyMapper

      tag 'address'
      element :street, String, :tag => 'street'
      element :postcode, String, :tag => 'postcode'
      element :housenumber, Integer, :tag => 'housenumber'
      element :city, String, :tag => 'city'
      element :country, String, :tag => 'country'
    end

To make a class HappyMapper compatible you simply `include HappyMapper` within the class definition. This takes care of all the work of defining all the speciality methods and magic you need to get running. As you can see we immediately start using these methods.

    `tag` matches the name of the XML tag name 'address'.

    `element` defines accessor methods for the specified symbol (e.g. `:street`,`:housenumber`) that will return the class type (e.g. `String`,`Integer`) of the XML tag specified (e.g. `:tag => 'street'`, `:tag => 'housenumber'`).
    
When you define an element with an accessor with the same name as the tag, this is the case for all the examples above, you can omit the `:tag`. These two element declaration are equivalent to each other:

    element :street, String, :tag => 'street'
    element :street, String

Including the additional tag element is not going to hurt anything and in some cases will make it absolutely clear how these elements map to the XML. However, once you know this rule, it is hard not to want to save yourself the keystrokes.

Instead of `element` you may also use `has_one`:

    element :street, String, :tag => 'street'
    element :street, String
    has_one :street, String

These three statements are equivalent to each other.

## Parsing

With the mapping of the address XML articulated in our Address class it is time to parse the data:

    address = Address.parse(ADDRESS_XML_DATA, :single => true)
    puts address.street 

Assuming that the constant `ADDRESS_XML_DATA` contains a string representation of the address XML data this is fairly straight-forward save for the `parse` method.

The `parse` method, like `tag` and `element` are all added when you included HappyMapper in the class. Parse is a wonderful, magical place that converts all these declarations that you have made into the data structure you are about to know and love.

But what about the `:single => true`? Right, that is there because by default, without `:single => true`, when your object is all done parsing it will be an array. In this case an array with one element, but an array none the less. So the following are equivalent to each other:

    address = Address.parse(ADDRESS_XML_DATA).first
    address = Address.parse(ADDRESS_XML_DATA, :single => true)

The first one returns an array and we return the first instance, the second will do that work for us inside of parse.

## Multiple Elements Mapping

What if our address XML was a little different, perhaps we allowed multiple streets:

    <address>
      <street>Milchstrasse</street>
      <street>Another Street</street>
      <housenumber>23</housenumber>
      <postcode>26131</postcode>
      <city>Oldenburg</city>
      <country code="de">Germany</country>
    </address>

Similar to `element` or `has_one`, the declaration for when you have multiple elements you simply use:

    has_many :streets, String, :tag => 'street'

Your resulting `street` method will now return an array.

    address = Address.parse(ADDRESS_XML_DATA, :single => true)
    puts address.streets.join('\n')
    
Imagine that you have to write `street.join('\n')` for the rest of eternity throughout your code. It would be a nightmare and one that you could avoid by creating your own convenience method.

     require 'happymapper'

     class Address
       include HappyMapper

       tag 'address'
       
       has_many :streets, String, :tag => 'street'
       
       def street
         streets.join('\n')
       end
       
       element :postcode, String, :tag => 'postcode'
       element :housenumber, String, :tag => 'housenumber'
       element :city, String, :tag => 'city'
       element :country, String, :tag => 'country'
     end

Now when we access `street` we get a single value, but we still have `streets` if we ever need to the two values independently.


## Attribute Mapping

    <address location='home'>
      <street>Milchstrasse</street>
      <street>Another Street</street>
      <housenumber>23</housenumber>
      <postcode>26131</postcode>
      <city>Oldenburg</city>
      <country code="de">Germany</country>
    </address>

Attributes are absolutely the same as `element` or `has_many`

    attribute :location, String, :tag => 'location
    
Again, you can omit the tag if the attribute accessor symbol matches the name of the attribute.


## Class composition

Our address likely belongs to a person and likely is contained within our XML

    <person>
      <name>Burtie Sanchez</name>  
      <address location='home'>
        <street>Milchstrasse</street>
        <street>Another Street</street>
        <housenumber>23</housenumber>
        <postcode>26131</postcode>
        <city>Oldenburg</city>
        <country code="de">Germany</country>
      </address>
    </person>

We have already defined our Address class, so let's define our Person class.

    class Person
      include HappyMapper
  
      has_one :name, String
      has_many :addresses, Address, :tag => 'address'
    end

Instead of a `String`, `Boolean`, or `Integer` we declare the class that this maps to and HappyMapper takes care of the details of continuing the XML mapping through the address.

    person = Person.parse(PERSON_XML_DATA, :single => true)
    puts person.address.street
  
A quick note, you can use `Person` or `'Person'`. The nice part of using the latter declaration, enclosed in quotes, is that you do not have to define your class above or before this class. So Person and Address can live in separate files and as long they are both available when it comes time to parse you are golden.


## Custom XPATH

I ran into a case where I wanted to capture all the pictures but only the ones not contained in an album.

    <media>
      <gallery>
        <picture>
          <name>Burtie Sanchez</name>  
          <img>burtie01.png</img>
        </picture>
      </gallery>
      <picture>
        <name>Unsorted Photo</name>  
        <img>bestfriends.png</img>
      </picture>
    </media>
    
The following `Media` class is where I started:

    require 'happymapper'

    class Media
      include HappyMapper
  
      has_many :galleries, Gallery, :tag => 'gallery'
      has_many :pictures, Picture, :tag => 'picture'
    end

However when I parsed the media xml the number of pictures returned to me was 2, not 1.

    pictures = Media.parse(MEDIA_XML,:single => true).pictures
    pictures.length.should == 1   # => Failed Expectation

I was mistaken and that is because, by default the mappings are assigned XPATH './/' which is requiring all the elements no matter where they can be found. To override this you can specify an XPATH value for your defined elements.

    has_many :pictures, Picture, :tag => 'picture', :xpath => '/media'

`/media` states that we are only interested in pictures that can be found directly under the media element. So when we parse again we will have only our one element.

## Namespaces
