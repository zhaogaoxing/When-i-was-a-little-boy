
local Levels = import("..data.MyLevels")
local Cell   = import("..views.Cell")

local curSwapBeginRow = -1
local curSwapBeginCol = -1

local scheduler = cc.Director:getInstance():getScheduler()

local Board = class("Board", function()
    return display.newNode()
end)

local NODE_PADDING   = 100 * GAME_CELL_STAND_SCALE
local NODE_ZORDER    = 0

local COIN_ZORDER    = 1000


local isInAnimation = false
local isInTouch = false
local isEnableTouch = true
local swapDruTime = 0.8
local cell_anim_time = 0.68
local drop_time = 0.9

function Board:ctor(levelData)
    cc.GameObject.extend(self):addComponent("components.behavior.EventProtocol"):exportMethods()
    math.randomseed(tostring(os.time()):reverse():sub(1,6))

    self.batch = display.newNode()
    self.batch:setPosition(display.cx, display.cy)
    self:addChild(self.batch)
    self.grid = {}

    --多加上一个屏幕的缓冲格子
    for i=1,levelData.rows * 2 do
        self.grid[i] = {}
        if levelData.grid[i] == nil then
            levelData.grid[i] = {}
        end
        for j=1,levelData.cols do
            self.grid[i][j] = levelData.grid[i][j]
        end
    end

    self.grid = clone(levelData.grid)
    self.rows = levelData.rows
    self.cols = levelData.cols
    self.cells = {}
    self.flipAnimationCount = 0

    if self.cols<= 8 then
        self.offsetX = -math.floor(NODE_PADDING * self.cols / 2) - NODE_PADDING / 2
        self.offsetY = -math.floor(NODE_PADDING * self.rows / 2) - NODE_PADDING / 2
        -- create board, place all cells
        for row = 1, self.rows do
            local y = row * NODE_PADDING + self.offsetY
            for col = 1, self.cols do
                local x = col * NODE_PADDING + self.offsetX
                local nodeSprite = display.newSprite("#BoardNode.png", x, y)
                nodeSprite:setScale(GAME_CELL_STAND_SCALE)
                self.batch:addChild(nodeSprite, NODE_ZORDER)

                local node = self.grid[row][col]
                if node ~= Levels.NODE_IS_EMPTY then
                    local cell = Cell.new()
                    cell:setScale(GAME_CELL_STAND_SCALE)
                    cell:setPosition(x, y)
                    cell.row = row
                    cell.col = col
                    self.grid[row][col] = cell
                    self.cells[#self.cells + 1] = cell
                    self.batch:addChild(cell, COIN_ZORDER)
                end
            end
        end
    else
        GAME_CELL_EIGHT_ADD_SCALE = 8.0 / self.cols
        NODE_PADDING = NODE_PADDING * GAME_CELL_EIGHT_ADD_SCALE
        self.offsetX = -math.floor(NODE_PADDING * self.cols / 2) - NODE_PADDING / 2
        self.offsetY = -math.floor(NODE_PADDING * self.rows / 2) - NODE_PADDING / 2
        GAME_CELL_STAND_SCALE = GAME_CELL_EIGHT_ADD_SCALE * GAME_CELL_STAND_SCALE
        -- create board, place all cells
        for row = 1, self.rows do
            local y = row * NODE_PADDING + self.offsetY
            for col = 1, self.cols do
                local x = col * NODE_PADDING + self.offsetX
                local nodeSprite = display.newSprite("#BoardNode.png", x, y)
                nodeSprite:setScale(GAME_CELL_STAND_SCALE)
                self.batch:addChild(nodeSprite, NODE_ZORDER)

                local node = self.grid[row][col]
                if node ~= Levels.NODE_IS_EMPTY then
                    local cell = Cell.new()
                    cell:setScale(GAME_CELL_STAND_SCALE)
                    cell:setPosition(x, y)
                    cell.row = row
                    cell.col = col
                    self.grid[row][col] = cell
                    self.cells[#self.cells + 1] = cell
                    self.batch:addChild(cell, COIN_ZORDER)
                end
            end
        end
    end

    self:setNodeEventEnabled(true)
    self:setTouchEnabled(true)
    self:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(event)
        return self:onTouch(event.name, event.x, event.y)
    end)
    while self:checkAll() do
        self:changeSingedCell()
    end
end

function Board:getCell(row, col)
    if self.grid[row] then
        return self.grid[row][col]
    end
end

function Board:checkAll()
    local padding = NODE_PADDING * GAME_CELL_EIGHT_ADD_SCALE * 1.65
    for _, cell in ipairs(self.cells) do
        self:checkCell(cell)
    end
    for i,v in pairs (self.cells) do
        if v.isNeedClean  then
            return true
        end
    end
    return false
end


function Board:checkCell(cell)
    local listH = {}
    listH [#listH + 1] = cell
    local i=cell.col
    --格子中左边对象是否相同的遍历
    while i > 1 do
        i = i -1
        local cell_left = self:getCell(cell.row,i)
        if cell.nodeType == cell_left.nodeType then
            listH [#listH + 1] = cell_left
        else
            break
        end
    end
    --格子中右边对象是否相同的遍历
    if cell.col ~= self.cols then
        for j=cell.col+1 , self.cols do
            local cell_right = self:getCell(cell.row,j)
            if cell.nodeType == cell_right.nodeType then
                listH [#listH + 1] = cell_right
            else
                break
            end
        end
    end
    --目前的当前格子的左右待消除对象(连同自己)

    --print(#listH)

    if #listH < 3 then
    else
        -- print("find a 3 coup H cell")
        for i,v in pairs(listH) do
            v.isNeedClean = true
        end

    end
    for i=2,#listH do
        listH[i] = nil
    end

    --判断格子的上边的待消除对象

    if cell.row ~= self.rows then
        for j=cell.row+1 , self.rows do
            local cell_up = self:getCell(j,cell.col)
            if cell.nodeType == cell_up.nodeType then
                listH [#listH + 1] = cell_up
            else
                break
            end
        end
    end

    local i=cell.row

    --格子中下面对象是否相同的遍历
    while i > 1 do
        i = i -1
        local cell_down = self:getCell(i,cell.col)
        if cell.nodeType == cell_down.nodeType then
            listH [#listH + 1] = cell_down
        else
            break
        end
    end

    if #listH < 3 then
        for i=2,#listH do
            listH[i] = nil
        end
    else
        for i,v in pairs(listH) do
            v.isNeedClean = true
        end
    end
end


function Board:changeSingedCell(onAnimationComplete)
    local sum = 0
    --统计所有的掉落项

    local DropList = {}

    --统计所有的最高掉落项
    local DropListFinal = {}

    for i,v in pairs(self.cells) do
        if v.isNeedClean then
            sum = sum +1
            local drop_pad = 1
            local row = v.row
            local col = v.col
            local x = col * NODE_PADDING + self.offsetX
            local y = (self.rows + 1)* NODE_PADDING + self.offsetY
            for i,v in pairs(DropList) do
                if col == v.col then
                    drop_pad = drop_pad + 1
                    y = y + NODE_PADDING
                    for i2,v2 in pairs(DropListFinal) do
                        if v2.col == v.col then
                            table.remove(DropListFinal,i2)
                        end
                    end
                end
            end

            local cell = Cell.new()
            DropList [#DropList + 1] = cell
            DropListFinal [#DropListFinal + 1] = cell
            cell.isNeedClean = false
            cell:setPosition(x, y)
            cell:setScale(GAME_CELL_STAND_SCALE)
            cell.row = self.rows + drop_pad
            cell.col = col
            self.grid[self.rows +  drop_pad][col] = cell
            if onAnimationComplete == nil then
                self.batch:removeChild(v, true)
                self.grid[row][col] = nil
            else
                --
            end
            self.cells[i] = cell
            self.batch:addChild(cell, COIN_ZORDER)
        end
    end

    local temp = nil

    --进行一次DropListFinal的精简
    for i=1,#DropListFinal do
        if DropListFinal[i] then
            for j=1,#DropList do
                if DropListFinal[i].col == DropList[j].col and DropListFinal[i].row < DropList[j].row then
                    DropListFinal[i] = DropList[j]
                end
            end
        end
    end

    --重新排列grid
    for i , v in pairs(DropListFinal) do
        if v then
            local c = v.row 
            local j = 1
            while j <=  self.rows  do
                if self.grid[j][v.col] == nil then
                    local k = j
                    while k <  c + 1 do
                        self:swap(k,v.col,k+1,v.col)
                        k = k + 1
                    end
                    j = j - 1
                end
                j = j + 1
            end
        end
    end

    --填补self.grid空缺
    --或执行最后的所有动画步骤

    if onAnimationComplete == nil then
        for i=1,self.rows do
            for j=1,self.cols do
                local y = i * NODE_PADDING + self.offsetY
                local x = j * NODE_PADDING + self.offsetX
                if self.grid[i][j] then
                    self.grid[i][j]:setPosition(x,y)
                end
            end
        end
    else
        --
    end
end

function Board:swap(row1,col1,row2,col2,isAnimation,callBack)
    local temp
    if self.grid[row1] and self.grid[row1][col1] then
        self.grid[row1][col1].row = row2
        self.grid[row1][col1].col = col2
    end
    if self.grid[row2] and self.grid[row2][col2] then
        self.grid[row2][col2].row = row1
        self.grid[row2][col2].col = col1
    end
    if self.grid[row2] == nil or self.grid[row1] == nil then
        isEnableTouch = true
        print("error")
        return
    end
    
    temp = self.grid[row1][col1] 
    self.grid[row1][col1] = self.grid[row2][col2]
    self.grid[row2][col2] = temp

    if isAnimation ~= nil then
        isEnableTouch = true
        if isAnimation  then
            local X2,Y2 = col1 * NODE_PADDING + self.offsetX , row1  * NODE_PADDING + self.offsetY
            local X1,Y1 = col2 * NODE_PADDING + self.offsetX , row2  * NODE_PADDING + self.offsetY
            if (row1==row2+1 and col1==col2) or
                (row1==row2-1 and col1==col2) or
                (row1==row2 and col1==col2+1) or
                (row1==row2 and col1==col2-1) 
                then
            if callBack then
                self.grid[row1][col1]:runAction(transition.sequence({
                        cc.MoveTo:create(0.8, cc.p(X2,Y2)),
                        cc.CallFunc:create(function()
                            self:swap(row1,col1,row2,col2)
                             callBack()   
                        end)
                    }))
                self.grid[row2][col2]:runAction(cc.MoveTo:create(0.8, cc.p(X1,Y1)))
            else
                self.grid[row1][col1]:runAction(cc.MoveTo:create(0.8, cc.p(X2,Y2)))
                self.grid[row2][col2]:runAction(cc.MoveTo:create(0.8, cc.p(X1,Y1)))
                self:swap(row1,col1,row2,col2)
            end
            
        -- else
        --     local tempX,tempY = self.grid[row1][col1]:getPosition()
        --     self.grid[row1][col1]:setPosition(self.grid[row2][col2]:getPositionX(),self.grid[row2][col2]:getPositionY())
        --     self.grid[row2][col2]:setPosition(tempX,tempY)
        end
    end
    self:swap(row1,col1,row2,col2)
    end
end
-- function Board:changeSingedCell()
--     local sum = 0
--     for i,v in pairs(self.cells) do
--         if v.isNeedClean then
--             sum = sum +1
--             print("x",v.row,"y",v.col,"type",v.nodeType)
--             print("find it!!!!!!",sum )
--         end
--     end
-- end

-- function Board:FindCells()
--     local Find = {}
--     Find[#Find+1] = cell
--     local i = cell.col
--     while i > 1 do
--         i = i - 1
--         local left_cell = self:getCell(cell.row,i)
--         if cell.nodeType == left_cell.nodeType then
--             Find[#Find+1] = left_cell
--         else
--             break
--         end
--     end
--     while i > 1 do
--         i = i + 1
--         local right_cell = self:getCell(cell.row,i)
--         if cell.nodeType == right_cell.nodeType then
--             Find[#Find+1] = right_cell
--         else
--             break
--         end
--     end
--     local j = cell.row
--     while j > 1 do
--         j = j - 1
--         local up_cell = self:getCell(j,cell.col)
--         if cell.nodeType == up_cell.nodeType then
--             Find[#Find+1] = up_cell
--         else
--             break
--         end
--     end
--     while j > 1 do
--         j = j + 1
--         local down_cell = self:getCell(j,cell.col)
--         if cell.nodeType == down_cell.nodeType then
--             Find[#Find+1] = down_cell
--         else
--             break
--         end
--     end
-- end

-- function Board:checkAll()
--     for i=1,self.rows do
--         for j=1,self.cols-2 do
--             local cell = self.grid[i][j]
--             -- print("he",cell.row,cell.col)
--             local cell_one = self.grid[i][j+1]
--             local cell_two = self.grid[i][j+2]
--             if cell.nodeType == cell_one.nodeType and
--                 cell.nodeType == cell_two.nodeType then
--                 print("he",i,j)
--                 j=j+2
--             end
--         end 
--     end
--     for i=1,self.cols do
--         for j=1,self.rows-2 do
--             local cell = self.grid[j][i]
--             -- print("he",cell.row,cell.col)
--             local cell_three = self.grid[j+1][i]
--             local cell_four = self.grid[j+2][i]
--             if cell.nodeType == cell_three.nodeType and
--                 cell.nodeType == cell_four.nodeType then
--                 print("he",j,i)
--                 j = j+2
--             end
--         end 
--     end
-- end

-- function Board:Check()
--     local i = 1
--     local j = 1
--     local list1 = {}
--     list1[#list1 + 1] = cell
--     while i<= self.rows do
--         j = 1
--         while j<= self.cols do
--             local cell = self.grid[i][j]
--             local cell_self = self.grid[i][j]
--             local sum = 1
--             while j<self.cols and cell.nodeType == self.grid[i][j+1].nodeType do
--                 cell = self.grid[i][j+1]
--                 list1[#list1 + 1] = cell
--                 j = j + 1
--                 sum = sum + 1
--             end
--             if sum >= 3 then
--                 list1[#list1 + 1] = cell_self
--                 -- print(i,j)
--                 for _,v in pairs(list1) do
--                     print("he",v.row,"  ",v.col)
--                 end
--                 else
--                     list1 = {}
--             end
--             j = j + 1
--         end
--         i = i + 1
--     end

--     i = 1
--     j = 1
--     while i<= self.cols do
--         j = 1
--         while j<= self.rows do
--             local cell = self.grid[j][i]
--             local sum = 1
--             while j<self.cols and cell.nodeType == self.grid[j+1][i].nodeType do
--                 cell = self.grid[j+1][i]
--                 j = j + 1
--                 sum = sum + 1
--             end
--            if sum >= 3 then
--                 list1[#list1 + 1] = cell_self
--                 -- print(i,j)
--                 for _,v in pairs(list1) do
--                     print("he",v.row,"  ",v.col)
--                 end
--                 else
--                     list1 = {}
--             end
--             j = j + 1
--         end
--         i = i + 1
--     end
-- end

-- function Board:checkXie2()
--     local i = 1
--     local j = 1
--     while i<= self.rows do
--         j = 1
--         while j<= self.cols do
--             local cell = self.grid[i][j]
--             local sum = 1
--             while j<self.cols and i<self.rows and cell.nodeType == self.grid[i+1][j+1].nodeType do
--                 cell = self.grid[i+1][j+1]
--                 j = j + 1
--                 i = i + 1    
--                 sum = sum + 1
--             end
--             if sum >= 3 then
--                 print(i,j)
--             end
--             j = j + 1
--         end
--         i = i + 1
--     end

--     i = self.rows
--     j = self.cols
--     while i>=1 do
--         j = self.cols
--         while j>=1 do
--             local cell = self.grid[i][j]
--             local sum = 1
--             while j>1 and i>1 and cell.nodeType == self.grid[i-1][j-1].nodeType do
--                 cell = self.grid[i-1][j-1]
--                 j = j - 1
--                 i = i - 1    
--                 sum = sum + 1
--             end
--             if sum >= 3 then
--                 print(i,j)
--             end
--             j = j - 1
--         end
--         i = i - 1
--     end

--     i = self.rows
--     j = 1
--     while i>=1 do
--         j = 1
--         while j<= self.cols do
--             local cell = self.grid[i][j]
--             local sum = 1
--             while j<self.cols and i>1 and cell.nodeType == self.grid[i-1][j+1].nodeType do
--                 cell = self.grid[i-1][j+1]
--                 j = j + 1
--                 i = i - 1    
--                 sum = sum + 1
--             end
--             if sum >= 3 then
--                 print(i,j)
--             end
--             j = j + 1
--         end
--         i = i - 1
--     end
--     i = 1
--     j = self.cols
--     while i<=self.rows do
--         j = self.cols
--         while j>= 1 do
--             local cell = self.grid[i][j]
--             local sum = 1
--             while j>1 and i<self.rows and cell.nodeType == self.grid[i+1][j-1].nodeType do
--                 cell = self.grid[i+1][j-1]
--                 j = j - 1
--                 i = i + 1    
--                 sum = sum + 1
--             end
--             if sum >= 3 then
--                 print(i,j)
--             end
--             j = j - 1
--         end
--         i = i + 1
--     end
-- end

-- function Board:checkXie()
--     for i=1,self.rows-2 do
--         for j=1,self.cols-2 do
--             local cell = self.grid[i][j]
--             -- print("he",cell.row,cell.col)
--             local cell_one = self.grid[i+1][j+1]
--             local cell_two = self.grid[i+2][j+2]
--             if cell.nodeType == cell_one.nodeType and
--                 cell.nodeType == cell_two.nodeType then
--                 print("he",i,j)
--             end
--         end 
--     end
--     local i = self.rows
--     while i >= 4  do
--         i = i - 1
--         for j=1,self.cols-2 do
--             local cell = self.grid[i][j]
--             -- print("he",cell.row,cell.col)
--             local cell_one = self.grid[i-1][j+1]
--             local cell_two = self.grid[i-2][j+2]
--             if cell.nodeType == cell_one.nodeType and
--                 cell.nodeType == cell_two.nodeType then
--                 print("he",i,j)
--             end
--         end 
--     end
-- end

function Board:checkLevelCompleted()
    local count = 0
    for _, cell in ipairs(self.cells) do
        if cell.isWhite then count = count + 1 end
    end
    if count == #self.cells then
        -- completed
        self:setTouchEnabled(false)
        self:dispatchEvent({name = "LEVEL_COMPLETED"})
    end
end

function Board:getCell(row, col)
    if self.grid[row] then
        return self.grid[row][col]
    end
end

function Board:flipCoin(cell, includeNeighbour)
    if not cell or cell == Levels.NODE_IS_EMPTY then return end

    self.flipAnimationCount = self.flipAnimationCount + 1
    cell:flip(function()
        self.flipAnimationCount = self.flipAnimationCount - 1
        self.batch:reorderChild(cell, CELL_ZORDER)
        if self.flipAnimationCount == 0 then
            self:checkLevelCompleted()
        end
    end)
    if includeNeighbour then
        audio.playSound(GAME_SFX.flipCoin)
        self.batch:reorderChild(cell, CELL_ZORDER + 1)
        self:performWithDelay(function()
            self:flipCoin(self:getCoin(cell.row - 1, cell.col))
            self:flipCoin(self:getCoin(cell.row + 1, cell.col))
            self:flipCoin(self:getCoin(cell.row, cell.col - 1))
            self:flipCoin(self:getCoin(cell.row, cell.col + 1))
        end, 0.25)
    end
end

function Board:onTouch(event, x, y)
    if not isEnableTouch then
        return
    end
    if event == "began" then
        local row,col = self:getRandC(x, y)
        curSwapBeginRow = row
        curSwapBeginCol = col
        isInTouch = true
    end
    if isInTouch and (event == "moved" or event == "ended"  )then
        local padding = NODE_PADDING / 2
        local cell_center = self.grid[curSwapBeginRow][curSwapBeginCol]
        local cx, cy = cell_center:getPosition()
        cx = cx + display.cx
        cy = cy + display.cy

        if event == "ended" then
            isInTouch = false
            local p_a = cell_center:getAnchorPoint()
            local x_a = (0.5 - p_a.x ) *  NODE_PADDING + curSwapBeginCol * NODE_PADDING + self.offsetX
            local y_a = (0.5 - p_a.y) *  NODE_PADDING + curSwapBeginRow * NODE_PADDING + self.offsetY
            cell_center:setAnchorPoint(cc.p(0.5,0.5))
            cell_center:setPosition(cc.p(x_a  , y_a ))
            isEnableTouch = false
                cell_center:runAction(
                    transition.sequence({
                    cc.MoveTo:create(0.4,cc.p(curSwapBeginCol * NODE_PADDING + self.offsetX,curSwapBeginRow * NODE_PADDING + self.offsetY)),
                    cc.CallFunc:create(function()
                          isEnableTouch = true
                    end)
                }))
            cell_center:runAction(cc.ScaleTo:create(0.5,CELL_SCALE))
            return true
        end

        if x < cx - 2*padding
            or x > cx + 2*padding
            or y < cy - 2*padding
            or y > cy + 2*padding then
            isInTouch = false

            --划归锚点偏移
            local p_a = cell_center:getAnchorPoint()
            local x_a = (0.5 - p_a.x ) *  NODE_PADDING + curSwapBeginCol * NODE_PADDING + self.offsetX
            local y_a = (0.5 - p_a.y) *  NODE_PADDING + curSwapBeginRow * NODE_PADDING + self.offsetY
            cell_center:setAnchorPoint(cc.p(0.5,0.5))
            cell_center:setPosition(cc.p(x_a  , y_a ))

            --进入十字框以内
            if (x >= cx - padding
            and x <= cx + padding)
            or (y >= cy - padding
            and y <= cy + padding) then

                local row,col = self:getRandC(x, y)

                isEnableTouch = false
                self:swap(row,col,curSwapBeginRow,curSwapBeginCol,
                    function()
                        isEnableTouch = true
                        if self:checkAll() then
                        self:changeSingedCell(true)
                        end
                    end
                    )
                cell_center:runAction(cc.ScaleTo:create(0.5,CELL_SCALE))
            else
                isEnableTouch = false
                cell_center:runAction(
                    transition.sequence({
                    cc.MoveTo:create(0.4,cc.p(curSwapBeginCol * NODE_PADDING + self.offsetX,curSwapBeginRow * NODE_PADDING + self.offsetY)),
                    cc.CallFunc:create(function()
                          isEnableTouch = true
                    end)
                }))
                cell_center:runAction(cc.ScaleTo:create(0.5,CELL_SCALE))
                return true
            end
        else
            x_vec = (cx - x)/ NODE_PADDING * 0.3 + 0.5
            y_vec = (cy - y)/ NODE_PADDING * 0.3 + 0.5
            cell_center:setAnchorPoint(cc.p(x_vec,y_vec))
        end
    end
    return true
end

function Board:getRandC(x,y)
    local padding = NODE_PADDING / 2
    for _, cell in ipairs(self.cells) do
        local cx, cy = cell:getPosition()
        cx = cx + display.cx
        cy = cy + display.cy
        if x >= cx - padding
            and x <= cx + padding
            and y >= cy - padding
            and y <= cy + padding then
            return cell.row , cell.col
        end
    end
    return -1 , -1
end

function Board:onEnter()
    self:setTouchEnabled(true)
end

function Board:onExit()
    GAME_CELL_EIGHT_ADD_SCALE = 1.0
    GAME_CELL_STAND_SCALE = GAME_CELL_EIGHT_ADD_SCALE * 0.75
    NODE_PADDING = 100 * 0.75
    self:removeAllEventListeners()
end

return Board
