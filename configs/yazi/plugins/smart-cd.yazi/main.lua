return {
  entry = function(_, job)
    local command = job.args[1]
    if not command or command == "" then
      ya.notify({ title = "smart-cd", content = "Falta comando", timeout = 4, level = "error" })
      return
    end

    local args = {}
    for i = 2, #job.args do
      table.insert(args, job.args[i])
    end

    local permit = ui.hide()
    local output, err = Command(command)
      :arg(args)
      :stdin(Command.INHERIT)
      :stdout(Command.PIPED)
      :stderr(Command.INHERIT)
      :output()
    permit:drop()

    if err then
      ya.notify({ title = command, content = tostring(err), timeout = 6, level = "error" })
      return
    end

    if not output.status.success then
      return
    end

    local target = output.stdout:gsub("%s+$", "")
    if target ~= "" then
      ya.emit("cd", { Url(target) })
    end
  end,
}
