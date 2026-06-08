function drawNucleus(assets, camera, scaleFactor, renderX, renderY)
    love.graphics.setBlendMode("add")
    
    love.graphics.setColor(1, 1, 200/255, 1 / (camera.scale * scaleFactor))
    love.graphics.draw(
        assets.halo,
        0 - renderX, 55 * scaleFactor - renderY,
        0,
        1.3 * scaleFactor, 1.3 * scaleFactor,
        assets.halo:getWidth() / 2,
        assets.halo:getHeight() / 2
    )

    love.graphics.setBlendMode("alpha")

    love.graphics.setColor(1, 1, 1, 1 / (camera.scale * scaleFactor))
    love.graphics.draw(
        assets.nucleus,
        0 - renderX, -10 * scaleFactor - renderY,
        0,
        2.5 * scaleFactor, 2.5 * scaleFactor,
        assets.nucleus:getWidth() / 2,
        assets.nucleus:getHeight() / 2
    )
    
    love.graphics.setColor(1, 1, 1, 1)
end