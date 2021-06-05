
#define INTERSECTION_NUMBER 3
#define ROUTES_NUMBER 2
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
bool isObjectDetected [ROUTES_NUMBER] = {false, false};
bool request [ROUTES_NUMBER] = {false, false};
mtype trafficLights [ROUTES_NUMBER] = {red, red};

bool flag [ROUTES_NUMBER] = {false, false};
int turn;   

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
    ::  trafficChannel? isObjectDetected[routeId] -> //maybe should declare local variable and write it to isObjectDetected after printf.
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
    int otherRouteId = 1 - routeId;
    do
    ::  request[routeId] ->
        printf("[Controller] [Route %d] Handle request:\n", routeId);

        // Peterson lock
        flag[routeId] = true;
        turn = otherRouteId;
        !(flag[otherRouteId] && turn == otherRouteId);

        // Critical section
        lightChannel! green;

        printf("[Controller] [Route %d] Wait for cars to pass\n", routeId);
        isObjectDetected[routeId] == false;
        
        request[routeId] = false;
        lightChannel! red;
        printf("[Controller] [Route %d] Request completed\n", routeId);
        // End of critical section

        // Peterson unlock
        flag[routeId] = false;
    od
}

active proctype main()
{
    int i = 0;
    do
    ::  i < ROUTES_NUMBER ->
        run Sensor(i, trafficChannels[i]);
        run TrafficGenerator(i, trafficChannels[i])
        run TrafficLight(i, lightChannels[i]);
        run Controller(i, lightChannels[i]);
        i++;
    ::  i == ROUTES_NUMBER ->
        break;
    od;


}

ltl safety_0_1 { [] !(trafficLights[0] == green && trafficLights[1] == green)}

ltl liveness_0 { [] (!(isObjectDetected[0] && (trafficLights[0] == red)) || <> (trafficLights[0] == green))}
ltl liveness_1 { [] (!(isObjectDetected[1] && (trafficLights[1] == red)) || <> (trafficLights[1] == green))}

ltl fairness_0 { [] <> !(trafficLights[0] == green && isObjectDetected[0])} // check if actually need isObjectDetected here
ltl fairness_1 { [] <> !(trafficLights[1] == green && isObjectDetected[1])}

// ltl liveness_2 { [] (!(isObjectDetected[2] && (trafficLights[2] == red)) || <> (trafficLights[2] == green))}
// ltl liveness_3 { [] (!(isObjectDetected[3] && (trafficLights[3] == red)) || <> (trafficLights[3] == green))}
// ltl liveness_4 { [] (!(isObjectDetected[4] && (trafficLights[4] == red)) || <> (trafficLights[4] == green))}