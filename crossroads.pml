
#define INTERSECTION_NUMBER 3
#define ROUTES_NUMBER 3
#define BUFSIZE 0
#define MAX_INTERSECTIONS_NUMBER INTERSECTION_NUMBER

typedef RouteConfig
{
    byte routeId;
    byte intersectionIds[MAX_INTERSECTIONS_NUMBER];
    byte intersectionIdsLength;
}

mtype = {green, red};


bool isIntersectionOccupied [INTERSECTION_NUMBER] = {false, false, false};
bool isObjectDetected [ROUTES_NUMBER] = {false, false, false}
bool request [ROUTES_NUMBER] = {false, false, false};
mtype trafficLights [ROUTES_NUMBER] = {red, red, red};

chan trafficChannels [ROUTES_NUMBER] = [0] of {byte};
chan controllerChannels [ROUTES_NUMBER] = [0] of {byte};
chan lightChannels [ROUTES_NUMBER] = [0] of {mtype};


proctype TrafficGenerator(int routeId; chan trafficChannel)
{
    do
    :: true ->
        printf("[TrafficGenerator] [Route %d] New traffic\n", routeId)
        trafficChannel! 1 //just dummy
    // :: true ->
    //     printf("[TrafficGenerator] [Route %d] No new traffic\n", routeId)
    //     skip // no new object
    od
}

proctype Sensor(int routeId; /*chan controllerChannel,*/ chan trafficChannel)
{
    byte object;
    do
    ::  true ->
        isObjectDetected[routeId] = false;
        if
        :: trafficChannel? object ->
            printf("[Sensor] [Route %d] Object appeared \n", routeId);
            isObjectDetected[routeId] = true;
        fi;
        printf("[Sensor] [Route %d] request: %d, isObjectDetected: %d\n", routeId, request[routeId], isObjectDetected[routeId]);
        if
        :: !request[routeId] && isObjectDetected[routeId] ->
            printf("[Sensor] [Route %d] Make request\n", routeId);
            request[routeId] = true; // need sync
        fi
    od
}

proctype TrafficLight(int routeId; chan lightChannel)
{
    mtype color;
    do
    ::  lightChannel? color ->
        printf("[TrafficLight] [Route %d] Switch light color to: %e\n", routeId, color);
        trafficLights[routeId] = color;
    od
}

proctype Controller(int routeId; chan lightChannel)
{
    do
    ::  request[routeId] ->
        printf("[Controller] [Route %d] Handle request:\n", routeId);
        lightChannel! green;
        printf("[Controller] [Route %d] Wait for light change to green\n", routeId);
        trafficLights[routeId] == green;
        
        lightChannel! red;
        printf("[Controller] [Route %d] Wait for light change to red\n", routeId);
        trafficLights[routeId] == red;
        printf("[Controller] [Route %d] Request completed\n", routeId);
        request[routeId] = false;
    od
}

active proctype main()
{
    run Sensor(0, trafficChannels[0]);
    run TrafficGenerator(0, trafficChannels[0])
    run TrafficLight(0, lightChannels[0]);
    run Controller(0, lightChannels[0]);
}


ltl p1 { [] (!(isObjectDetected[0] && (trafficLights[0] == red)) || <> (trafficLights[0] == green))}