require "colorize"
require "tty-prompt"
require "tty-progressbar"
require "tty-cursor"
require "tty-table"
require_relative "./Helpers.rb"
require_relative "../models/market/Catalogue.rb"
require_relative "../models/market/SecurityPricing.rb"

include Market

module Views
    module Trading
        def self.get_trade(user)
            # quick_trade if ARGV[0] =~ /^-t(rade)*/

            while true
                system 'clear'
                STDIN.iflush
                
                cash = user.file[:holdings][:CASH][0]
                
                holdings = []
                user.file[:holdings].each_pair {|k,v| (holdings << [k,number_comma(v[0])]) unless k == :CASH}

                tty_cursor = TTY::Cursor
                tty_bar = TTY::ProgressBar.new("Executing Trade [:bar]", total: 20, bar_format: :block)
                tty_prompt = TTY::Prompt.new
                tty_table = TTY::Table.new(header: [" Security ", " Quantity "], rows: holdings)

                puts "Welcome to the trading platform, #{user.file[:username]}!"
                (puts "Your current holdings are as follows:"; puts tty_table.render(:unicode, alignment: [:center, :right])) unless holdings == []
                trade_type = tty_prompt.select("You currently have #{("$"+number_comma(cash)).light_green} to play with.\nWill you be intending to make a buy order or a sell order?\n", {Buy: :buy, Sell: :sell, Exit: :exit}, show_help: :always)
                break if trade_type == :exit

                trade_ticker = tty_prompt.select("\n#{trade_type ? "Time to put your money where your mouth is!" : "Never hang on to a loser!"}\nWhich security would you like to transact with today?\n", Catalogue::TICKERS[1..Catalogue::TICKERS.length], cycle: true, show_help: :always)
                locked_price = SecurityPricing.prices(trade_ticker)[:current]
                puts "\nGreat choice! Our brokers have locked in a unit price of #{("$"+number_comma(locked_price)).light_green} for you."
                
                case trade_type
                    when :buy
                        (puts "\nHowever, it appears that you have insufficient cash to fund this purchase.\nConsider liquidating some of your existing holdings if you wish to make further purchases."; sleep_keypress(10,STDIN); next) if cash < locked_price
                        puts "With your current cash balance, you can purchase a maximum of #{(number_comma((cash/locked_price).floor.to_i)).light_cyan} shares of #{trade_ticker.to_s.light_blue}."
                        puts "How much #{trade_ticker.to_s.light_blue} would you like to order today?"
                        
                        i = 0
                        while true
                            trade_qty = Input.get("int")
                            break if trade_qty <= cash/locked_price
                            i == 0 ? (puts "You don't have enough cash for that! Please try a different number.") : (print tty_cursor.clear_lines(2))
                            i += 1
                        end
                        
                        puts; confirmed = tty_prompt.yes?("Confirming you would like to purchase #{number_comma(trade_qty).light_cyan} shares of #{trade_ticker.to_s.light_blue}, at a unit price of #{("$"+number_comma(locked_price)).light_green} for a total of #{("$"+number_comma(locked_price*trade_qty)).light_green}?") {|q| q.suffix "y/n"}
                        puts; confirmed ? (tty_cursor.invisible{20.times {sleep 0.1;tty_bar.advance}}; puts "Trade executed successfully!"; yield [trade_ticker, trade_qty, locked_price] ; yield [:CASH, -(trade_qty*locked_price), 1]) : next
                        puts; tty_prompt.yes?("Would you like to execute further trades?") {|q| q.suffix "y/n"} ? next : break
                    when :sell
                        # (puts "\nHowever, it appears that you do not have any existing holdings of the selected security.\n"; sleep_keypress(10,STDIN); next) if 

                end

                # test stacked input errors
                # p trade_type; p trade_ticker
                # insufficient cash/stock logic
                # LAST IN FIRST OUT - sell behaviour - traverse trade history
            end
        end

        def quick_trade
            # quick route to trade section in control flow
        end
    end
end