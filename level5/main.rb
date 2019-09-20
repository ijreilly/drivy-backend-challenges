require 'json'
require 'date'

class Drivy
  def initialize(input)
    data = JSON.parse(input, symbolize_names: true)
    @cars = data[:cars]
    @options = data[:options]
    @rentals = data[:rentals].map { |rental| Rental.new(rental[:id], @cars, rental[:car_id], rental[:start_date], rental[:end_date], rental[:distance], @options)}
  end

  def generate_json
    File.open('data/output.json', 'w') do |file|
      file.write(JSON.pretty_generate(rentals: @rentals.map(&:for_json)))
    end
  end

  class Rental
    def initialize(id, cars, car_id, start_date, end_date, distance, options)
      @id = id
      @car = cars.find { |car| car[:id] == car_id }
      @options = options.select { |option| option[:rental_id] == @id }.map { |option| option[:type]}
      @start_date = DateTime.parse start_date
      @end_date = DateTime.parse end_date
      @distance = distance
    end

    def duration
      @end_date - @start_date + 1
    end

    def reduction(index)
      case index
      when 0 then 0
      when 1..3 then 0.1
      when 4..9 then 0.3
      else 0.5
      end
    end

    def price_duration
      daily_prices = Array.new(duration) { @car[:price_per_day] }
      daily_prices.map!.with_index { |price, index| price * (1 - reduction(index)) }
      daily_prices.reduce(:+)
    end

    def price_distance
      @car[:price_per_km] * @distance
    end

    def price
      price_duration + price_distance
    end

    def gps
      duration * (@options.include?("gps") ? 500 : 0)
    end

    def baby_seat
      duration * (@options.include?("baby_seat") ? 200 : 0)
    end

    def additional_insurance
      duration * (@options.include?("additional_insurance") ? 1000 : 0)
    end

    def commission
      commission = {
        driver: - (price + gps + baby_seat + additional_insurance),
        owner: (price * 0.7).to_i + gps + baby_seat,
        insurance: (price * 0.3 * 0.5).to_i,
        assistance: (100 * duration).to_i,
        drivy: (price * 0.3).to_i - (price * 0.3 * 0.5).to_i - (100 * duration).to_i + additional_insurance
      }
    end

    def action(people, amount)
      {
        who: people,
        type: amount.positive? ? "credit" : "debit",
        amount: amount.to_i.abs
      }
    end

    def for_json
      { id: @id, options: @options, actions: commission.map {|people, amount| action(people,amount)} }
    end
  end
end

serialized_input = File.read('data/input.json')
Drivy.new(serialized_input).generate_json