function executeIk()
    for i=1,4,1 do
        -- We handle each branch individually:
        local ld=sim.getLinkDummy(ikTips[i])
        if ld>=0 then
            -- We make sure we don't perform too large jumps:
            local p=sim.getObjectPosition(ikTips[i],ld)
            local l=math.sqrt(p[1]*p[1]+p[2]*p[2]+p[3]*p[3])
            local steps=math.ceil(0.00001+l/0.05)
            local start=sim.getObjectPosition(ikTips[i],-1)
            local goal=sim.getObjectPosition(ld,-1)
            for j=1,steps,1 do
                local t=j/steps
                local pos={start[1]*(1-t)+goal[1]*t,start[2]*(1-t)+goal[2]*t,start[3]*(1-t)+goal[3]*t}
                sim.setObjectPosition(ld,-1,pos)
                sim.handleIkGroup(ikGroups[i])
            end
        end
    end
end

function setDlgItemContent()
    if ui then
        local sel=simBWF.getSelectedEditWidget(ui)

--        simUI.setEditValue(ui,1,simBWF.format("%.0f",sim.getJointPosition(zOffsetJ)/0.001),true)
        simUI.setEditValue(ui,2,simBWF.format("%.0f",sim.getJointPosition(xOffsetJ1)/0.001),true)
        simUI.setEditValue(ui,3,simBWF.format("%.0f",sim.getJointPosition(yOffsetJ1)/0.001),true)
        simUI.setEditValue(ui,4,simBWF.format("%.2f",sim.getJointPosition(alphaOffsetJ1)*180/math.pi),true)
        simUI.setEditValue(ui,5,simBWF.format("%.2f",sim.getJointPosition(betaOffsetJ1)*180/math.pi),true)
        simBWF.setSelectedEditWidget(ui,sel)
    end
end
--[[
function zChange_callback(ui,id,newVal)
    sim.setJointPosition(zOffsetJ,newVal/1000)
    simBWF.markUndoPoint()
    setDlgItemContent()
    executeIk()
end
--]]
function xChange_callback(ui,id,newVal)
    sim.setJointPosition(xOffsetJ1,newVal/1000)
    sim.setJointPosition(xOffsetJ2,newVal/1000)
    simBWF.markUndoPoint()
    setDlgItemContent()
    executeIk()
end

function yChange_callback(ui,id,newVal)
    sim.setJointPosition(yOffsetJ1,newVal/1000)
    sim.setJointPosition(yOffsetJ2,newVal/1000)
    sim.setJointPosition(yOffsetJ3,newVal/1000)
    sim.setJointPosition(yOffsetJ4,newVal/1000)
    simBWF.markUndoPoint()
    setDlgItemContent()
    executeIk()
end

function alphaChange_callback(ui,id,newVal)
    sim.setJointPosition(alphaOffsetJ1,newVal*math.pi/180)
    sim.setJointPosition(alphaOffsetJ2,newVal*math.pi/180)
    sim.setJointPosition(alphaOffsetJ3,newVal*math.pi/180)
    sim.setJointPosition(alphaOffsetJ4,newVal*math.pi/180)
    simBWF.markUndoPoint()
    setDlgItemContent()
    executeIk()
end

function betaChange_callback(ui,id,newVal)
    sim.setJointPosition(betaOffsetJ1,newVal*math.pi/180)
    sim.setJointPosition(betaOffsetJ2,newVal*math.pi/180)
    sim.setJointPosition(betaOffsetJ3,newVal*math.pi/180)
    sim.setJointPosition(betaOffsetJ4,newVal*math.pi/180)
    simBWF.markUndoPoint()
    setDlgItemContent()
    executeIk()
end

function resetJoints_callback(ui,id)
    local allJoints=sim.getObjectsInTree(model,sim.object_joint_type)
    for i=1,#allJoints,1 do
        local mode=sim.getJointMode(allJoints[i])
        if mode==sim.jointmode_ik then
            sim.setJointPosition(allJoints[i],0)
        end
    end
    sim.setJointPosition(ikJ1_a,0*math.pi/180)
    sim.setJointPosition(ikJ2_a,0*math.pi/180)
    sim.setJointPosition(ikJ3_a,0*math.pi/180)
    sim.setJointPosition(ikJ4_a,0*math.pi/180)
    sim.setJointPosition(ikJ1_b,0*math.pi/180)
    sim.setJointPosition(ikJ2_b,0*math.pi/180)
    sim.setJointPosition(ikJ3_b,0*math.pi/180)
    sim.setJointPosition(ikJ4_b,0*math.pi/180)
    simBWF.markUndoPoint()
    executeIk()
end

function createDlg()
    if (not ui) and simBWF.canOpenPropertyDialog() then
        local xml=[[
            <group layout="form" flat="true">
                <label text="X (mm)"/>
                <edit on-editing-finished="xChange_callback" id="2"/>

                <label text="Y (mm)"/>
                <edit on-editing-finished="yChange_callback" id="3"/>

                <label text="Alpha (deg)"/>
                <edit on-editing-finished="alphaChange_callback" id="4"/>

                <label text="Beta (deg)"/>
                <edit on-editing-finished="betaChange_callback" id="5"/>
            </group>
            <button text="Reset IK joints" on-click="resetJoints_callback" id="6" />
        ]]
        --[[
                <label text="Z (mm)"/>
                <edit on-editing-finished="zChange_callback" id="1"/>
                --]]
        ui=simBWF.createCustomUi(xml,simBWF.getUiTitleNameFromModel(model,_MODELVERSION_,_CODEVERSION_),previousDlgPos)
        setDlgItemContent()
    end
end

function showDlg()
    if not ui then
        createDlg()
    end
end

function removeDlg()
    if ui then
        local x,y=simUI.getPosition(ui)
        previousDlgPos={x,y}
        simUI.destroy(ui)
        ui=nil
    end
end

function sysCall_init()
    model=sim.getObjectAssociatedWithScript(sim.handle_self)
    zOffsetJ=sim.getObjectHandle('Ragnar_zOffset')
    xOffsetJ1=sim.getObjectHandle('Ragnar_yOffsetLeft')
    xOffsetJ2=sim.getObjectHandle('Ragnar_yOffsetRight')
    yOffsetJ1=sim.getObjectHandle('Ragnar_xOffsetLeftFront')
    yOffsetJ2=sim.getObjectHandle('Ragnar_xOffsetLeftRear')
    yOffsetJ3=sim.getObjectHandle('Ragnar_xOffsetRightFront')
    yOffsetJ4=sim.getObjectHandle('Ragnar_xOffsetRightRear')
    alphaOffsetJ1=sim.getObjectHandle('Ragnar_zRotLeftFront')
    alphaOffsetJ2=sim.getObjectHandle('Ragnar_zRotLeftRear')
    alphaOffsetJ3=sim.getObjectHandle('Ragnar_zRotRightFront')
    alphaOffsetJ4=sim.getObjectHandle('Ragnar_zRotRightRear')
    betaOffsetJ1=sim.getObjectHandle('Ragnar_xRotLeftFront')
    betaOffsetJ2=sim.getObjectHandle('Ragnar_xRotLeftRear')
    betaOffsetJ3=sim.getObjectHandle('Ragnar_xRotRightFront')
    betaOffsetJ4=sim.getObjectHandle('Ragnar_xRotRightRear')
    ikJ1_a=sim.getObjectHandle('Ragnar_motor1')
    ikJ2_a=sim.getObjectHandle('Ragnar_motor2')
    ikJ3_a=sim.getObjectHandle('Ragnar_motor3')
    ikJ4_a=sim.getObjectHandle('Ragnar_motor4')
    ikJ1_b=sim.getObjectHandle('Ragnar_primaryArm1_j1')
    ikJ2_b=sim.getObjectHandle('Ragnar_primaryArm2_j1')
    ikJ3_b=sim.getObjectHandle('Ragnar_primaryArm3_j1')
    ikJ4_b=sim.getObjectHandle('Ragnar_primaryArm4_j1')

    ikTips={}
    for i=1,4,1 do
        ikTips[i]=sim.getObjectHandle('Ragnar_secondaryArm'..i..'a_tip')
    end

    ikGroups={}
    for i=1,4,1 do
        ikGroups[i]=sim.getIkGroupHandle('ragnarIk_arm'..i)
    end

    previousDlgPos=simBWF.readSessionPersistentObjectData(model,"dlgPosAndSize")
end

function showOrHideUiIfNeeded()
    local s=sim.getObjectSelection()
    if s and #s>=1 and s[#s]==model then
        showDlg()
    else
        removeDlg()
    end
end

function sysCall_nonSimulation()
    showOrHideUiIfNeeded()
end

function sysCall_beforeSimulation()
    removeDlg()
end

function sysCall_beforeInstanceSwitch()
    removeDlg()
end

function sysCall_cleanup()
    removeDlg()
    simBWF.writeSessionPersistentObjectData(model,"dlgPosAndSize",previousDlgPos)
end

