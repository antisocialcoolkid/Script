--[[
                                                                                                                             
            dddddddd                                                                                                         
            d::::::d  iiii                                                                                     tttt          
            d::::::d i::::i                                                                                 ttt:::t          
            d::::::d  iiii                                                                                  t:::::t          
            d:::::d                                                                                         t:::::t          
    ddddddddd:::::d iiiiiii     ssssssssss   rrrrr   rrrrrrrrr   uuuuuu    uuuuuu ppppp   ppppppppp   ttttttt:::::ttttttt    
  dd::::::::::::::d i:::::i   ss::::::::::s  r::::rrr:::::::::r  u::::u    u::::u p::::ppp:::::::::p  t:::::::::::::::::t    
 d::::::::::::::::d  i::::i ss:::::::::::::s r:::::::::::::::::r u::::u    u::::u p:::::::::::::::::p t:::::::::::::::::t    
d:::::::ddddd:::::d  i::::i s::::::ssss:::::srr::::::rrrrr::::::ru::::u    u::::u pp::::::ppppp::::::ptttttt:::::::tttttt    
d::::::d    d:::::d  i::::i  s:::::s  ssssss  r:::::r     r:::::ru::::u    u::::u  p:::::p     p:::::p      t:::::t          
d:::::d     d:::::d  i::::i    s::::::s       r:::::r     rrrrrrru::::u    u::::u  p:::::p     p:::::p      t:::::t          
d:::::d     d:::::d  i::::i       s::::::s    r:::::r            u::::u    u::::u  p:::::p     p:::::p      t:::::t          
d:::::d     d:::::d  i::::i ssssss   s:::::s  r:::::r            u:::::uuuu:::::u  p:::::p    p::::::p      t:::::t    tttttt
d::::::ddddd::::::ddi::::::is:::::ssss::::::s r:::::r            u:::::::::::::::uup:::::ppppp:::::::p      t::::::tttt:::::t
 d:::::::::::::::::di::::::is::::::::::::::s  r:::::r             u:::::::::::::::up::::::::::::::::p       tt::::::::::::::t
  d:::::::::ddd::::di::::::i s:::::::::::ss   r:::::r              uu::::::::uu:::up::::::::::::::pp          tt:::::::::::tt
   ddddddddd   dddddiiiiiiii  sssssssssss     rrrrrrr                uuuuuuuu  uuuup::::::pppppppp              ttttttttttt  
                                                                                   p:::::p                                   
                                                                                   p:::::p                                   
                                                                                  p:::::::p                                  
                                                                                  p:::::::p                                  
                                                                                  p:::::::p                                  
                                                                                  ppppppppp              
]]
-- detecting executor, this is used for potential Solara or Wave support in the future
local executor_used = tostring(identifyexecutor())
if executor_used == "Synapse Z" then
    -- vars
    local visuals_enabled = false
    local show_boxes_enabled = false
    local show_tracers_enabled = false
    local show_names_enabled = false
    local show_skeleton_enabled = false
    local show_view_line_enabled = false
    local aimbot_enabled = false
    local aimbot_fov_size = 50
    local aimbot_aim_part = "Head"
    local aimbot_keybind = Enum.UserInputType.MouseButton2
    local aimbot_smoothness = 0
    local show_fov = false
    local aimbot_right_click = false
    local aimbot_smoothness_enabled = false
    local aimbot_prediction_enabled = false
    local aimbot_prediction_strength_x = 0
    local aimbot_prediction_strength_y = 0
    local aimbot_sticky_aim_enabled = false
    local user_input_service = game:GetService("UserInputService")
    local locked_target = nil
    local players_service = game:GetService("Players")
    local run_service = game:GetService("RunService")
    local visual_elements = {}
    local tp_behind_offset = 0
    local tp_behind_height = 6
    local teleporting = false
    local speed_multiplier = 0
    local speed_modifier_enabled = false

    function init_visuals(player)
        if not visuals_enabled then
            return
        end
        if player == players_service.LocalPlayer then
            return
        end

        local character = player.Character or player.CharacterAdded:Wait()
        local humanoid_root_part = character:WaitForChild("HumanoidRootPart")

        local box_visual = Drawing.new("Square")
        box_visual.Color = Color3.fromRGB(255, 255, 255)
        box_visual.Thickness = 2
        box_visual.Transparency = 1
        box_visual.Filled = false

        local tracer_visual = Drawing.new("Line")
        tracer_visual.Color = Color3.fromRGB(255, 255, 255)
        tracer_visual.Thickness = 1
        tracer_visual.Transparency = 1

        local name_visual = Drawing.new("Text")
        name_visual.Text = player.Name
        name_visual.Color = Color3.fromRGB(255, 255, 255)
        name_visual.Size = 20
        name_visual.Center = true
        name_visual.Outline = true
        name_visual.Transparency = 1

        local skeleton_lines = {}
        for i = 1, 6 do
            local line = Drawing.new("Line")
            line.Color = Color3.fromRGB(255, 255, 255)
            line.Thickness = 2.5
            line.Transparency = 1
            table.insert(skeleton_lines, line)
        end

        local view_line = Drawing.new("Line")
        view_line.Color = Color3.fromRGB(255, 255, 255)
        view_line.Thickness = 2.5
        view_line.Transparency = 1

        visual_elements[player] = {
            box = box_visual,
            tracer = tracer_visual,
            name = name_visual,
            skeleton = skeleton_lines,
            view_line = view_line
        }

        local function update_visuals()
            if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
                box_visual.Visible = false
                tracer_visual.Visible = false
                name_visual.Visible = false
                for _, line in pairs(skeleton_lines) do
                    line.Visible = false
                end
                view_line.Visible = false
                return
            end
        
            if not visuals_enabled then
                box_visual.Visible = false
                tracer_visual.Visible = false
                name_visual.Visible = false
                for _, line in pairs(skeleton_lines) do
                    line.Visible = false
                end
                view_line.Visible = false
                return
            end
        
            local hrp_position, on_screen = workspace.CurrentCamera:WorldToViewportPoint(humanoid_root_part.Position)
            if on_screen then
                local top = workspace.CurrentCamera:WorldToViewportPoint(humanoid_root_part.Position + Vector3.new(0, 3, 0))
                local bottom = workspace.CurrentCamera:WorldToViewportPoint(humanoid_root_part.Position - Vector3.new(0, 3, 0))
                local size = Vector2.new(math.abs(top.X - bottom.X) * 1.5, math.abs(top.Y - bottom.Y) * 1.5)
        
                if show_boxes_enabled then
                    box_visual.Size = size
                    box_visual.Position = Vector2.new(hrp_position.X - size.X / 2, hrp_position.Y - size.Y / 2)
                    box_visual.Visible = true
                else
                    box_visual.Visible = false
                end
        
                if show_tracers_enabled then
                    tracer_visual.From = Vector2.new(workspace.CurrentCamera.ViewportSize.X / 2, workspace.CurrentCamera.ViewportSize.Y)
                    tracer_visual.To = Vector2.new(hrp_position.X, hrp_position.Y)
                    tracer_visual.Visible = true
                else
                    tracer_visual.Visible = false
                end
        
                if show_names_enabled then
                    name_visual.Position = Vector2.new(hrp_position.X, hrp_position.Y - size.Y / 2 - 20)
                    name_visual.Visible = true
                else
                    name_visual.Visible = false
                end
        
                if show_view_line_enabled and player.Character:FindFirstChild("Head") then
                    local head = player.Character:FindFirstChild("Head")
                    local head_pos = workspace.CurrentCamera:WorldToViewportPoint(head.Position)
                    local forward_vector = player.Character.HumanoidRootPart.CFrame.LookVector * 2
                    local view_point = head.Position + forward_vector
                    local view_pos = workspace.CurrentCamera:WorldToViewportPoint(view_point)
        
                    view_line.From = Vector2.new(head_pos.X, head_pos.Y)
                    view_line.To = Vector2.new(view_pos.X, view_pos.Y)
                    view_line.Visible = true
                else
                    view_line.Visible = false
                end
        
                if show_skeleton_enabled and player.Character then
                    local parts = {
                        head = player.Character:FindFirstChild("Head"),
                        left_arm = player.Character:FindFirstChild("LeftUpperArm"),
                        right_arm = player.Character:FindFirstChild("RightUpperArm"),
                        left_leg = player.Character:FindFirstChild("LeftUpperLeg"),
                        right_leg = player.Character:FindFirstChild("RightUpperLeg"),
                        torso = player.Character:FindFirstChild("Torso") or player.Character:FindFirstChild("UpperTorso")
                    }
        
                    if parts.head and parts.torso then
                        local head_pos = workspace.CurrentCamera:WorldToViewportPoint(parts.head.Position)
                        local torso_pos = workspace.CurrentCamera:WorldToViewportPoint(parts.torso.Position)
        
                        skeleton_lines[1].From = Vector2.new(head_pos.X, head_pos.Y)
                        skeleton_lines[1].To = Vector2.new(torso_pos.X, torso_pos.Y)
                        skeleton_lines[1].Visible = true
        
                        if parts.left_arm then
                            local left_arm_pos = workspace.CurrentCamera:WorldToViewportPoint(parts.left_arm.Position)
                            skeleton_lines[2].From = Vector2.new(torso_pos.X, torso_pos.Y)
                            skeleton_lines[2].To = Vector2.new(left_arm_pos.X, left_arm_pos.Y)
                            skeleton_lines[2].Visible = true
                        else
                            skeleton_lines[2].Visible = false
                        end
        
                        if parts.right_arm then
                            local right_arm_pos = workspace.CurrentCamera:WorldToViewportPoint(parts.right_arm.Position)
                            skeleton_lines[3].From = Vector2.new(torso_pos.X, torso_pos.Y)
                            skeleton_lines[3].To = Vector2.new(right_arm_pos.X, right_arm_pos.Y)
                            skeleton_lines[3].Visible = true
                        else
                            skeleton_lines[3].Visible = false
                        end
        
                        if parts.left_leg then
                            local left_leg_pos = workspace.CurrentCamera:WorldToViewportPoint(parts.left_leg.Position)
                            skeleton_lines[4].From = Vector2.new(torso_pos.X, torso_pos.Y)
                            skeleton_lines[4].To = Vector2.new(left_leg_pos.X, left_leg_pos.Y)
                            skeleton_lines[4].Visible = true
                        else
                            skeleton_lines[4].Visible = false
                        end
        
                        if parts.right_leg then
                            local right_leg_pos = workspace.CurrentCamera:WorldToViewportPoint(parts.right_leg.Position)
                            skeleton_lines[5].From = Vector2.new(torso_pos.X, torso_pos.Y)
                            skeleton_lines[5].To = Vector2.new(right_leg_pos.X, right_leg_pos.Y)
                            skeleton_lines[5].Visible = true
                        else
                            skeleton_lines[5].Visible = false
                        end
                    end
                else
                    for _, line in pairs(skeleton_lines) do
                        line.Visible = false
                    end
                end
            else
                box_visual.Visible = false
                tracer_visual.Visible = false
                name_visual.Visible = false
                for _, line in pairs(skeleton_lines) do
                    line.Visible = false
                end
                view_line.Visible = false
            end
        end
        

        run_service.RenderStepped:Connect(update_visuals)
    end

    function remove_visuals(player)
        if visual_elements[player] then
            visual_elements[player].box:Remove()
            visual_elements[player].tracer:Remove()
            visual_elements[player].name:Remove()
            visual_elements[player] = nil
        end
    end

    function add_visuals(player)
        player.CharacterAdded:Connect(
            function()
                init_visuals(player)
            end
        )
        player.CharacterRemoving:Connect(
            function()
                remove_visuals(player)
            end
        )
        if player.Character then
            init_visuals(player)
        end
    end

    players_service.PlayerAdded:Connect(add_visuals)

    for _, player in pairs(players_service:GetPlayers()) do
        add_visuals(player)
    end

    function toggle_visuals(state)
        visuals_enabled = state
        if not state then
            for _, player in pairs(players_service:GetPlayers()) do
                remove_visuals(player)
            end
        else
            for _, player in pairs(players_service:GetPlayers()) do
                if player.Character then
                    init_visuals(player)
                end
            end
        end
    end

    -- aimbot shit
    function aimbot()
        if not aimbot_enabled or not aimbot_keybind then
            return
        end

        -- checking for keycode or a mousebutton 
        if aimbot_keybind == Enum.UserInputType.MouseButton2 then
            if not user_input_service:IsMouseButtonPressed(aimbot_keybind) then
                locked_target = nil
                return
            end
        else
            if not user_input_service:IsKeyDown(aimbot_keybind) then
                locked_target = nil
                return
            end
        end


        local camera = workspace.CurrentCamera
        local mouse = players_service.LocalPlayer:GetMouse()

        if locked_target and aimbot_sticky_aim_enabled then
            if locked_target.Character and locked_target.Character:FindFirstChild(aimbot_aim_part) then
                local part = locked_target.Character[aimbot_aim_part]
                local predicted_position = part.Position
                if aimbot_prediction_enabled then
                    local velocity = locked_target.Character.HumanoidRootPart.Velocity
                    predicted_position =
                        part.Position +
                        Vector3.new(
                            velocity.X * aimbot_prediction_strength_x * 0.1,
                            velocity.Y * aimbot_prediction_strength_y * 0.1,
                            0
                        )
                end
                local screen_pos = camera:WorldToViewportPoint(predicted_position)
                local target = Vector2.new(screen_pos.X, screen_pos.Y)
                local screen_center = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
                local move = target - screen_center

                if aimbot_smoothness_enabled then
                    local move_step = move / (aimbot_smoothness + 1)
                    mousemoverel(move_step.X, move_step.Y)
                else
                    mousemoverel(move.X, move.Y)
                end
                return
            else
                locked_target = nil
            end
        end

        local closest_player = nil
        local closest_distance = aimbot_fov_size

        for _, player in pairs(players_service:GetPlayers()) do
            if
                player ~= players_service.LocalPlayer and player.Character and
                    player.Character:FindFirstChild(aimbot_aim_part)
             then
                local part = player.Character[aimbot_aim_part]
                local predicted_position = part.Position
                if aimbot_prediction_enabled then
                    local velocity = player.Character.HumanoidRootPart.Velocity
                    predicted_position =
                        part.Position +
                        Vector3.new(
                            velocity.X * aimbot_prediction_strength_x * 0.1,
                            velocity.Y * aimbot_prediction_strength_y * 0.1,
                            0
                        )
                end
                local screen_pos, on_screen = camera:WorldToViewportPoint(predicted_position)
                if on_screen then
                    local distance =
                        (Vector2.new(screen_pos.X, screen_pos.Y) -
                        Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)).magnitude
                    if distance < closest_distance then
                        closest_distance = distance
                        closest_player = player
                    end
                end
            end
        end

        if closest_player then
            locked_target = closest_player
            local part = closest_player.Character[aimbot_aim_part]
            local predicted_position = part.Position
            if aimbot_prediction_enabled then
                local velocity = closest_player.Character.HumanoidRootPart.Velocity
                predicted_position =
                    part.Position +
                    Vector3.new(
                        velocity.X * aimbot_prediction_strength_x * 0.1,
                        velocity.Y * aimbot_prediction_strength_y * 0.1,
                        0
                    )
            end
            local screen_pos = camera:WorldToViewportPoint(predicted_position)
            local target = Vector2.new(screen_pos.X, screen_pos.Y)
            local screen_center = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
            local move = target - screen_center

            if aimbot_smoothness_enabled then
                local move_step = move / (aimbot_smoothness + 1)
                mousemoverel(move_step.X, move_step.Y)
            else
                mousemoverel(move.X, move.Y)
            end
        end
    end

    run_service.RenderStepped:Connect(aimbot)

    local fov_circle = Drawing.new("Circle")
    fov_circle.Color = Color3.fromRGB(255, 255, 255)
    fov_circle.Thickness = 1
    fov_circle.Transparency = 1
    fov_circle.Filled = false

    function update_fov_circle()
        if show_fov then
            local camera = workspace.CurrentCamera
            local mouse_pos = user_input_service:GetMouseLocation()
            fov_circle.Radius = aimbot_fov_size
            fov_circle.Position = Vector2.new(mouse_pos.X, mouse_pos.Y)
            fov_circle.Visible = true
        else
            fov_circle.Visible = false
        end
    end

    run_service.RenderStepped:Connect(update_fov_circle)

    -- janky but 
