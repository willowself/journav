json = require "libraries/json"
hump = require "libraries/hump"

smokeModule = require "Cogs/smoke"
nucleusModule = require "Cogs/nucleus"
starModule = require "Cogs/star"
planetModule = require "Cogs/planet"
helpers = require "Cogs/helpers"

width, height = 1280, 720
local assets = {}

local baseZoom = 108 / 64
local scaleFactor = baseZoom / 108

local data = {
    megadata = "Data/raw2.json",
    coordinates = "Data/coordinates.json",
    smokes = "Data/smoke.json"
}

function immediatePrint(text)
    love.graphics.clear()
    love.graphics.print(
        text.."\nThis can take longer on older systems.",
        love.graphics.getWidth()/3,
        love.graphics.getHeight()/4
    )
    love.graphics.present()
end


function love.load()
    love.window.setMode(width, height, {
        fullscreen = false,
        resizable = true,
        vsync = true,
        minwidth = 600,
        minheight = 400
    })
    love.window.setTitle("journav")

    immediatePrint("Loading JSON data into memory")

    for key, path in pairs(data) do
        if not love.filesystem.getInfo(path) then goto continue end
        local rawData = love.filesystem.read(path)
        data[key] = json.decode(rawData)

        ::continue::
    end

    immediatePrint("Loading image data into memory")

    assets.smokePreset = love.graphics.newImage("Assets/smoke.png")
    assets.halo = love.graphics.newImage("Assets/HaloFixed.png")
    assets.nucleus = love.graphics.newImage("Assets/Nucleus.png")
    assets.land1 = love.graphics.newImage("Assets/land1.png")
    assets.land2 = love.graphics.newImage("Assets/land2.png")
    assets.land3 = love.graphics.newImage("Assets/land3.png")
    assets.steam = love.graphics.newImage("Assets/steam.png")
    assets.terran = love.graphics.newImage("Assets/clouds.png")
    assets.gasGiant = love.graphics.newImage("Assets/gasgiant.png")
    assets.shadow = love.graphics.newImage("Assets/shadow.png")
    assets.starGlare = love.graphics.newImage("Assets/sunGlare.png")
    assets.rings = love.graphics.newImage("Assets/rings.png")
    assets.accretion = love.graphics.newImage("Assets/accretiondisk.png")

    immediatePrint("Setting up camera")
    
    camera = hump(love.graphics.getWidth() / 2, love.graphics.getHeight() / 2)

    camera.x, camera.y = getStarCoords(data, 2742, baseZoom)

    camera.scale = 1000

    camera.smoother = hump.smooth.damped(5)
    camera.targetX, camera.targetY = camera.x, camera.y
    camera.targetZoom = camera.scale

    cameraSpeed = 300

    immediatePrint("Compiling shaders")
    local pixelCode = love.filesystem.read("Shaders/Corona.glsl")
    local vertexCode = [[
        vec4 position(mat4 transform_projection, vec4 vertex_position) {
            return transform_projection * vertex_position;
        }
    ]]
    assets.coronaShader = love.graphics.newShader(pixelCode, vertexCode)

    love.graphics.setBackgroundColor(0.012, 0.012, 0.012, 1)
end

local frame = 0
local time = 0

local zoomVelocity = 0

function love.wheelmoved(x, y)
    zoomVelocity = zoomVelocity + y * 5
end

local hexRotation = 0
local hexRotationSpeed = 1
local renderX, renderY = 0,0

local baseSpeed = 300
local targetBaseSpeed = baseSpeed

function love.update(dt)
    frame = frame + 1
    time = time + dt

    local dx, dy = 0, 0
    if love.keyboard.isDown('w') then dy = dy - 1 end
    if love.keyboard.isDown('s') then dy = dy + 1 end
    if love.keyboard.isDown('a') then dx = dx - 1 end
    if love.keyboard.isDown('d') then dx = dx + 1 end

    if love.keyboard.isDown('e') then
        camera.targetZoom = camera.targetZoom * (1 + dt)
    end
    if love.keyboard.isDown('q') then
        camera.targetZoom = camera.targetZoom * (1 - dt)
    end

    camera:zoomTo(camera.scale + (camera.targetZoom - camera.scale) * dt * 10)

    local zooming = math.abs(camera.targetZoom - camera.scale) > 0.05
    local targetRotationSpeed = zooming and 0 or 1

    hexRotationSpeed = hexRotationSpeed +
        (targetRotationSpeed - hexRotationSpeed) * dt * 2

    hexRotation = hexRotation + hexRotationSpeed * dt

    if love.keyboard.isDown('lshift') then
        targetBaseSpeed = 900
    else
        targetBaseSpeed = 300
    end

    baseSpeed = baseSpeed +
        (targetBaseSpeed - baseSpeed) * dt * 4

    cameraSpeed = baseSpeed / camera.scale

    zoomVelocity = zoomVelocity * math.exp(-32 * dt)

    camera.targetZoom =
        math.min(5000000000, camera.targetZoom * (1 + zoomVelocity * dt))

    if dx ~= 0 or dy ~= 0 then
        local length = math.sqrt(dx*dx + dy*dy)
        camera.targetX = camera.targetX + (dx / length) * cameraSpeed * dt
        camera.targetY = camera.targetY + (dy / length) * cameraSpeed * dt
    end

    renderX = renderX + (camera.targetX - renderX) * dt * 10
    renderY = renderY + (camera.targetY - renderY) * dt * 10
    camera:lockPosition(0,0)
end

function love.draw()
    camera:attach()
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setLineWidth(1 / camera.scale)
    local wobbleX = renderX - camera.targetX
    local wobbleY = renderY - camera.targetY
    
    local fadingFactor = 800 -- default 15

    for i, smokeData in ipairs(data.smokes) do
        drawSmoke(smokeData, camera, baseZoom, scaleFactor, fadingFactor, renderX, renderY, assets)
    end

    drawNucleus(assets, camera, scaleFactor, renderX, renderY)
    
    for starid, coord in ipairs(data.coordinates) do
        local system, value2, value3, systemScale, x, y = drawStar(
            starid, coord, camera, renderX, renderY, scaleFactor, baseZoom, time, data, assets
        )
        if not system then goto continue end

        for planetid, planet in pairs(system.Planets) do
            drawPlanet(planet, planetid, starid, system, x, y, scaleFactor, systemScale, value3, assets)
        end
        ::continue::
    end

    love.graphics.setColor(1,1,1,1)
    
    drawHexagon(
        "line",
        -wobbleX,
        -wobbleY,
        30 / camera.scale,
        hexRotation,
        math.rad(math.log(camera.targetZoom) * 50)
    )

    camera:detach()

    love.graphics.print("fps: "..love.timer.getFPS(), 5, 5)
    if camera.targetZoom > 5000000000 then
        error("Too much zoom; Crash to prevent GPU failure")
    end
    local warning = camera.targetZoom > 4999999999 and " | zoom stopped to protect GPU from failure" or ""
    love.graphics.print("zoom: "..math.floor(camera.scale + 0.5)..warning, 5, 20)
end
