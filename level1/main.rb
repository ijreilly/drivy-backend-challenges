require 'json'
require 'date'

class Drivy
  def initialize(input)
    data = JSON.parse(input, symbolize_names: true)
    @cars = data[:cars]
    @rentals = data[:rentals].map { |rental| Rental.new(rental[:id], @cars, rental[:car_id], rental[:start_date], rental[:end_date], rental[:distance])}
  end

  def to_json
    File.open('data/output.json', 'w') do |file|
      file.write(JSON.pretty_generate(rentals: @rentals.map(&:for_json)))
    end
  end

  class Rental
    def initialize(id, cars, car_id, start_date, end_date, distance)
      @id = id
      @car = cars.find { |car| car[:id] == car_id }
      @start_date = DateTime.parse start_date
      @end_date = DateTime.parse end_date
      @distance = distance
    end

    def duration
      @end_date - @start_date + 1
    end

    def price
      @car[:price_per_day] * duration + @car[:price_per_km] * @distance
    end

    def for_json
      { id: @id, price: price.to_i }
    end
  end
end

serialized_input = File.read('data/input.json')
puts Drivy.new(serialized_input).to_json
