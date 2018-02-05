require 'csv'

class CSVImporter
  attr_accessor :errors

  def initialize(community, file)
    @community = community
    @file = file
    @errors = []
    @translations = CommunityTranslation.all.each_with_object({}){|row, result| result[row.translation_key] = row.translation }
    @custom_fields = CustomField.all.each_with_object({}){|row, result| result[row.name] = row }
    @categories = Category.all.each_with_object({}){|row, result| result[row.display_name(I18n.locale)] = row }
    @shapes = ListingShape.all.to_a
  end

  def process
    CSV.parse(IO.read(@file), headers: true).each_with_index do |row, index|
      row = row.to_h.with_indifferent_access
      puts row.inspect
      import_row(row, index)
      # @errors << [index, [e.inspect, e.message, e.backtrace[0]].join(" ")]
    end
  end

  def import_row(row, index)
    return unless row['Email'].present?
    person = create_person(row, index)
    return unless person
    make_listing(person, row, index) if row['Listing Title'].present?
  end

  # Given Name,Family Name,Email,Username,Password,Profile Type
  def create_person(params, index)
    person = Person.new({
        username: params['Username'],
        community_id: @community.id,
        given_name: params['Given Name'],
        family_name: params['Family Name'],
        locale: 'en',
        password: params['Password'],
        is_vendor: params['Profile Type'] == 'Vendor/Business'
      })
    email_address = params['Email'].downcase.strip
    allowed_and_available = @community.email_allowed?(email_address) && Email.email_available?(email_address, @community.id)
    unless allowed_and_available
      @errors << [index, "The email #{email_address} is already in use"]
      return nil
    end

    username_exists = Person.where(community_id: @community.id, username: params['Username']).exists?
    if username_exists
      @errors << [index, "The email #{params['Username']} is already in use"]
      return nil
    end

    email = Email.new(:person => @person, :address => email_address, :send_notifications => true, community_id: @community.id)
    person.emails << email
    person.inherit_settings_from(@community)
    person.set_default_preferences
    person.save!
    membership = CommunityMembership.new(:person => person, :community => @community, :consent => @community.consent, status: 'pending_email_confirmation')
    membership.save!
    if person.is_vendor
      person.image = File.new(Rails.root+"app/assets/images/gray_shop_logo.png")
      person.save
    end
    person
  end


  # Listing Type,Listing Title,Price,Description,Category,Unit Type,List Filter,Seller Type,Condition,Pickup/Dropoff Options,Address,Images
  def make_listing(author, params, index)
    shape = find_shape(params["Listing Type"])
    unless shape
      @errors << [index, "Missing shape #{params["Listing Type"]}"]
      return
    end

    listing_unit = find_unit(shape, params['Unit Type'])

    listing = Listing.new
    listing.community_id = @community.id
    listing.title = params["Listing Title"]
    listing.description = params["Description"]
    listing.price_cents = params["Price"].to_f * 100
    listing.currency = @community.currency
    listing.author = author
    listing.category = find_category(params["Category"])
    
    listing.listing_shape = shape
    listing.transaction_process_id = shape.transaction_process_id
    listing.availability = shape.availability
    listing.shape_name_tr_key = shape.name_tr_key
    listing.action_button_tr_key = shape.action_button_tr_key

    listing.unit_type = listing_unit&.unit_type
    listing.quantity_selector = listing_unit&.quantity_selector
    listing.unit_tr_key = listing_unit&.name_tr_key
    listing.unit_selector_tr_key = listing_unit&.selector_tr_key

    location = Location.new(address: params['Address'], location_type: 'origin_loc')
    location.search_and_fill_latlng
    listing.origin_loc = location
    listing.save!

    if params["Images"].present?
      params["Images"].split("|").each_with_index do |url, index|
        ListingImage.create(image: open(url), listing: listing, position: index)
      end
    end

    ['List Filter','Seller Type','Condition','Pickup/Dropoff Options'].each do |cf_name|
      add_custom_field_options(listing, cf_name, params[cf_name], index)
    end
  end

  def find_shape(name)
    @shapes.detect{|shape| @translations[shape.name_tr_key] == name }
  end

  def find_category(name)
    @categories[name.to_s.strip]
  end

  def add_custom_field_options(listing, name, values, index)
    return unless values.present?
    custom_field = @custom_fields[name]
    unless custom_field
      @errors << [index, "Missing custom field \"#{name}\""]
      return
    end

    values.split("|").each do |value|
      if option = custom_field.options.detect{|opt| opt.title.strip == value.strip }
        if field_value = listing.custom_field_value_factory(custom_field.id, [option.id]) 
          field_value.save
        end
      else
        @errors << [index, "Missing option #{value} for #{name}"]
      end
    end
  end

  def find_unit(shape, name)
    shape.listing_units.detect{|u| u.unit_type.to_s == name || @translations[u.name_tr_key] == name }
  end
end
