
function getStarCoords(data, index, baseZoom)
    if index > 6400 then
        if index >= 1000001 then
            index = index - 993600
        else
            return nil
        end
    end

    local star = data.coordinates[index + 1]
    if not star then return nil end

    local x, y = star[1] * baseZoom, star[2] * baseZoom
    return x, y
end

function drawHexagon(mode, centerX, centerY, radius, rotation, rotationOffset)
    local vertices = {}

    for i = 0, 5 do
        local angle =
            i * math.pi / 3 +
            math.pi / 6 +
            rotation +
            rotationOffset

        table.insert(vertices, centerX + radius * math.cos(angle))
        table.insert(vertices, centerY + radius * math.sin(angle))
    end

    love.graphics.polygon(mode, vertices)
end

function printTable(t, indent)
    indent = indent or 0
    local indentStr = string.rep("  ", indent)

    if type(t) ~= "table" then
        print(indentStr .. tostring(t))
        return
    end

    for key, value in pairs(t) do
        if type(value) == "table" then
            print(indentStr .. tostring(key) .. " = {")
            printTable(value, indent + 1)
            print(indentStr .. "}")
        else
            print(indentStr .. tostring(key) .. " = " .. tostring(value))
        end
    end
end

local epoch = 67

function getMainSequenceSize(star)
    local mass = star.Mass
    local special = star.Special or 0
    local baseSize

    if special == 3 then
        baseSize = 2.0
    elseif special == 1 then
        if mass > 1.4 then
            baseSize = (mass + 3) * 0.4 * 2
        else
            baseSize = (mass + 3) * 0.425 * 2
        end
    elseif special == 2 then
        local v8 = mass + 3 + 14
        baseSize = v8 * 24.2 / 25 * 2
    else
        baseSize = (mass + 3) * 2
    end

    return baseSize / 10
end

function getValue3(star)
    local special = star.Special or 0
    local binary = star.Binary or false
    local value2 = getMainSequenceSize(star)
    local value3 = value2 * 0.5

    if binary then
        if special == 1 then
            value3 = value2 * 3.5 + 2
        elseif special == 3 then
            value3 = value2 * 10 + 10
        else
            value3 = value2 * 1.5 + 1
        end
    elseif special == 3 then
        value3 = value2 * 10 + 5
    end

    return value2, value3
end

function getPlanetPosition(planet, star)
    local value2, value3 = getValue3(star)

    local orbitalRadius = planet.SemiMajorAxis * 18 + value3
    local orbitalPeriod = (orbitalRadius * math.sqrt(orbitalRadius)) / star.Mass / 2

    local currentTime = epoch + os.clock()
    local angle = math.fmod(currentTime / orbitalPeriod, math.pi * 2)

    local x = math.cos(angle) * orbitalRadius * 10
    local y = math.sin(math.random(-42,67)) * orbitalRadius * 10 -- :P
    local z = math.sin(angle) * math.cos(inclination) * orbitalRadius * 10

    return x, y, z
end

local function ClassFromMass(mass)
    local t, letter
    if mass > 4 then
        t = (mass - 4) / 3
        letter = "O"
    elseif mass > 2.1 then
        t = (mass - 2.1) / 1.9
        letter = "B"
    elseif mass > 1.4 then
        t = (mass - 1.4) / 0.7
        letter = "A"
    elseif mass > 1.04 then
        t = (mass - 1.04) / 0.36
        letter = "F"
    elseif mass > 0.8 then
        t = (mass - 0.8) / 0.24
        letter = "G"
    elseif mass > 0.45 then
        t = (mass - 0.45) / 0.35
        letter = "K"
    elseif mass > 0.15 then
        t = (mass - 0.15) / 0.3
        letter = "M"
    elseif mass > 0.1 then
        t = (mass - 0.1) / 0.05
        letter = "L"
    elseif mass > 0.06 then
        t = (mass - 0.06) / 0.03
        letter = "T"
    else
        t = mass / 0.06
        letter = "Y"
    end
    return letter, math.floor(10 - t * 10)
end

function SpectralClassification(star)
    local result
    local special = star.Special or 0

    if special == 1 then
        if star.Mass > 3 then
            result = "III"
        elseif star.Mass > 2.2 then
            result = "II"
        elseif star.Mass > 1.3 then
            result = "I"
        else
            local subclass = math.floor(10 - (star.Mass - 0.5) / 0.83 * 10)
            result = "DA" .. subclass
        end
    elseif special == 2 then
        local letter, subclass = ClassFromMass(star.Mass / 2)
        local luminosity = star.Mass > 3 and "II" or "III"
        result = string.format("%s%d%s", letter, subclass, luminosity)
    elseif special == 3 then
        result = "Q"
    else
        local letter, subclass = ClassFromMass(star.Mass)
        result = string.format("%s%d", letter, subclass)
        if star.Mass > 0.15 then
            result = result .. "V"
        end
    end

    if not star.Binary then
        return result
    end

    local companionMass = star.Mass * star.CompanionMassFactor
    local letter, subclass = ClassFromMass(companionMass)
    local companion = string.format("%s%d", letter, subclass)
    if companionMass > 0.15 then
        companion = companion .. "V"
    end

    return result .. " & " .. companion
end

local oceanColors = {
    None    = {20, 50, 100, 255},
    Lava    = {255, 119, 0, 255},
    Water   = {20, 50, 100, 255},
    Blood   = {196, 40, 28, 255},
    Acid    = {75, 151, 75, 255},
    Ammonia = {107, 50, 124, 255},
    Methane = {0, 255, 255, 255},
    Air     = {86, 66, 54, 255},
}

function GetPlanetIconData(systemId, planetIndex, planet)
    local result = {
        landId = nil,
        oceanColor = nil,
        cloudName = nil,
        color = nil,
    }

    result.landId = ((systemId * 10 + planetIndex) % 3) + 1

    local color = oceanColors[planet.Ocean] or oceanColors.None

    result.oceanColor = {
        color[1] / 255,
        color[2] / 255,
        color[3] / 255,
        color[4] / 255,
    }

    if planet.Atmosphere == "Terran" then
        result.cloudName = "terran"
    elseif planet.Atmosphere == "Steam" then
        result.cloudName = "steam"
    end

    local sourceColor = {R=0,G=0,B=0}

    if planet.Tectonics == "Jovian" or not planet.Life then
        sourceColor = planet.GroundColor
    else
        sourceColor = planet.GrassColor
    end

    result.color = {
        sourceColor.R,
        sourceColor.G,
        sourceColor.B,
        1
    }

    return result
end

function getStarColors(star)
    local mass = star.Mass
    local special = star.Special or 0

    if special == 3 or star.Id == 0 then
        return
            {0, 0, 0},
            {255, 181, 62},
            {255, 181, 62},
            {255, 107, 49}
    end

    if special == 1 then
        if mass > 1.4 then
            return
                {255, 157, 253},
                {255, 120, 225},
                {255, 120, 225},
                {228, 158, 255}
        else
            return
                {255, 255, 255},
                {240, 240, 255},
                {200, 210, 255},
                {176, 185, 200}
        end
    end

    local m = special == 2 and mass / 2 or mass

    if m > 4 then
        return
            {228,205,255},
            {150,150,255},
            {154,147,255},
            {100,0,150}

    elseif m > 2.1 then
        return
            {202,251,255},
            {100,150,255},
            {119,114,255},
            {100,100,200}

    elseif m > 1.4 then
        return
            {255,228,228},
            special == 2 and {255,161,161} or {255,180,180},
            {255,178,178},
            {100,100,200}

    elseif m > 1.04 then
        return
            {255,255,255},
            special == 2 and {255,252,153} or {245,255,179},
            {253,255,213},
            {180,173,146}

    elseif m > 0.8 then
        return
            {248,255,213},
            special == 2 and {255,205,6} or {253,255,142},
            {255,227,117},
            {150,100,0}

    elseif m > 0.45 then
        return
            {255,225,184},
            special == 2 and {255,64,0} or {255,120,0},
            special == 2 and {255,42,0} or {255,65,0},
            {150,25,0}

    elseif m > 0.15 then
        return
            {255,191,183},
            special == 2 and {245,39,53} or {255,79,88},
            special == 2 and {180,37,47} or {180,35,90},
            special == 2 and {125,0,29} or {162,0,113}

    elseif m > 0.1 then
        return
            {239,179,0},
            {255,200,100},
            {255,127,76},
            {125,28,28}

    elseif m > 0.07 then
        return
            {175,61,141},
            {200,70,160},
            {255,126,184},
            {125,50,90}

    else
        return
            {31,34,77},
            {91,34,12},
            {188,71,42},
            {80,23,23}
    end
end

local function rgbToHsv(r, g, b)
    local max = math.max(r, g, b)
    local min = math.min(r, g, b)
    local h, s, v
    v = max

    local d = max - min
    s = (max == 0) and 0 or (d / max)

    if max == min then
        h = 0
    else
        if max == r then
            h = (g - b) / d + (g < b and 6 or 0)
        elseif max == g then
            h = (b - r) / d + 2
        elseif max == b then
            h = (r - g) / d + 4
        end
        h = h / 6
    end

    return h, s, v
end

local function hsvToRgb(h, s, v)
    local i = math.floor(h * 6)
    local f = h * 6 - i
    local p = v * (1 - s)
    local q = v * (1 - f * s)
    local t = v * (1 - (1 - f) * s)

    local i6 = i % 6
    if i6 == 0 then return v, t, p
    elseif i6 == 1 then return q, v, p
    elseif i6 == 2 then return p, v, t
    elseif i6 == 3 then return p, q, v
    elseif i6 == 4 then return t, p, v
    elseif i6 == 5 then return v, p, q
    end
end

function shiftHue(r, g, b, hueShift)
    local h, s, v = rgbToHsv(r, g, b)
    h = (h + hueShift) % 1
    return hsvToRgb(h, s, v)
end
