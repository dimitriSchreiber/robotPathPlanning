function timeUi_onClose()
    if timeUi then
        timeDlg_wasClosed=true
        timeUi_hide()
    end
end

function timeUi_hide()
    if timeUi then
        local x,y=simUI.getPosition(timeUi)
        timeUi_previousDlgPos={x,y}
        simUI.destroy(timeUi)
        timeUi=nil
    end
end

function timeUi_createDlg()
    if bwfPluginLoaded and not timeUi then
        if not timeUi_previousDlgPos then
            timeUi_previousDlgPos='bottomLeft'
        end
        if simplifiedTimeDisplay or online then
            local xml =[[
                    <label text="Time " style="* {font-size: 20px; font-weight: bold; margin-left: 20px; margin-right: 20px;}"/>
                    <label id="1" text="" style="* {font-size: 20px; font-weight: bold; margin-left: 20px; margin-right: 20px;}"/>
            ]]
            local title='Simulation Time'
            if online then
                title='Time'
            end
            timeUi=simBWF.createCustomUi(xml,title,timeUi_previousDlgPos,true,'timeUi_onClose',false,false,false,'layout="form"')
        else
            local xml =[[
                    <label text="Simulation time " style="* {font-size: 20px; font-weight: bold; margin-left: 20px; margin-right: 20px;}"/>
                    <label id="1" text="" style="* {font-size: 20px; font-weight: bold; margin-left: 20px; margin-right: 20px;}"/>
                    <label text="Real-time " style="* {font-size: 20px; font-weight: bold; margin-left: 20px; margin-right: 20px;}"/>
                    <label id="2" text="" style="* {font-size: 20px; font-weight: bold; margin-left: 20px; margin-right: 20px;}"/>
            ]]
            timeUi=simBWF.createCustomUi(xml,'Simulation Time',timeUi_previousDlgPos,true,'timeUi_onClose',false,false,false,'layout="form"')
        end
    end
end

function packMLState_onClose()
    if packMLStateUi then
        packMLStateDlg_wasClosed=true
        packMLState_hideState()
    end
end

function packMLState_hideState()
    if packMLStateUi then
        local x,y=simUI.getPosition(packMLStateUi)
        packMLState_previousDlgPos={x,y}
        simUI.destroy(packMLStateUi)
        packMLStateUi=nil
    end
end

function packMLState_showState(state)
    if packMLStateUi and (version>30400 or revision>12) then
        if simplifiedPackMLDisplay then
            state=string.lower(state)
            local data=nil
            if state=='aborting' then data={'Aborting',"background-color: #66ff66"} end
            if state=='aborted' then data={'Aborted',"background-color: #ffff66"} end
            if state=='clearing' then data={'Clearing',"background-color: #66ff66"} end
            if state=='stopping' then data={'Stopping',"background-color: #66ff66"} end
            if state=='stopped' then data={'Stopped',"background-color: #ffff66"} end
            
            if state=='suspending' then data={'Suspending',"background-color: #66ff66"} end
            if state=='suspended' then data={'Suspended',"background-color: #ffff66"} end
            if state=='un-suspending' then data={'Un-Suspending',"background-color: #66ff66"} end
            if state=='resetting' then data={'Resetting',"background-color: #66ff66"} end
            
            if state=='complete' then data={'Complete',"background-color: #ffff66"} end
            if state=='completing' then data={'Completing',"background-color: #66ff66"} end
            if state=='execute' then data={'Execute',"background-color: #66aaff"} end
            if state=='starting' then data={'Starting',"background-color: #66ff66"} end
            if state=='idle' then data={'Idle',"background-color: #ffff66"} end
            
            if state=='holding' then data={'Holding',"background-color: #66ff66"} end
            if state=='hold' then data={'Hold',"background-color: #ffff66"} end
            if state=='un-holding' then data={'Un-Holding',"background-color: #66ff66"} end
            
            if data then
                simUI.setButtonText(packMLStateUi,1,data[1])
                simUI.setStyleSheet(packMLStateUi,1,'* {'..data[2]..'; min-width: 170px; min-height: 75px; font-size: 20px; font-weight: bold;}')
            end
        else
            simUI.setStyleSheet(packMLStateUi,1,"* {background-color: #bbffbb}")
            simUI.setStyleSheet(packMLStateUi,2,"* {background-color: #ffffbb}")
            simUI.setStyleSheet(packMLStateUi,3,"* {background-color: #bbffbb}")
            simUI.setStyleSheet(packMLStateUi,4,"* {background-color: #bbffbb}")
            simUI.setStyleSheet(packMLStateUi,5,"* {background-color: #ffffbb}")

            simUI.setStyleSheet(packMLStateUi,6,"* {background-color: #bbffbb}")
            simUI.setStyleSheet(packMLStateUi,7,"* {background-color: #ffffbb}")
            simUI.setStyleSheet(packMLStateUi,8,"* {background-color: #bbffbb}")
            simUI.setStyleSheet(packMLStateUi,9,"* {background-color: #bbffbb}")

            simUI.setStyleSheet(packMLStateUi,10,"* {background-color: #ffffbb}")
            simUI.setStyleSheet(packMLStateUi,11,"* {background-color: #bbffbb}")
            simUI.setStyleSheet(packMLStateUi,12,"* {background-color: #bbddff}")
            simUI.setStyleSheet(packMLStateUi,13,"* {background-color: #bbffbb}")
            simUI.setStyleSheet(packMLStateUi,14,"* {background-color: #ffffbb}")

            simUI.setStyleSheet(packMLStateUi,15,"* {background-color: #bbffbb}")
            simUI.setStyleSheet(packMLStateUi,16,"* {background-color: #ffffbb}")
            simUI.setStyleSheet(packMLStateUi,17,"* {background-color: #bbffbb}")
            
            state=string.lower(state)
            local id=-1
            if state=='aborting' then id=1 end
            if state=='aborted' then id=2 end
            if state=='clearing' then id=3 end
            if state=='stopping' then id=4 end
            if state=='stopped' then id=5 end
            if state=='suspending' then id=6 end
            if state=='suspended' then id=7 end
            if state=='un-suspending' then id=8 end
            if state=='resetting' then id=9 end
            if state=='complete' then id=10 end
            if state=='completing' then id=11 end
            if state=='execute' then id=12 end
            if state=='starting' then id=13 end
            if state=='idle' then id=14 end
            if state=='holding' then id=15 end
            if state=='hold' then id=16 end
            if state=='un-holding' then id=17 end
            
            if id>=0 then
                simUI.setStyleSheet(packMLStateUi,id,"* {background-color: #ff6600}")
            end
        end
    end
end

function packMLState_createDlg()
    if bwfPluginLoaded and not packMLStateUi then
        if simplifiedPackMLDisplay then
            local xml =[[
                    <button text="PackML State" enabled="false" id="1" style="* {min-width: 170px; min-height: 75px; font-size: 20px; font-weight: bold;}"/>   
                    ]]
            packMLStateUi=simBWF.createCustomUi(xml,'Current PackML state',packMLState_previousDlgPos,true,'packMLState_onClose',false,false,false)
        else
            local xml =[[
                    <image geometry="0,0,1088,607" width="702" height="390" id="1000"/>
                    
                    <button text="Aborting" geometry="591,312,79,50" enabled="false" id="1" style="* {background-color: #bbffbb}"/>                
                    <button text="Aborted" geometry="451,312,79,50" enabled="false" id="2" style="* {background-color: #ffffbb}"/>                
                    <button text="Clearing" geometry="311,312,79,50" enabled="false" id="3" style="* {background-color: #bbffbb}"/>                
                    <button text="Stopping" geometry="170,312,79,50" enabled="false" id="4" style="* {background-color: #bbffbb}"/>                
                    <button text="Stopped" geometry="29,312,79,50" enabled="false" id="5" style="* {background-color: #ffffbb}"/>                
                    
                    <button text="Suspending" geometry="451,187,79,50" enabled="false" id="6" style="* {background-color: #bbffbb}"/>                
                    <button text="Suspended" geometry="311,187,79,50" enabled="false" id="7" style="* {background-color: #ffffbb}"/>                
                    <button text="Un-Suspending" geometry="170,187,79,50" enabled="false" id="8" style="* {background-color: #bbffbb}"/>                
                    <button text="Resetting" geometry="29,187,79,50" enabled="false" id="9" style="* {background-color: #bbffbb}"/>                

                    <button text="Complete" geometry="591,108,79,50" enabled="false" id="10" style="* {background-color: #ffffbb}"/>                
                    <button text="Completing" geometry="451,108,79,50" enabled="false" id="11" style="* {background-color: #bbffbb}"/>                
                    <button text="Execute" geometry="311,108,79,50" enabled="false" id="12" style="* {background-color: #bbddff}"/>                
                    <button text="Starting" geometry="170,108,79,50" enabled="false" id="13" style="* {background-color: #bbffbb}"/>                
                    <button text="Idle" geometry="29,108,79,50" enabled="false" id="14" style="* {background-color: #ffffbb}"/>                

                    <button text="Holding" geometry="451,30,79,50" enabled="false" id="15" style="* {background-color: #bbffbb}"/>                
                    <button text="Hold" geometry="311,30,79,50" enabled="false" id="16" style="* {background-color: #ffffbb}"/>                
                    <button text="Un-Holding" geometry="170,30,79,50" enabled="false" id="17" style="* {background-color: #bbffbb}"/>                
                    ]]
            packMLStateUi=simBWF.createCustomUi(xml,'Current PackML state',packMLState_previousDlgPos,true,'packMLState_onClose',false,false,false,'layout="none"',{702,390})

            local img=nil
            local c=sim.unpackTable(sim.readCustomDataBlock(model,simBWF.BLUEREALITYAPP_TAG))
            if not c.packedPackMlStateImage then
                local file=io.open("d:/v_rep/textures/packML2-selfMade.png","rb")
                img=file:read("*a")
                c.packedPackMlStateImage=img
                sim.writeCustomDataBlock(model,simBWF.BLUEREALITYAPP_TAG,sim.packTable(c))
            end

            -- We have the image stored in PNG
            img="@mem"..c.packedPackMlStateImage
            img=sim.loadImage(0,img)
            
            simUI.setImageData(packMLStateUi,1000,img,702,390)
        end
    end
end



function sysCall_init()
    bwfPluginLoaded=sim.isPluginLoaded('Bwf')
    model=sim.getObjectAssociatedWithScript(sim.handle_self)
    version=sim.getInt32Parameter(sim.intparam_program_version)
    revision=sim.getInt32Parameter(sim.intparam_program_revision)
    local data=sim.readCustomDataBlock(model,simBWF.BLUEREALITYAPP_TAG)
    data=sim.unpackTable(data)
    online=simBWF.isSystemOnline()
    startTime_real=sim.getSystemTimeInMs(-1)
end

function sysCall_sensing()
--    socket = require("socket")
--    socket.sleep(0.05)
--    sim.auxFunc('sleep',0.05)
    local data=sim.readCustomDataBlock(model,simBWF.BLUEREALITYAPP_TAG)
    data=sim.unpackTable(data)
    if (version>30400 or revision>12) then
        simplifiedPackMLDisplay=sim.boolAnd32(data.bitCoded,2)>0
        if sim.boolAnd32(data.bitCoded,1)>0 then
            if simplifiedPackMLDisplay~=previousSimplifiedPackMLDisplay then
                packMLState_hideState()
                packMLState_previousDlgPos=nil
                previousSimplifiedPackMLDisplay=simplifiedPackMLDisplay
            end
            if not packMLStateDlg_wasClosed then
                packMLState_createDlg()
            end
        else
            packMLState_hideState()
            packMLStateDlg_wasClosed=nil
        end

        simplifiedTimeDisplay=sim.boolAnd32(data.bitCoded,8)>0
        if sim.boolAnd32(data.bitCoded,4)>0 then
            if simplifiedTimeDisplay~=previousSimplifiedTimeDisplay then
                timeUi_hide()
                timeUi_previousDlgPos=nil
                previousSimplifiedTimeDisplay=simplifiedTimeDisplay
            end
            if not timeDlg_wasClosed then
                timeUi_createDlg()
            end
        else
            timeUi_hide()
            timeDlg_wasClosed=nil
        end
    end
    
    
    if timeUi then
        local t={sim.getSimulationTime(),sim.getSystemTimeInMs(startTime_real)/1000}
        local cnt=2
        if simplifiedTimeDisplay or online then
            cnt=1
        end
        if online then
            t={sim.getSystemTimeInMs(startTime_real)/1000}
        end
        for i=1,cnt,1 do
            local v=t[i]
            local hour=math.floor(v/3600)
            v=v-3600*hour
            local minute=math.floor(v/60)
            v=v-60*minute
            local second=math.floor(v)
            v=v-second
            local hs=math.floor(v*100)
            local str=simBWF.format("%02d",hour)..':'..simBWF.format("%02d",minute)..':'..simBWF.format("%02d",second)..'.'..simBWF.format("%02d",hs)
            simUI.setLabelText(timeUi,i,str,true)
        end
    end
    
    if packMLStateUi then
        local msg,data=simBWF.query('packml_getState',{})
        local state='none'
        if msg=='ok' then
            state=data.state
        else
            -- We fake a state:
            local allStates={'aborting','aborted','clearing','stopping','stopped','suspending','suspended','un-suspending','resetting','complete','completing','execute','starting','idle','holding','hold','un-holding'}
            if not __fakeState__ then
                __fakeState__=0
            end
            __fakeState__=__fakeState__+1
            if __fakeState__>#allStates then
                __fakeState__=1
            end
            state=allStates[__fakeState__]
        end
        packMLState_showState(state)  
    end
end


function sysCall_cleanup()
    if timeUi then
        simUI.destroy(timeUi)
    end
    if packMLStateUi then
        simUI.destroy(packMLStateUi)
    end
end
