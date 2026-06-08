function drawPlanet(planet, planetid, starid, system, x, y, scaleFactor, systemScale, value3, assets)
    local orbitalRadius = planet.SemiMajorAxis * 18 + value3
    local displayRadius = orbitalRadius * scaleFactor / systemScale

    love.graphics.setColor(1,1,1,0.4)
    love.graphics.circle("line", x, y, displayRadius)
    love.graphics.setColor(1,0,0,1)

    local planetX, planetY, planetZ = getPlanetPosition(planet, system.Star)
    local px = x + (planetX / 10) * scaleFactor / systemScale
    local py = y + (planetZ / 10) * scaleFactor / systemScale

    local divisor = planet.Tectonics == "Jovian" and 1 or 1
    local iconData = GetPlanetIconData(starid, planetid, planet)

    local radius = (planet.Radius / divisor) * 0.001 * scaleFactor
    love.graphics.setColor(unpack(iconData.oceanColor or {20, 50, 100}))
    love.graphics.circle("fill", px, py, radius)
    local landSprite = assets["land".. iconData.landId]
    if planet.Tectonics == "Jovian" then landSprite = assets.gasGiant end

    local drawSize = radius/(255)
    love.graphics.setColor(unpack(iconData.color))
    love.graphics.draw(
        landSprite,
        px, py,
        0,
        drawSize,
        drawSize,
        landSprite:getWidth() / 2,
        landSprite:getHeight() / 2
    )

    if iconData.cloudName then
        local cloudSprite = assets[iconData.cloudName]

        love.graphics.setColor(1,1,1,1)
        love.graphics.draw(
            cloudSprite, px, py, 0,
            drawSize, drawSize,
            cloudSprite:getWidth() / 2,
            cloudSprite:getHeight() / 2
        )
    end

    love.graphics.setColor(1,1,1,0.5)
    love.graphics.draw(
        assets.shadow,
        px, py,
        math.rad(45) + math.atan2(y - py, x - px),
        drawSize,
        drawSize,
        assets.shadow:getWidth() / 2,
        assets.shadow:getHeight() / 2
    )

    if planet.Rings then
        love.graphics.setColor(0.8,0.9,1,0.5)
        love.graphics.draw(
            assets.rings, px, py,
            math.rad(45) + math.atan2(y - py, x - px),
            drawSize, drawSize,
            assets.rings:getWidth() / 2,
            assets.rings:getHeight() / 2
        )
    end
end