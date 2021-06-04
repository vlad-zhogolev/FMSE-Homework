
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

chan trafficChannels [ROUTES_NUMBER] = [0] of {bool};
chan controllerChannels [ROUTES_NUMBER] = [0] of {byte};
chan lightChannels [ROUTES_NUMBER] = [0] of {mtype};


proctype TrafficGenerator(int routeId; chan trafficChannel)
{
    do
    :: true ->
        printf("[TrafficGenerator] [Route %d] New traffic\n", routeId);
        trafficChannel! true;
        printf("[TrafficGenerator] [Route %d] Wait for green light\n", routeId);
        trafficLights[routeId] == green;
        printf("[TrafficGenerator] [Route %d] Notify about traffic absence\n", routeId);
        trafficChannel! false;
        printf("[TrafficGenerator] [Route %d] Wait for red light\n", routeId);
        trafficLights[routeId] == red;
    // Leads to violation of p1 property. Creates acceptance loop being executed forever.
    // Process responsible for traffic light swith does not proceed to switching light to green.
    // :: true ->
    //     printf("[TrafficGenerator] [Route %d] No new traffic\n", routeId)
    //     skip // no new object
    od
}

proctype Sensor(int routeId; /*chan controllerChannel,*/ chan trafficChannel)
{
    do
    ::  trafficChannel? isObjectDetected[routeId] ->
        printf("[Sensor] [Route %d] request: %d, isObjectDetected: %d\n", routeId, request[routeId], isObjectDetected[routeId]);
        if
        :: !request[routeId] && isObjectDetected[routeId] ->
            printf("[Sensor] [Route %d] Make request\n", routeId);
            request[routeId] = true; // need sync
        :: else ->
            skip;
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
        // TODO: compete for resources
        lightChannel! green;

        printf("[Controller] [Route %d] Wait for cars to pass\n", routeId);
        isObjectDetected[routeId] == false;
        
        request[routeId] = false;
        lightChannel! red;
        printf("[Controller] [Route %d] Request completed\n", routeId);
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