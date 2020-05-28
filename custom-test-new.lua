if sysbench.cmdline.command == nil then
    error("Command is required. Supported commands: run")
end

sysbench.cmdline.options = {
    point_selects = {"Number of point SELECT queries to run", 2},
    skip_trx = {"Do not use BEGIN/COMMIT; Use global auto_commit value", false}
}

local select_points = {
    "SELECT * FROM idx.instructor WHERE id = %d",
    "SELECT * FROM idx.instructor WHERE salary > %d"
}
local select_string = {
"SELECT * FROM idx.instructor WHERE name = '%s'",
"SELECT * FROM idx.instructor WHERE dept_name = '%s'"
}
local inserts = {
    "INSERT INTO idx.instructor (ID, name, dept_name, salary) VALUES ('%d', '%s', '%s', %d)",
}
 
 
function execute_selects()

    -- loop for however many the user wants to execute
    for i = 1, sysbench.opt.point_selects do

        -- select random query from list
        local randQuery = select_points[math.random(#select_points)]

        -- generate random ids and execute
        local id = sysbench.rand.pareto(1, 3000000)
        con:query(string.format(randQuery, id))
    end

    -- generate random string
    for i, o in ipairs(select_string) do
        local str = sysbench.rand.string(string.rep("@", sysbench.rand.special(2, 15)))
        con:query(string.format(o, str))
    end

end

local id = 0

function execute_inserts()

    -- generate name/ dept_name / id / salary
    local name = sysbench.rand.string(string.rep("@",sysbench.rand.uniform(5,10)))
    local dept_name = sysbench.rand.string(string.rep("@",sysbench.rand.uniform(5,10)))
    local salary = sysbench.rand.pareto(1, 30000)
    -- INSERT for new imdb.user
    con:query(string.format(inserts[1], id, name, dept_name, salary))
    id = id + 1
end


-- Called by sysbench to initialize script
function thread_init()

    -- globals for script
    drv = sysbench.sql.driver()
    con = drv:connect()
end


-- Called by sysbench when tests are done
function thread_done()

    con:disconnect()
end


-- Called by sysbench for each execution
function event()

    if not sysbench.opt.skip_trx then
        con:query("BEGIN")
    end
    
    execute_inserts()
    execute_selects()
    

    if not sysbench.opt.skip_trx then
        con:query("COMMIT")
    end
end