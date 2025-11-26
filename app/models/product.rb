class Product
  attr_reader :code, :label, :starting_vintage, :late_vintage, :excluded_vintages

  def initialize(code:, label:, starting_vintage:, late_vintage:, excluded_vintages:)
    @code = code
    @label = label
    @starting_vintage = starting_vintage.to_i
    @late_vintage = late_vintage.to_i
    @excluded_vintages = write_excluded_vintages_from_range(excluded_vintages)
  end


  def vintage_allowed?(vintage)
    return false if excluded_vintages.include?(vintage.to_i)
    return false if starting_vintage != "ND" && vintage.to_i < starting_vintage
    return false if late_vintage != "ND" && vintage.to_i > late_vintage
    return false if vintage.to_i > Date.today.year
    true
  end

  private

  def write_excluded_vintages_from_range(excluded_vintages)
    return [] if excluded_vintages.nil? ||
                excluded_vintages.to_s.strip.empty? ||
                excluded_vintages.to_s.strip == "ND"

    # Normaliser en array si c'est une string
    ranges = if excluded_vintages.is_a?(Array)
      excluded_vintages
    else
      excluded_vintages.to_s.split(",").map(&:strip)
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
