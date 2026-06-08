function drawSmoke(smokeData, camera, baseZoom, scaleFactor, fadingFactor, renderX, renderY, assets)
    local scale = (smokeData.sz * baseZoom) / assets.smokePreset:getWidth()
    
    local smokeFade = (1 - smokeData.tr) - (1 * (camera.scale / fadingFactor) * scaleFactor)
    smokeData.c = smokeData.c or {R = 0.5882, G = 0.7843, B = 1}

    love.graphics.setColor(smokeData.c.R, smokeData.c.G, smokeData.c.B, smokeFade)

    local x = smokeData.pos.X * baseZoom - renderX
    local y = smokeData.pos.Y * baseZoom - renderY

    local cx, cy = camera:cameraCoords(x, y)
    local currentWidth  = love.graphics.getWidth()
    local currentHeight = love.graphics.getHeight()

    local margin = (smokeData.sz * baseZoom) / 0.5 / scaleFactor

    if cx < -margin or cy < -margin or cx > currentWidth + margin or cy > currentHeight + margin then
        local dx = camera.targetX - (x + renderX)
        local dy = camera.targetY - (y + renderY)

        if dx*dx + dy*dy > (200 * scaleFactor)^2 then
            return
        end
    end

    love.graphics.draw(
        assets.smokePreset,
        x, y,
        math.rad(180 - smokeData.r),
        scale, scale,
        assets.smokePreset:getWidth() / 2,
        assets.smokePreset:getHeight() / 2
    )
end