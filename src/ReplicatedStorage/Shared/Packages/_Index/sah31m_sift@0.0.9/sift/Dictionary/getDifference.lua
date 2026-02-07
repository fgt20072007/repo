local function GetTableDifference(table1, table2)
    local differences = {}

    -- Iterate through keys of the first table
    for key, value in pairs(table1) do
      -- Check if the key doesn't exist in the second table
      if not table2[key] then
        differences[key] = value -- Key exists only in the first table
      else
        -- Check if the values are different data types
        if type(value) ~= type(table2[key]) then
          differences[key] = { value, table2[key] } -- Values have different data types
        elseif type(value) == "table" then
          -- Recursively call the function for nested tables
          local nestedDifference = GetTableDifference(value, table2[key])
          if next(nestedDifference) then -- Check if there are any differences in nested tables
            differences[key] = nestedDifference
          end
        else
          -- Check for value differences (excluding nested tables)
          if value ~= table2[key] then
            differences[key] = value -- Values are different
          end
        end
      end
    end

    -- Check for keys present only in the second table
    for key, value in pairs(table2) do
      if not differences[key] and not table1[key] then
        differences[key] = value -- Key exists only in the second table
      end
    end

    return differences
end

return GetTableDifference