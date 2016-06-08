
local Levels = import("..data.MyLevels")

local ourCellsName =
{
    {"#lian1_1.jpg"},
    {"#lian2_1.jpg"},
    {"#lian3_2.jpg"},
    {"#lian4_1.jpg"},
    {"#lian5_1.jpg"},
}

local Cell = class("Cell", function(nodeType)
    -- local index = 1
    --     index = math.floor(math.random(#ourCellsName))
    -- if nodeType == Levels.NODE_IS_BLACK then
    --     index = 8
    -- end
    if nodeType then
        index = nodeType
    else
        index = math.floor(math.random(#ourCellsName))
    end
    local sprite = display.newSprite(ourCellsName[index][1])
    sprite.nodeType= index 
    return sprite
end)

function Cell:flip(onComplete)
    local frames = display.newFrames("fanfan2.png", 1, 8, not self.isWhite)
    local animation = display.newAnimation(frames, 0.3 / 8)
    self:playAnimationOnce(animation, false, onComplete)

    self:runAction(transition.sequence({
        cc.ScaleTo:create(0.15, 1.5),
        cc.ScaleTo:create(0.1, 1.0),
        cc.CallFunc:create(function()
            local actions = {}
            local scale = 1.1
            local time = 0.04
            for i = 1, 5 do
                actions[#actions + 1] = cc.ScaleTo:create(time, scale, 1.0)
                actions[#actions + 1] = cc.ScaleTo:create(time, 1.0, scale)
                scale = scale * 0.95
                time = time * 0.8
            end
            actions[#actions + 1] = cc.ScaleTo:create(0, 1.0, 1.0)
            self:runAction(transition.sequence(actions))
        end)
    }))

    self.isWhite = not self.isWhite
end

return Cell
