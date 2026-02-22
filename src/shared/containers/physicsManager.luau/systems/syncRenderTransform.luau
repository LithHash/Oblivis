local ReplicatedStorage = game:GetService("ReplicatedStorage")

local oblivis = require(ReplicatedStorage.shared.oblivis)

local components = oblivis.components

return oblivis.systems.create("syncRenderTransform", {
	update = function(world: oblivis.World, deltaTime: number)
		world:view(
			components.transform,
			components.renderData
		):forEach(function(entity, transform, renderData)
			local instance = renderData.instance
			if not instance or not instance.Parent then
				return
			end

			if instance:IsA("Model") and instance.PrimaryPart then
				instance:PivotTo(transform.rotation + transform.position)
			elseif instance:IsA("BasePart") then
				instance.CFrame = transform.rotation + transform.position
			end
		end)
	end,

	step = "Heartbeat",
	priority = 4,
})
