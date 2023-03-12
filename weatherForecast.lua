-- Функция показывает пару ключ-значение, включая случаи, когда
-- значением является другая таблица.
local function printTable(table)
  for idx, val in pairs(table) do
    if val == nil then
      print(idx)
    end
    if type(val) ~= "table" then
      print(idx, val)
    else
      print(idx)
      printTable(val)
    end
  end
end

local https = require("ssl.https")
local json = require("lunajson")
local plaseOfTable = {}
local workingDir = os.getenv("PWD")

--запрос адреса местоположения
::inputLocation:: --Метка запроса
print("Enter location")
local inputLocation = io.read("*l")
local req = "https://www.yr.no/api/v0/locations/search?language=en&q=" .. inputLocation
local body, code, headers, status = https.request(req)

if body ~= nil and code == 200 and headers ~= nil then
  -- если есть ответ - пишем его в json
  plaseOfTable = json.decode(body)
else
  --Если ничего не нашлось, пишем сообщение и заново запускаем запрос местоположения
  print("\nServer not accept your request!")
  print("\tcode : ", code)
  print("\tstatus : ", status)
  if type(headers == "table") then
    for ind, val in ipairs(headers) do
      print(ind, ":", val)
    end
  elseif type(headers == "string") then print(headers)
  else print(headers)
  end
  print("Repeat your request, please!\n")
  goto inputLocation -- Перемещаемся к метке
  return
end

--узнаем количество найденных местоположений. Если местоположение
--не найдено, просим повторить запрос
local intCount
for k, v in pairs(plaseOfTable) do
  if k == "totalResults" then intCount = v end
end
if intCount == 0 then print("Местоположение не найдено. Повторите запрос!") goto inputLocation end

--создадим таблицу и заполним её в формате: ключ(это местоположение)->другая таблица, внутри
--которой координаты местоположений
local tableOfSearch = {}
for i = 1, intCount do
  local urlPath = plaseOfTable["_embedded"]["location"][i]["urlPath"]
  local location = plaseOfTable["_links"]["location"][i]["href"]
  local lat = plaseOfTable["_embedded"]["location"][i]["position"]["lat"]
  local lon = plaseOfTable["_embedded"]["location"][i]["position"]["lon"]
  local elevation = plaseOfTable["_embedded"]["location"][i]["elevation"]
  tableOfSearch[i] = {
    { new_location = urlPath },
    { lat = lat },
    { lon = lon },
    { elevation = elevation },
    { location = location }
  }
end

-- Выводим список местоположений и спрашиваем, какое из них интересует. После выбора печатаем
-- это местоположение.
-- Для получение forecast/currenthour, создадим переменную, в которую запишем выбранный location
-- и прибавим forecast/currenthour.
local forecastCurrenthour
local iChice = false
local choice
while not iChice do
  for g = 1, intCount do
    print(g, tableOfSearch[g][1]["new_location"] .. "\n" .. tableOfSearch[g][5]["location"])
  end
  print()
  print("\n", "Look at the list and answer me: what location do you need (enter the number)?")
  choice = assert(io.read("*n"), "Only number in accepted!")
  print("\n", "You choise " .. "\"" .. tableOfSearch[choice][1]["new_location"] .. "\"\n")
  forecastCurrenthour = "https://www.yr.no:443" .. tableOfSearch[choice][5]["location"] .. "/forecast/currenthour"
  iChice = true
end

-- Записываем координаты в переменные и печатаем их
local lat, lon, elevation
lat = tableOfSearch[choice][2]["lat"]
lon = tableOfSearch[choice][3]["lon"]
elevation = tableOfSearch[choice][4]["elevation"]
print("Object coordinate is\n ", "lat = " .. lat .. "\n", "lon = " ..
  lon .. "\n", "elevation = " .. elevation .. "\n")

-- Запрашиваем у сервера json с данными о погоде
local ltn12 = require("ltn12")
https.TIMEOUT = 10
local link = "https://api.met.no:443/weatherapi/locationforecast/2.0/complete?altitude=" ..
    elevation .. "&lat=" .. lat .. "&lon=" .. lon
local resp = {}
local bodyYrNo, codeYrNo, headersYrNo = https.request {
  url = link,
  headers = {
    --user-agent используется для идентификации на сервере. Но на самом деле работает любой.
    ["user-agent"] = "acmeweathersite.com  support@acmeweathersite.com";
    ['Connection'] = 'close',
    ["content-type"] = "application/json",
  },
  sink = ltn12.sink.table(resp)
}

print("\n", "Technical information from server:\n")

if codeYrNo ~= 200 then
  print("Error: " .. (codeYrNo or ''))
  return
end
print("Status:", bodyYrNo and "OK" or "FAILED")
print("HTTP code:", codeYrNo)
print("Response headers:")
if type(headersYrNo) == "table" then
  for k, v in pairs(headersYrNo) do
    print(k, ":", v)
  end
end

https.TIMEOUT = 10
local forecastCurrentHourTable = {}

local bodyCurentHour, codeCurentHour, headersCurentHour = https.request {
  url = forecastCurrenthour,
  headers = {
    --user-agent используется для идентификации на сервере. Но на самом деле работает любой.
    ["user-agent"] = "acmeweathersite.com  support@acmeweathersite.com";
    ['Connection'] = 'close',
    ["content-type"] = "application/json",
  },
  sink = ltn12.sink.table(forecastCurrentHourTable)
}

--Записываем данные в соответствующие Json файлы
local openweatherjsonfile = assert(io.open(workingDir .. "/body.json", "w"), "can't open file body.json! may be not exist?")
openweatherjsonfile:write(table.concat(resp))
openweatherjsonfile:close()

local curentHourJsonFile = assert(io.open(workingDir .. "/curentHour.json", "w"),
  "can't open file curentHour.json! may be not exist?")
curentHourJsonFile:write(table.concat(forecastCurrentHourTable))
curentHourJsonFile:close()


-- Функция возвращает размер переданного файла
local function fileSize(fileName)
  local current = fileName:seek() -- get current position
  local size = fileName:seek("end") -- get file size
  fileName:seek("set", current) -- restore position
  return size
end

local openWeatherJsonFileAgain = assert(io.open(workingDir .. "/body.json", "r"), "Can't openWeatherJsonFileAgain")
local size = fileSize(openWeatherJsonFileAgain)
if size == 0 then print("File body.json don't download") return end
local content = assert(openWeatherJsonFileAgain:read("*a"), "Can't read the file")
local TableOfWeather = {}; -- В эту таблицу конвертируется json
TableOfWeather = assert(json.decode(content), "Can't decode json file")
openWeatherJsonFileAgain:close()

local openCurentHourJsonFile = assert(io.open(workingDir .. "/curentHour.json", "r"), "Can't openCurentHourJsonFile")
local sizeCurentHourJsonFile = fileSize(openCurentHourJsonFile)
if sizeCurentHourJsonFile == 0 then print("File curentHour.json don't download") return end
local contentCurentHour = assert(openCurentHourJsonFile:read("*a"), "Can't read the file")
local TableCurentHour = {}; -- В эту таблицу конвертируется json
TableCurentHour = assert(json.decode(contentCurentHour), "Can't decode json file")
openCurentHourJsonFile:close()


-- Цикл устанавливает соответствие между текущем временем\датой и
-- соответствующим ключом/позицией в TableOfWeather
local systemTime = os.date("!%dT%H:")
local position
for i = 1, 20 do
  local timeStr = TableOfWeather["properties"]["timeseries"][i]["time"]
  if string.find(timeStr, systemTime) ~= nil then
    position = i
  end
end

local tempRightNow = TableOfWeather["properties"]["timeseries"][position]["data"]["instant"]["details"][
    "air_temperature"]
local max6Temp = TableOfWeather["properties"]["timeseries"][position]["data"]["next_6_hours"]["details"][
    "air_temperature_max"]
local precipitationAmountSixHours = TableOfWeather["properties"]["timeseries"][position]["data"]["next_6_hours"][
    "details"]["precipitation_amount"]
local min6Temp = TableOfWeather["properties"]["timeseries"][position]["data"]["next_6_hours"]["details"][
    "air_temperature_min"]
local cloudAreaFraction = TableOfWeather["properties"]["timeseries"][position]["data"]["instant"]["details"][
    "cloud_area_fraction"]
--     "details"]["precipitation_amount"]
local symbolCodeOneOurs = TableOfWeather["properties"]["timeseries"][position]["data"]["next_1_hours"]["summary"][
    "symbol_code"]
local symbolCodeSixOurs = TableOfWeather["properties"]["timeseries"][position]["data"]["next_6_hours"]["summary"][
    "symbol_code"]
local symbolCode_12_Hours = TableOfWeather["properties"]["timeseries"][position]["data"]["next_12_hours"]["summary"][
    "symbol_code"]
local wind = TableOfWeather["properties"]["timeseries"][position]["data"]["instant"]["details"]["wind_from_direction"]
local precipitation_amount = TableOfWeather["properties"]["timeseries"][position + 1]["data"]["next_1_hours"]["details"]
    [
    "precipitation_amount"]
local relative_humidity = TableOfWeather["properties"]["timeseries"][position]["data"]["instant"]["details"][
    "relative_humidity"]
local wind_speed = TableOfWeather["properties"]["timeseries"][position]["data"]["instant"]["details"]["wind_speed"]

-- Добавляется модуль переводчика
local packegePath = ";" .. workingDir .. "/?.lua"
package.path = packegePath 
local trans = require("translate")
print()
-- вычисляется текущее время
local t = TableOfWeather["properties"]["timeseries"][position]["time"]
local timeFoundNow = t:find("T")
local timeRightNow = t:sub(timeFoundNow + 1, 19)
print("\tСейчас (" .. timeRightNow .. " в " .. tableOfSearch[choice][1]["new_location"] .. ") на улице")
print("Температура ", tempRightNow .. " °C", "\tОщущается как ",
  TableCurentHour["temperature"]["feelsLike"] .. " °C")
print("Ветер\t", wind_speed .. " м/с", "\tВлажность", relative_humidity .. " %")
print("Направление ", trans.wind_direction(wind), "Осадки\t", precipitation_amount .. " мм")
print("Облачность ", cloudAreaFraction .. " %")
print("\n", "Ближайшее время", "\t" .. trans.translate(symbolCodeOneOurs) .. "\n")

-- Нужна таблица, которая будет хранить время в качества ключа, и величину
-- осадков через час + текущую температуру в качестве значения этого ключа. В
-- качестве аргумента передаю переменную, которая соответствует текущему времени\даты и
-- соответствующим ключом/позицией в json (position)

local tblRainSleetSnow = {}
local function rainSleetSnow(p)
  for m = p, p + 12 do
    -- Так как значение осадков можно взять только из поля next_1_hours, для корректной
    -- информации нужно взять это значение из информации по предыдущему часу
    local weatherCharacteristics = TableOfWeather["properties"]["timeseries"][p]["data"]["next_1_hours"]["summary"][
        "symbol_code"]
    local precipitation_amountNextOneHours = TableOfWeather["properties"]["timeseries"][m - 3]["data"]["next_1_hours"][
        "details"
        ][
        "precipitation_amount"]
    local air_temperature_now = TableOfWeather["properties"]["timeseries"][m]["data"]["instant"]["details"][
        "air_temperature"]
    relative_humidity = TableOfWeather["properties"]["timeseries"][m]["data"]["instant"]["details"][
        "relative_humidity"]
    wind_speed = TableOfWeather["properties"]["timeseries"][m]["data"]["instant"]["details"]["wind_speed"]
    wind = TableOfWeather["properties"]["timeseries"][m]["data"]["instant"]["details"]["wind_from_direction"]
    local timeStart = TableOfWeather["properties"]["timeseries"][m]["time"]
    local timeFoundT = timeStart:find("T") -- Нужно найти и вырезать Т
    local timeTime = timeStart:sub(timeFoundT + 1, 19) -- Время без Z
    local timeDate = timeStart:sub(1, timeFoundT - 1) -- Дата без Т
    local timeDateTime = timeDate .. " в " .. timeTime -- Т заменяется на " в "

    -- Если прогнозируются осадки - включить осадки в вывод на терминал
    if precipitation_amountNextOneHours > 0 then
      tblRainSleetSnow[timeDateTime] =
      {
        precipitation_amount = "> " .. precipitation_amountNextOneHours .. " мм <",
        air_temperature_now = air_temperature_now .. " °C",
        wind_speed = "        " .. wind_speed .. " мс",
        wind_direction = "        " .. trans.wind_direction(wind),
        relative_humidity = relative_humidity .. " %",
        weatherCharacteristics = trans.translate(weatherCharacteristics),
      }
    else
      tblRainSleetSnow[timeDateTime] =
      {
        air_temperature_now = air_temperature_now .. " °C",
        wind_speed = "        " .. wind_speed .. " мс",
        wind_direction = "        " .. trans.wind_direction(wind),
        relative_humidity = relative_humidity .. " %",
        weatherCharacteristics = trans.translate(weatherCharacteristics),
      }
    end
  end
end

-- Использую вышеназванную функцию
rainSleetSnow(position)

-- Нужна таблица, кторая будет хронить только ключи из tblRainSleetSnow. Потом они
-- сортируются, и происходит вызов tblRainSleetSnow с ключом из новой СОРТИРОВАННОЙ таблицы.
local tblSortKeyForTblRainSleetSnow = {}
for w in pairs(tblRainSleetSnow) do table.insert(tblSortKeyForTblRainSleetSnow, w) end
table.sort(tblSortKeyForTblRainSleetSnow, function(aa, b) return aa < b end)
for _, k in ipairs(tblSortKeyForTblRainSleetSnow) do
  print(k)
  print(printTable(tblRainSleetSnow[k]))
end

print("Через 6 часов", trans.translate(symbolCodeSixOurs),
  trans.nex6AvgTemp(min6Temp, max6Temp) .. " °C")
print("Объём осадков", precipitationAmountSixHours .. " мм")
print("Через 12 часов", trans.translate(symbolCode_12_Hours))
