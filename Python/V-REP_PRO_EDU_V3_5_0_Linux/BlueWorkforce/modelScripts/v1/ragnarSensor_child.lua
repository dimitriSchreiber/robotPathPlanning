function ext_simulationPause(isPause)
    if sensorPlot_ui then
        if isPause and lastDataFromSensor then
            setPlotData(sensorTriggerData,1)
        end
        simUI.setMouseOptions(sensorPlot_ui,1,isPause,isPause,isPause,isPause)
    end
end

function setPlotData(triggerData,plotId)
    if sensorPlot_ui then
        if plotId==1 then
            simUI.clearCurve(sensorPlot_ui,1,'l')
            simUI.clearCurve(sensorPlot_ui,1,'h')
            simUI.clearCurve(sensorPlot_ui,1,'trigger')
            local startT=0
            if triggerData.lastTime-10>0 then
                startT=triggerData.lastTime-10
            end
            local trig={}
            for i=1,#triggerData.triggerTimes,1 do
                trig[i]=4
            end
            simUI.addCurveTimePoints(sensorPlot_ui,1,'l',{startT,triggerData.lastTime},{0,0})
            simUI.addCurveTimePoints(sensorPlot_ui,1,'h',{startT,triggerData.lastTime},{4.5,4.5})
            if #trig>0 then
                simUI.addCurveTimePoints(sensorPlot_ui,1,'trigger',triggerData.triggerTimes,trig)
            end
            simUI.rescaleAxesAll(sensorPlot_ui,1,false,false)
            simUI.replot(sensorPlot_ui,1)
        end
    end
end

function getAndApplySensorState()
    
    if online then
        local data={}
        data.id=model
        local res,retData=simBWF.query('ragnarSensor_getTriggers',data)
        
        if res=='ok' then
            sensorTriggerTimesFromPlugin=retData
        else
            if simBWF.isInTestMode() then
                -- Generate fake data:
                if not blabla then
                    blabla=0
                    blabli=0
                end
                blabla=blabla+0.05
                sensorTriggerTimesFromPlugin={}
                if blabla>5 then
                        sensorTriggerTimesFromPlugin[#sensorTriggerTimesFromPlugin+1]=blabli+5
                        blabli=blabli+blabla
                        blabla=0
                end
            else
                sensorTriggerTimesFromPlugin={}
            end
        end
        sensorTriggerData.lastTime=simBWF.getSimulationOrOnlineTime()
    else
        sensorTriggerData.lastTime=sim.getSimulationTime()
    end
    if sensorTriggerTimesFromPlugin and #sensorTriggerTimesFromPlugin>0 then
        for i=1,#sensorTriggerTimesFromPlugin,1 do
            sensorTriggerData.triggerTimes[#sensorTriggerData.triggerTimes+1]=sensorTriggerTimesFromPlugin[i]
        end
    end
    if simSensorTriggers and #simSensorTriggers>0 then
        for i=1,#simSensorTriggers,1 do
            sensorTriggerData.triggerTimes[#sensorTriggerData.triggerTimes+1]=simSensorTriggers[i]
        end
        simSensorTriggers={}
    end
    -- Remove triggers that lay more then 10 seconds back:
    local ind=1
    while ind<=#sensorTriggerData.triggerTimes do
        if sensorTriggerData.triggerTimes[ind]<sensorTriggerData.lastTime-10 then
            table.remove(sensorTriggerData.triggerTimes,ind)
        else
            ind=ind+1
        end
    end
    if sensorPlot_ui then
        local updatePlot=false
        if online then    
            local dt=sim.getSystemTimeInMs(lastPlotVisualizeUpdateTimeInMs)
            if dt>plotVisUpdateFrequMs then
                updatePlot=true
                lastPlotVisualizeUpdateTimeInMs=sim.getSystemTimeInMs(-1)
            end
        else
            local t=(sim.getSimulationTime()+sim.getSimulationTimeStep())*1000
            if t+1>lastPlotVisualizeUpdateTimeInMs+plotVisUpdateFrequMs then
                updatePlot=true
                lastPlotVisualizeUpdateTimeInMs=t
            end
        end
        if sensorPlot_ui and updatePlot then
            setPlotData(sensorTriggerData,1)
        end
    end
end

function startShowingPlotForSensor()
    if not sensorPlot_ui then
        local xml=[[
                <plot id="1" max-buffer-size="1000" cyclic-buffer="false" background-color="25,25,25" foreground-color="150,150,150" y-ticks="false" y-tick-labels="false"/>
                ]]
        if not previousPlotDlgPos then
            previousPlotDlgPos="bottomRight"
        end
        sensorPlot_ui=simBWF.createCustomUi(xml,simBWF.getObjectAltName(model),previousPlotDlgPos,true,"stopShowingPlotForSensor_callback",false,true,false,nil,previousPlotDlgSize)
        simUI.setPlotLabels(sensorPlot_ui,1,"time (seconds)","trigger state")

        local curveStyle=simUI.curve_style.line
        local scatterShape={scatter_shape=simUI.curve_scatter_shape.none,scatter_size=1,line_size=1,add_to_legend=false,selectable=false,track=false}
        simUI.addCurve(sensorPlot_ui,1,simUI.curve_type.time,'l',{255,255,255},curveStyle,scatterShape)
        simUI.addCurve(sensorPlot_ui,1,simUI.curve_type.time,'h',{64,64,64},curveStyle,scatterShape)
        simUI.addCurve(sensorPlot_ui,1,simUI.curve_type.time,'trigger',{255,255,0},simUI.curve_style.scatter,{scatter_shape=simUI.curve_scatter_shape.circle,scatter_size=10,line_size=1,add_to_legend=true,selectable=true,track=false})
        simUI.setLegendVisibility(sensorPlot_ui,1,true)
 --       simUI.YLabel(sensorPlot_ui,1,''
        simUI.setMouseOptions(sensorPlot_ui,1,false,false,false,false)
    end
end

function stopShowingPlotForSensor_callback()
    sensorPlotWasClosed=true
    stopShowingPlotForSensor()
end

function stopShowingPlotForSensor()
    if sensorPlot_ui then
        local x,y=simUI.getPosition(sensorPlot_ui)
        previousPlotDlgPos={x,y}
        local x,y=simUI.getSize(sensorPlot_ui)
        previousPlotDlgSize={x,y}
        simUI.destroy(sensorPlot_ui)
        sensorPlot_ui=nil
    end
end

function sysCall_init()
    model=sim.getObjectAssociatedWithScript(sim.handle_self)
    sensor=sim.getObjectHandle('RagnarSensor_sensor')
    bwfPluginLoaded=sim.isPluginLoaded('Bwf')
    online=simBWF.isSystemOnline()
    simOrRealIndex=1
    lastPlotVisualizeUpdateTimeInMs=-1000
    if online then
        simOrRealIndex=2
        lastPlotVisualizeUpdateTimeInMs=sim.getSystemTimeInMs(-1)-1000
    end
    local properties=sim.unpackTable(sim.readCustomDataBlock(model,simBWF.RAGNARSENSOR_TAG))
    sensorTriggerData={}
    sensorTriggerData.lastTime=0
    sensorTriggerData.triggerTimes={}
    sensorPlotWasClosed=false
    lastSimSensorReading=false
    simSensorTriggers={}
end


function sysCall_customCallback1()
    local properties=sim.unpackTable(sim.readCustomDataBlock(model,simBWF.RAGNARSENSOR_TAG))
    local delaysInMs={50,200,1000}
    plotVisUpdateFrequMs=delaysInMs[properties.plotUpdateFrequ[simOrRealIndex]+1]
    
    if properties.showPlot[simOrRealIndex] then
        if not sensorPlotWasClosed then
            startShowingPlotForSensor()
        end
    else
        sensorPlotWasClosed=false
        stopShowingPlotForSensor()
    end
    getAndApplySensorState()
end


function sysCall_sensing()
    if not online then
        local res=sim.handleProximitySensor(sensor)
        if res~=lastSimSensorReading then
            if res>0 then
                simSensorTriggers[#simSensorTriggers+1]=sim.getSimulationTime()
                if bwfPluginLoaded then
                    local data={}
                    data.id=model
                    simBWF.query('ragnarSensor_trigger',data)
                end
            end
            lastSimSensorReading=res
        end
    end
end


function sysCall_cleanup()
    stopShowingPlotForSensor()
    if not online then
        sim.resetProximitySensor(sensor)
    end
end

