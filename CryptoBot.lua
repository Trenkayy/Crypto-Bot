local http = require("socket.http")
local Json = require("json")

local coins = {"bitcoin", "etherium", "solana", "xrp", "tether", "tron",}
local vs_currency = "usd"

function fetch_prices()
    local url = "https://api.coingecko.com/api/v3/simple/price?ids=" .. table.concat(coins, ",") .. "&vs_currencies=" .. vs_currency
    local response, status = http.request(url)
    
    if status == 200 then
        local data = json.decode(response)
        return data
    else
        print("Failed to fetch current prices.")
        return nil
    end
end

function get_historical_prices(coin, days)
    local url = "https://api.coingecko.com/api/v3/coins/" .. coin .. "/market_chart?vs_currency=usd&days=" .. days
     local response, status = http.request(url)
     
    if status == 200 then
        local data = json.decode(response)
        local prices, volumes = {}, {}

        for _, entry in ipairs(data.prices) do table.insert(prices, entry[2]) end
        for _, entry in ipairs(data.total_volumes) do table.insert(volumes, entry[2]) end 

        return prices, volumes
    else
        print("Failed to fetch historical data for " .. coin)
        return nil, nil
    end
end

local calculate_sma(prices, period)
    if #prices < perdiod then return nil end
    local sum = 0
    for i = #prices - period + 1, #prices do
        sum = sum + prices[i]
    end
    return sum / period
end

function calculate_ema(prices, period)
    if #prices < period then return nil end
    local multiplier = 2 / (period + 1)
    local ema = prices[#prices - period + 1]

    for i = #prices - period + 2, #prices do
        ema = (prices[i] - ema) * multiplier + ema
    end

    return ema
end

function calculate_rsi(prices, period)
    if #prices < period then return nil end
    local gains, losses = 0, 0

    for i = #prices - period + 1, #prices do
        local change = prices[i] - prices[i-1]
        if change > 0 then gains = gains + change else losses = losses - change end
    end

    if losses == 0 then return 100 end
    local rs = gains / losses
    return 100 - (100 / (1 +rs))
end

function calculate_macd(prices)
    local ema_12 = calculate_ema(prices, 12)
    local ema_26 = calculate_ema(prices, 26)
    if not ema _12 or not ema_26 then return nil end
    return ema_12 - ema_26
end

function analyze_volume(volume data)
    if #volume_data < 2 then return "N/A" end
    return volume_data[#volume_data] > volume_data[#volume_data -1] and "📈 Increasing" or "📉 Decreasing"
end

for _, coin in ipairs(coins) do
    local prices = get_historical_prices(coin, 30)
    if prices then
        local sma_7 = calculate_sma(prices, 7)
        local sma_30 = calculate_sma(prices, 30)
        print(coin .. "SMA-7: $" .. (sma_7 or "N/A") .. ", SMA-30: $" .. (sma_30 or "N/A"))
    end
end

function log_prices(prices)
    local file = io.open("crypto_prices.log", "a") 
    if not file then
        print("Error opening log file.")
        return
    end
    
    local timestamp = os.date("%Y-%m-%d %H:%M:%S") -- Get current time
    file:write("=== " .. timestamp .. " ===\n")
    
    for coin, price in pairs(prices) do
        file:write(coin .. ": $" .. price .. "\n")
    end

    file:write("\n") -- Newline for readability
    file:close()
end

function log_signals(signals)
    local file = io.open("crypto_signals.log", "a")
    if not file then
        print("Error opening signal log file.")
        return
    end

    local timestamp = os.date("%Y-%m-%d %H:%M:%S")
    file:write("=== " .. timestamp .. " ===\n")

    for coin, signal in pairs(signals) do
        file:write(coin .. ": " .. signal .. "\n")
    end

    file:write("\n")
    file:close()
end

while true do
    print("🔄 Fetching crypto data...")

    local signals = {}

    for _, coin in ipairs(coins) do
        local historical_prices, volume_data = get_historical_data(coin, 30)

        if historical_prices and volume_data then
            local sma_7 = calculate_sma(historical_prices, 7)
            local sma_30 = calculate_sma(historical_prices, 30)
            local rsi = calculate_rsi(historical_prices, 14)
            local macd = calculate_macd(historical_prices)
            local volume_trend = analyze_volume(volume_data)

            local signal = ""
            if sma_7 and sma_30 then
                if sma_7 > sma_30 then
                    signal = signal .. "🚀 Buy " .. coin .. " (SMA-7 above SMA-30) "
                elseif sma_7 < sma_30 then
                    signal = signal .. "⚠️ Sell " .. coin .. " (SMA-7 below SMA-30) "
                else
                    signal = signal .. "Hold " .. coin .. " (SMA-7 == SMA-30) "
                end
            end

            if rsi then
                if rsi > 70 then
                    signal = signal .. "🔥 Overbought (RSI: " .. rsi .. ") "
                elseif rsi < 30 then
                    signal = signal .. "🧊 Oversold (RSI: " .. rsi .. ") "
                end
            end

            if macd then
                if macd > 0 then
                    signal = signal .. "📈 MACD Bullish (MACD: " .. macd .. ") "
                else
                    signal = signal .. "📉 MACD Bearish (MACD: " .. macd .. ") "
                end
            end

            signal = signal .. "📊 Volume: " .. volume_trend

            signals[coin] = signal

            -- **Send Discord & Telegram Alerts**
            if signal:find("🚀 Buy") or signal:find("⚠️ Sell") then
                send_discord_alert("🚨 **Crypto Alert** 🚨\n" .. signal)
                send_telegram_alert("🚨 **Crypto Alert** 🚨\n" .. signal)
            end
        end
    end

    log_signals(signals)

    print("✅ Data fetched and analyzed. Sleeping for 1 hour...")
    os.execute("sleep 3600") -- Wait 1 hour before the next run
end

local DISCORD_WEBHOOK_URL = "https://discord.com/api/webhooks/1354410984298512464/xTwsBSnNhKyWY3ocydceDgiLT-RhTYSUgZ_hRI4ZmNSwStRlw1LnZ5zL3It7cOJAKPiB"

function send_discord_alert(message)
    local payload = json.encode({content = message})  -- Format for Discord
    local response, status = http.request(DISCORD_WEBHOOK_URL, payload)

    if status == 200 then
        print("📩 Discord alert sent!")
    else
        print("❌ Failed to send Discord alert.")
    end
end

function backtest(coin, days, intial_balance)
    local prices = get_historical_prices(coin, days)
    if not prices then 
        print("❌ No data for " .. coin)
        return
    end

    local balance = intial_balance
    local holding = false
    local buy_price = 0

    for i = 30. #prices do 
        local sma_7 = calculate_sma(prices, 7, i)
        local sma_30 = calculate_sma(prices, 30, i)

        if sma_7 and sma_30 then
            if sma_7 > sma_30 and not holding then
                buy_price = prices[i]
                holding = true
                print("📈 Bought " .. coin .. " at $" .. buy_price)
            elseif sma_7 < sma_30 and holding then
                local sell_price = prices[i]
                balance = balance + (sell_price - buy_price)
                holding = false
                print("📉 Sold " .. coin .. " at $" .. sell_price .. "| New Balance: $" .. balance)
            end
        end
    encode

    print("💰 Final balance after backtest: $" .. balance) 
end
