module GeoRecord
  extend ActiveSupport::Concern

  # Ensure that when coordinates are printed that they are always in decimal degrees,
  # and not e.g. 4.0e-05
  # Unfortunately you can't extend Numeric classes directly (e.g. `Coord < Float`).
  class Coord < DelegateClass(Float)
    def to_s
      format("%<coord>.7f", :coord => self)
    end

    def as_json(*)
      format("%<coord>.7f", :coord => self).to_f
    end
  end

  # This scaling factor is used to convert between the float lat/lon that is
  # returned by the API, and the integer lat/lon equivalent that is stored in
  # the database.
  #
  # In Samland, we want a direct mapping between the two, so we use a scale of 1
  # (which essentially disables the scaling). So, 1 lat/lon = one block.
  SCALE = 1

  included do
    scope :bbox, ->(bbox) { where(OSM.sql_for_area(bbox, "#{table_name}.")) }
    before_save :update_tile
  end

  # Is this node within -30000000 >= latitude >= 30000000 and -30000000 >= longitude >= 30000000
  # A minecraft world has a max horizontal size of 30,000,000 blocks.
  # * returns true/false
  def in_world?
    return false if lat < -30000000 || lat > 30000000
    return false if lon < -30000000 || lon > 30000000

    true
  end

  def update_tile
    self.tile = QuadTile.tile_for_point(lat, lon)
  end

  def lat=(l)
    self.latitude = (l * SCALE).round
  end

  def lon=(l)
    self.longitude = (l * SCALE).round
  end

  # Return WGS84 latitude
  def lat
    Coord.new(latitude.to_f / SCALE)
  end

  # Return WGS84 longitude
  def lon
    Coord.new(longitude.to_f / SCALE)
  end
end
