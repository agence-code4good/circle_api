class Product
  require "csv"

  attr_reader :family,
              :product_type,
              :product_complement,
              :country,
              :region,
              :subregion,
              :origin_sign,
              :origin,
              :mention,
              :name,
              :label_complement,
              :label,
              :classification,
              :classification_detail,
              :bottler,
              :color,
              :starting_vintage,
              :late_vintage,
              :excluded_vintages,
              :code

  def initialize(attributes)
    attributes.each do |key, value|
      instance_variable_set("@#{key}", value)
    end
  end

  def vintage_allowed?(vintage)
    vintage_int = vintage.to_i
    normalized_excluded_vintages = write_excluded_vintages_from_range
    normalized_starting_vintage = normalize_starting_vintage
    normalized_late_vintage = normalize_late_vintage

    return false if normalized_excluded_vintages.include?(vintage_int)
    return false if vintage_int < normalized_starting_vintage
    return false if vintage_int > normalized_late_vintage
    return false if vintage_int > Date.today.year
    true
  end

  def c10
    code
  end

  def self.all
    load_products.values
  end

  def self.find_by(c10:)
    load_products[c10]
  end

  private

  def self.load_products
    @products ||= begin
      path = Rails.root.join("specs", "products.csv")
      rows = CSV.read(path, headers: true)

      rows.each_with_object({}) do |row, hash|
        c10 = row["C10"]
        next if c10.blank?

        attributes = {
          code: c10, # C10
          label: row["Etiquette"],
          starting_vintage: row["Premier millésime"],
          late_vintage: row["Dernier Millésime"],
          excluded_vintages: row["Millésime(s) non produit(s)"],
          family: row["Famille"],
          product_type: row["Type produit"],
          product_complement: row["Complément Produit"],
          country: row["Pays"],
          region: row["Région"],
          subregion: row["Sous-Région"],
          origin_sign: row["Signe de l'Origine"],
          origin: row["Origine"],
          mention: row["Mention"],
          name: row["Nom"],
          label_complement: row["Complément étiquette / Cuvée"],
          classification: row["Classement / Appellation"],
          classification_detail: row["Du Classement / Climat"],
          bottler: row["Producteur / Embouteilleur"],
          color: row["Couleur"]
        }

        product = new(attributes)

        hash[c10] = product
      end
    end
  end

  def normalize_starting_vintage
    return 1855 if @starting_vintage.nil? || @starting_vintage.to_s.strip == "ND" || @starting_vintage.to_s.strip.empty?
    @starting_vintage.to_i
  end

  def normalize_late_vintage
    return Date.today.year if @late_vintage.nil? || @late_vintage.to_s.strip == "ND" || @late_vintage.to_s.strip.empty?
    @late_vintage.to_i
  end

  def write_excluded_vintages_from_range
    return [] if @excluded_vintages.nil? ||
                @excluded_vintages.to_s.strip.empty? ||
                @excluded_vintages.to_s.strip == "ND"

    # Normaliser en array si c'est une string
    ranges = if @excluded_vintages.is_a?(Array)
      @excluded_vintages
    else
      @excluded_vintages.to_s.split(",").map(&:strip)
    end

    # Parser chaque élément (peut être une plage "2003-2007" ou une année "2013")
    ranges.flat_map do |range_str|
      range_str = range_str.strip
      next [] if range_str.empty?

      if range_str.include?("-")
        # C'est une plage : "2003-2007"
        start_year, end_year = range_str.split("-").map(&:strip).map(&:to_i)
        (start_year..end_year).to_a
      else
        # C'est une année unique : "2013"
        [ range_str.to_i ]
      end
    end.compact
  end
end
