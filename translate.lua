#!/usr/bin/env lua

---
---Возвращает перевод переданной строки на русский язык.
---
---@param word string
---@return string
---@nodiscard
local function translate(word)
  if word == "snow" then return "Снег"
  elseif word == "lightsnow" then return "Слабый снег"
  elseif word == "cloudy" then return "Облачно"
  elseif word == "sleet" then return "Дождь + снег"
  elseif word == "lightrain" then return "Слабый дождь"
  elseif word == "rain" then return "Дождь"
  elseif word == "heavyrain" then return "Ливень"
  elseif word == "lightsleet" then return "Лёгкий дождь+снег"
  elseif word == "lightsnowshowers_day" then return "Слабый снег"
  elseif word == "snowshowers" then return "Снегопад"
  elseif word == "lightsnowshowers" then return "Небольшой снегопад"
  elseif word == "partlycloudy" then return "Переменная облачность"
  elseif word == "partlycloudy_day" then return "Переменная облачность"
  elseif word == "partlycloudy_night" then return "Переменная облачность"
  elseif word == "clearsky" then return "Безоблачно"
  elseif word == "fair" then return "Ясно"
  elseif word == "fair_night" then return "Безоблачная ночь"
  elseif word == "fog" then return "Туман"
  elseif word == "heavyrainandthunder" then return "Сильный дождь и гром"
  elseif word == "heavyrainshowers" then return "Ливень"
  elseif word == "heavyrainshowersandthunder" then return "Проливной дождь+гром"
  elseif word == "heavysleet" then return "Сильный мокрый снег"
  elseif word == "heavysleetandthunder" then return "Сильный мокрый снег+гром"
  elseif word == "heavysleetshowers" then return "Сильный дождь+мокрый снег"
  elseif word == "heavysleetshowersandthunder" then return "Сильный дождь+мокрый снег+гром"
  elseif word == "sleetshowers" then return "Ледяной дождь"
  elseif word == "heavysnow" then return "Сильный снег"
  elseif word == "heavysnowandthunder" then return "Сильный снег+гром"
  elseif word == "heavysnowshowers" then return "Сильный снегопад"
  elseif word == "heavysnowshowersandthunder" then return "Сильный снегопад и гром"
  elseif word == "lightrainandthunder" then return "Небольшой дождь и гром"
  elseif word == "rainandthunder" then return "Дождь и гром"
  elseif word == "rainshowers" then return "Ливневые дожди"
  elseif word == "lightrainshowers" then return "Небольшой ливневый дождь"
  elseif word == "lightrainshowersandthunder" then return "Небольшой дождь, ливень+гром"
  elseif word == "rainshowersandthunder" then return "Ливневый дождь+гром"
  elseif word == "lightsleetandthunder" then return "Небольшой мокрый снег+гром"
  elseif word == "lightsleetshowers" then return "Небольшой дождь+мокрый снег"
  elseif word == "lightsnowandthunder" then return "Небольшой снег и гром"
  elseif word == "lightssleetshowersandthunder" then return "Небольшой дождь+мокрый снег+гром"
  elseif word == "lightssnowshowersandthunder" then return "Небольшой дождь+мокрый снег+гром"
  elseif word == "clearsky_day" then return "Безоблачный день"
  elseif word == "clearsky_night" then return "Безоблачная ночь"
  elseif word == "fair_day" then return "Солнечный день"
  elseif word == "lightrainshowers_night" then return "Ночь с лёгким дождём"
  elseif word == "rainshowers_night" then return "Ночной ливневый дождь"
  elseif word == "lightrainshowers_day" then return "День с лёгким дождём"
  elseif word == "precipitation_amount" then return "Объём осадков"
  elseif word == "precipitation_amountNextOneHours" then return "Объём осадков"
  end
  return "Nothing return translate"
end

---
---Возвращает перевод числового значения направления в текстовое на русском языке.
---
---@param argument number
---@return string
---@nodiscard
local function wind_direction(argument)
  if argument >= 337 and argument <= 360 then return "Северное"
  elseif argument >= 0 and argument < 22 then return "Северное"
  elseif argument >= 22 and argument < 67 then return "Северо-Восток"
  elseif argument >= 67 and argument < 112 then return "Восточное"
  elseif argument >= 112 and argument < 157 then return "Юго-Восточное"
  elseif argument >= 157 and argument < 202 then return "Южное"
  elseif argument >= 202 and argument < 247 then return "Юго-Западное"
  elseif argument >= 247 and argument < 292 then return "Западное"
  elseif argument >= 292 and argument < 337 then return "Северо-Запад"
  end
  return "Nothing return wind_direction"
end

local function nex6AvgTemp(minTemp, maxTemp)
  local middle = minTemp + maxTemp
  return middle / 2
end

return { translate = translate, wind_direction = wind_direction, nex6AvgTemp = nex6AvgTemp }
