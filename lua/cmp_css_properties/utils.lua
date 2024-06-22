-- Define a cache table
local M = {}
local cmp = require("cmp")

function M.split_path(inputstr, sep)
    if sep == nil then
        sep = "%s"
    end

    local t = {}
    for str in string.gmatch(inputstr, "([^" .. sep .. "]+)") do
        table.insert(t, str)
    end
    return t
end

function M.join_paths(absolute, relative)
    local path = absolute
    for _, dir in ipairs(M.split_path(relative, "/")) do
        if (dir == "..") then
            path = absolute:gsub("(.*)/.*", "%1")
        end
    end
    return path .. "/" .. relative:gsub("^[%./|%../]*", "")
end

function M.get_css_properties(file, handle_import_path)
    local properties = {}
    local content = vim.fn.readfile(file)
    local used = {}

    for _, line in ipairs(content) do
        local lines = vim.split(line, "[;{}]")
        for _, l in ipairs(lines) do
            local name = l:match("^%s*%-%-(.*):")
            local imports = l:match("^%s*@import%s*.*")

            if name and not used[name] then
                table.insert(
                    properties,
                    {
                        label = "--" .. name,
                        insertText = "var(--" .. name .. ")",
                        kind = cmp.lsp.CompletionItemKind.Variable
                    }
                )
                used[name] = true
            elseif imports then
                for import in imports:gmatch("[^,%s]+") do
                    if import == "@import" then
                        goto continue
                    end
                    -- remove quotes if any
                    import = import:gsub('["\']', "")

                    local filepath = handle_import_path and handle_import_path(import) or nil

                    if filepath == nil then
                        -- add .css extension if missing
                        if not import:match("%.css$") then
                            import = import .. ".css"
                        end

                        filepath = M.join_paths(file:gsub("(.*)/.*", "%1"), import)
                    end

                    local found_file = vim.fn.findfile(filepath, ".;.")

                    if found_file ~= "" then
                        -- recursively get properties from imported file
                        local imported_properties = M.get_css_properties(found_file, handle_import_path)
                        -- add them to the main table
                        for _, v in ipairs(imported_properties) do
                            table.insert(properties, v)
                        end
                    end

                    ::continue::
                end
            end
        end
    end

    return properties
end

return M
