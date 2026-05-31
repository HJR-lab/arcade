-- Bootstraps the obby. Keep all logic in ObbyService so PurchaseHandler
-- can share the same state.

local ObbyService = require(script.Parent:WaitForChild("ObbyService"))

ObbyService.Init()
