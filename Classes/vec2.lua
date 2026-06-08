-- By Willow Elliott
-- Full distribution allowed as long as this comment is kept

local vec2 = {}
vec2.__index = vec2

function vec2.new(x,y)
    local self = setmetatable({}, vec2)
    self.x = x
    self.y = y
    return self
end
function vec2.__index(self, key)
    if key == "length" then
        return math.sqrt(self.x^2 + self.y^2)
    elseif key == "unit" then
        return self/#self
    end

    return vec2[key]
end

function vec2.__call(self,x,y)
    return vec2.new(x or 0, y or 0)
end
function vec2.__add(self,b)
    return vec2.new(self.x + b.x, self.y + b.y)
end
function vec2.__sub(self,b)
    return vec2.new(self.x - b.x, self.y - b.y)
end
function vec2.__mul(self, b)
  if type(self) == "number" then
    return vec2.new(b.x * self, b.y * self)
  elseif type(b) == "number" then
    return vec2.new(self.x * b, self.y * b)
  else
    return vec2.new(self.x * b.x, self.y * b.y)
  end
end
function vec2.__div(self, b)
   if type(b) == "number" then
      return vec2.new(self.x / b, self.y / b)
   else
      return vec2.new(self.x / b.x, self.y / b.y)
   end
end
function vec2.__eq(self, b)
	return self.x == b.x and self.y == b.y
end
function vec2.__ne(self, b)
	return not vec2.__eq(self, b)
end
function vec2.__unm(self)
	return vec2.new(-self.x, -self.y)
end
function vec2.__lt(self, b)
	return self.x < b.x and self.y < b.y
end
function vec2.__le(self, b)
	return self.x <= b.x and self.y <= b.y
end
function vec2.__tostring(self)
	return self.x .. ", " .. self.y
end

setmetatable(vec2, vec2)
return vec2