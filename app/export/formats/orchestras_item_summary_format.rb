module Formats
  class OrchestrasItemSummaryFormat
    def initialize
      @total = {
          :dormitory => {
              :thursday => 0,
              :friday => 0,
              :saturday => 0
          },
          :medal => 0,
          :tag => 0,
          :tshirt => {
              :womenxs => 0,
              :womens => 0,
              :womenm => 0,
              :womenl => 0,
              :womenxl => 0,
              :womenxxl => 0,
              :womenxxxl => 0,

              :manxs => 0,
              :mans => 0,
              :manm => 0,
              :manl => 0,
              :manxl => 0,
              :manxxl => 0,
              :manxxxl => 0
          },
          :is_late_registration => 0,
          :orchestra_ticket => {
              :thursday => 0,
              :friday => 0,
              :saturday => 0
          },
          :orchestra_food_ticket => {
              :thursday => 0,
              :friday => 0,
              :saturday => 0
          },
          :consecutive_10 => 0,
          :attended_25 => 0,
          :instrument_size => {
              :none => 0,
              :very_small => 0,
              :small => 0,
              :medium => 0,
              :large => 0
          }
      }
    end

    def column_names
      {
          :name => 'Orkester',
          :dormitory => 'Sovsalsdagar',
          :medal => 'Medaljer',
          :tag => 'Märken',
          :tshirt => 'T-shirt',
          :orchestra_ticket => 'Festivalbiljetter',
          :orchestra_food_ticket => 'Matbiljetter',
          :is_late_registration => 'Sen anmälan',
          :consecutive_10 => '10 år i rad',
          :attended_25 => '25:e året',
          :user_id => 'Kontaktperson',
          :instrument_size => 'Instrumentstorlek'
      }
    end

    def data_for(item, column)
      value = value_for(item, column)
      increase_total(column, value)
      format_value(column, value)
    end

    def format_value(column, value)
      case column
        when :orchestra_ticket, :orchestra_food_ticket, :dormitory
          total_ticket_str(value)
        when :instrument_size
          total_instrument_str(value)
        when :tshirt
          total_tshirt_str(value)
        else
          value
      end
    end

    def value_for(item, column)
      case column
        when :name
          item.send(column)
        when :user_id
          User.where(id: item.send(column)).pluck(:email).first
        else
          value_for_item(item, column)
      end
    end

    def value_for_item(item, column)
      if column == :orchestra_ticket || column == :orchestra_food_ticket || column == :dormitory
        value = {
            :thursday => 0,
            :friday => 0,
            :saturday => 0
        }
      elsif column == :instrument_size
        value = {
            :none => 0,
            :very_small => 0,
            :small => 0,
            :medium => 0,
            :large => 0
        }
      elsif column == :tshirt
        value = {
            :womenxs => 0,
            :womens => 0,
            :womenm => 0,
            :womenl => 0,
            :womenxl => 0,
            :womenxxl => 0,
            :womenxxxl => 0,

            :manxs => 0,
            :mans => 0,
            :manm => 0,
            :manl => 0,
            :manxl => 0,
            :manxxl => 0,
            :manxxxl => 0
        }
      else
        value = 0
      end

      # Note, this is very bad way to loop through it.
      # This makes us loop through all signups once for each column instead of
      # looping once and handling all columns at once.
      # We could loop once and increase the total accordingly instead.
      item.orchestra_signups.each do |signup|
        case column
          when :is_late_registration, :consecutive_10, :attended_25
            value += 1 if signup.send(column)
          when :medal, :tag
            value += item_article(signup, column)
          when :orchestra_food_ticket, :orchestra_ticket
            if signup.send(column).present?
              increase_hash_total(value, ticket_count_increase_for(signup.send(column).kind))
            end
          when :dormitory
            if signup.send(column)
              increase_hash_total(value, ticket_count_increase_for(signup.send(:orchestra_ticket).kind))
            end
          when :instrument_size
            increase_hash_total(value, instrument_size_increase_for(signup.send(column)))
          when :tshirt
            signup.orchestra_articles.where(kind: 1).each do |article|
              increase_hash_total(value, tshirt_increase_for(article.data))
            end
          else
            value += signup.send(column)
        end
      end
      value
    end

    def extra_row
      column_names.keys.map { |col| total_value_for(col) }
    end

    private

    def increase_total(column, value)
      if @total.has_key? column
        if value.is_a? Numeric
          @total[column] += value
        elsif value.is_a? Hash
          increase_hash_total(@total[column], value)
        elsif value
          @total[column] += 1
        end
      end
    end

    def total_value_for(col)
      case col
        when :name
          'TOTALT'
        when :orchestra_ticket, :orchestra_food_ticket, :dormitory
          total_ticket_str @total[col]
        when :instrument_size
          total_instrument_str @total[col]
        when :tshirt
          total_tshirt_str @total[col]
        else
          @total[col]
      end
    end

    def increase_hash_total(total_field, increments)
      increments.each { |k,v| total_field[k] += v }
    end

    def item_article(item, article_name)
      item.orchestra_articles.where(kind: article_kind_map[article_name]).count
    end

    def item_ticket(item, ticket_type)
      ticket_description_for item.send(ticket_type).kind
    end

    def article_kind_map
      {
          :tshirt => 1,
          :medal => 2,
          :tag => 3
      }
    end

    def ticket_description_for(kind)
      descriptions = {
          0 => 'Torsdag, Fredag, Lördag',
          1 => 'Fredag, Lördag',
          2 => 'Lördag',
          3 => '',
          4 => 'Torsdag, Fredag'
      }

      descriptions[kind]
    end

    def ticket_count_increase_for(kind)
      increments = {
          0 => {
              :thursday => 1,
              :friday => 1,
              :saturday => 1
          },
          1 => {
              :friday => 1,
              :saturday => 1
          },
          2 => {
              :saturday => 1
          },
          3 => {},
          4 => {
              :thursday => 1,
              :friday => 1
          },
      }

      increments[kind]
    end

    def instrument_size_increase_for(kind)
      increments = {
          0 => {
              :none => 1
          },
          1 => {
              :very_small => 1
          },
          2 => {
              :small => 1
          },
          3 => {
              :medium => 1
          },
          4 => {
              :large => 1
          }
      }

      increments[kind]
    end

    def tshirt_increase_for(kind)
      case kind
        when 'Dam XS', 'Female XS'
          {womenxs: 1}
        when 'Dam S', 'Female S'
          {womens: 1}
        when 'Dam M', 'Female M'
          {womenm: 1}
        when 'Dam L', 'Female L'
          {womenl: 1}
        when 'Dam XL', 'Female XL'
          {womenxl: 1}
        when 'Dam XXL', 'Female XXL'
          {womenxxl: 1}
        when 'Dam XXXL', 'Female XXXL'
          {womenxxxl: 1}

        when 'Herr XS', 'Male XS'
          {manxs: 1}
        when 'Herr S', 'Male S'
          {mans: 1}
        when 'Herr M', 'Male M'
          {manm: 1}
        when 'Herr L', 'Male L'
          {manl: 1}
        when 'Herr XL', 'Male XL'
          {manxl: 1}
        when 'Herr XXL', 'Male XXL'
          {manxxl: 1}
        when 'Herr XXXL', 'Male XXXL'
          {manxxxl: 1}
        else
          FaultReport.send("Found unknown t-shirt size: #{kind}")
          {}
      end
    end

    def yes_no(value)
      value ? 'Ja' : 'Nej'
    end

    def total_ticket_str(total_field)
      "Torsdag: #{total_field[:thursday]}, Fredag: #{total_field[:friday]}, Lördag: #{total_field[:saturday]}"
    end

    def total_instrument_str(total_field)
      "Inget: #{total_field[:none]}, Väldigt litet: #{total_field[:very_small]}, Litet: #{total_field[:small]}, Mellan: #{total_field[:medium]}, Stort: #{total_field[:large]}"
    end

    def total_tshirt_str(total_field)
      "Dam/Herr: XS: #{total_field[:womenxs]}/#{total_field[:manxs]}, S: #{total_field[:womens]}/#{total_field[:mans]}, M: #{total_field[:womenm]}/#{total_field[:manm]}, L: #{total_field[:womenl]}/#{total_field[:manl]}, XL: #{total_field[:womenxl]}/#{total_field[:manxl]}, XXL: #{total_field[:womenxxl]}/#{total_field[:manxxl]}, XXXL: #{total_field[:womenxxxl]}/#{total_field[:manxxxl]}"
    end
  end
end