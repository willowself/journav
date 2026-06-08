function drawStar(starid, coord, camera, renderX, renderY, scaleFactor, baseZoom, time, data, assets)
    local mode = camera.scale > 500 and "line" or "fill"
    local x, y = coord[1] * baseZoom - renderX, coord[2] * baseZoom - renderY
    
    local cx, cy = camera:cameraCoords(x, y)
    local currentWidth, currentHeight = love.graphics.getWidth(), love.graphics.getHeight()

    if cx < -currentWidth * 0.5 or cy < -currentHeight * 0.5 or cx > currentWidth * 1.5 or cy > currentHeight * 1.5 then
        local dx = camera.targetX - (x + renderX)
        local dy = camera.targetY - (y + renderY)

        if dx*dx + dy*dy > (1 * scaleFactor)^2 then
            return
        end
    end

    love.graphics.setLineWidth(0.01 * scaleFactor / camera.scale)
    local fillAlpha = 1 - math.max(0, math.min(1, (camera.scale - 2000) / (8000 - 2000)))
    local systemView = fillAlpha < 1
    
    love.graphics.setColor(1, 1, 1, fillAlpha)
    love.graphics.circle("fill", x, y, 0.5 * scaleFactor)

    love.graphics.setColor(1,1,1,0.1)
    love.graphics.circle(mode, x, y, 0.5 * scaleFactor)
    love.graphics.setColor(1, 1, 1, 1)

    if not systemView then return end

    local system = data.megadata[starid]
    local value2, value3 = getValue3(system.Star)
    
    local systemScale = 1000
    local surface, corona, rays, background = getStarColors(system.Star)

    local glareSprite = assets.starGlare
    local glareSize = getMainSequenceSize(system.Star) / (systemScale*16) * scaleFactor


    if system.Star.Special == 3 then
        love.graphics.setBlendMode("alpha")
        glareSprite = assets.accretion
        glareSize = glareSize * 16
    else
        love.graphics.setBlendMode("add")
            love.graphics.setColor(
            corona[1]/255,
            corona[2]/255,
            corona[3]/255,
            1
        )
    end

    assets.coronaShader:send("time", time)
    
    love.graphics.draw(
        glareSprite,
        x, y, 0,
        glareSize,
        glareSize,
        glareSprite:getWidth() / 2,
        glareSprite:getHeight() / 2
    )

    love.graphics.setColor(
        surface[1]/255,
        surface[2]/255,
        surface[3]/255,
        1
    )

    if system.Star.Special ~= 3 then
        love.graphics.draw(
            assets.nucleus,
            x, y, 0,
            getMainSequenceSize(system.Star) / (systemScale*10) * scaleFactor,
            getMainSequenceSize(system.Star) / (systemScale*10) * scaleFactor,
            assets.nucleus:getWidth() / 2,
            assets.nucleus:getHeight() / 2
        )

        love.graphics.circle("fill", x, y, getMainSequenceSize(system.Star) / (systemScale/5) * scaleFactor)
    end
    
    love.graphics.setShader(assets.coronaShader)
    love.graphics.setColor(rays[1]/255, rays[2]/255, rays[3]/255, 0.25)

    love.graphics.setBlendMode("add")

    love.graphics.draw(
        assets.halo,
        x,
        y,
        0,
        glareSize * 12,
        glareSize * 12,
        assets.halo:getWidth()/2,
        assets.halo:getHeight()/2
    )

    love.graphics.setShader()

    love.graphics.setBlendMode("alpha")
    return system, value2, value3, systemScale, x, y
end