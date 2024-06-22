-- Custom nvim-cmp source for css_properties.

local utils = require("cmp_css_properties.utils")
local source = {}

function source.is_available()
    return vim.bo.filetype == "css"
end

function source.new()
    local self = setmetatable({}, { __index = source })
    self.cache = {}
    return self
end

function source.get_trigger_characters()
    return { '--' }
end

function source.get_keyword_pattern()
    return "--.*"
end

function source.complete(self, _, callback)
    local bufnr = vim.api.nvim_get_current_buf()
    local items = {}
    local file_path = vim.fn.expand("%:p")

    if not self.cache[bufnr] then
        items = utils.get_css_properties(file_path, source["handle_import_path"])

        if source["get_sources"] ~= nil then
            local custom_sources = source.get_sources();
            local git_root = vim.fn.systemlist('git rev-parse --show-toplevel')[1]
            if vim.v.shell_error ~= 0 then
                git_root = vim.fn.getcwd()
            end

            for _, custom_source in ipairs(custom_sources) do
                local custom_source_path = vim.fn.globpath(git_root, "**/" .. custom_source)
                if custom_source_path ~= "" then
                    -- Check if the custom source is a directory or a file
                    if vim.fn.isdirectory(custom_source_path) == 1 then
                        -- Handle the directory case
                        local properties_files = vim.fn.globpath(custom_source_path, "**/*.css")
                        if properties_files ~= "" then
                            for _, file in ipairs(vim.split(properties_files, "\n")) do
                                local custom_items = utils.get_css_properties(file, source["handle_import_path"])
                                for _, v in ipairs(custom_items) do
                                    table.insert(items, v)
                                end
                            end
                        end
                    else
                        -- Handle the file case
                        local custom_items = utils.get_css_properties(custom_source_path, source["handle_import_path"])
                        for _, v in ipairs(custom_items) do
                            table.insert(items, v)
                        end
                    end
                end
            end
        end

        if type(items) ~= "table" then
            return callback()
        end
        self.cache[bufnr] = items
    else
        items = self.cache[bufnr]
    end


    callback({ items = items or {}, isIncomplete = true })
end

function source.resolve(_, completion_item, callback)
    callback(completion_item)
end

function source.execute(_, completion_item, callback)
    callback(completion_item)
end

return source
