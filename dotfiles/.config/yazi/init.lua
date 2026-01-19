-- Show size and modified time
function Linemode:size_and_mtime()
	local time = math.floor(self._file.cha.mtime or 0)
	if time == 0 then
		time = ""
	elseif os.date("%Y", time) == os.date("%Y") then
		time = os.date("%b %d %H:%M", time)
	else
		time = os.date("%b %d  %Y", time)
	end

	local size = self._file:size()
	return string.format("%s %s", size and ya.readable_size(size) or "-", time)
end

-- Show relative line numbers
-- ~/.config/yazi/init.lua
require("relative-motions"):setup({ show_numbers = "relative", show_motion = true, enter_mode = "first" })

-- function Current:render(area)
-- 	self.area = area
--
-- 	local markers = {}
-- 	local items = {}
--
-- 	local cursor = cx.active.current.cursor
-- 	local offset = cx.active.current.offset
--
-- 	for i, f in ipairs(Folder:by_kind(Folder.CURRENT).window) do
-- 		local name = Folder:highlighted_name(f)
--
-- 		local idx = i - 1 - cursor + offset
-- 		if idx == 0 then
-- 			idx = cursor
-- 		end
--
-- 		local item = ui.ListItem(ui.Line({ ui.Span(string.format("%3d", idx)), Folder:icon(f), table.unpack(name) }))
-- 		-- Highlight hovered file
-- 		if f:is_hovered() then
-- 			item = item:style(THEME.manager.hovered)
-- 		else
-- 			item = item:style(f:style())
-- 		end
-- 		items[#items + 1] = item
--
-- 		-- Mark yanked/selected files
-- 		local yanked = f:is_yanked()
-- 		if yanked ~= 0 then
-- 			markers[#markers + 1] = { i, yanked }
-- 		elseif f:is_selected() then
-- 			markers[#markers + 1] = { i, 3 }
-- 		end
-- 	end
-- 	return ya.flat({ ui.List(area, items), Folder:linemode(area), Folder:markers(area, markers) })
-- end

require("git"):setup()
