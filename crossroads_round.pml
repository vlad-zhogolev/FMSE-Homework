
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
mtype trafficLights [ROUTES_NUMBER] = {red, red, red, red, red};

int flag [ROUTES_NUMBER] = {0, 0, 0, 0, 0};
int turn [ROUTES_NUMBER] = {0, 0, 0, 0, 0};

chan trafficChannels [ROUTES_NUMBER] = [1] of {bool};
chan turnChannel [ROUTES_NUMBER] = [0] of {bool};


proctype TrafficGenerator(int routeId; chan trafficChannel)
{
    do
    ::  trafficChannel! true;
        printf("[TrafficGenerator] [Route %d] New traffic\n", routeId);
    od
}

proctype Controller(int routeId; chan prevChannel, nextChannel, trafficChannel)
{
    do
    ::  prevChannel? _ ->
        printf("[Controller] [Route %d] My turn:\n", routeId);
        if
        ::  nempty(trafficChannel) ->
            trafficLights[routeId] = green;
            printf("[Controller] [Route %d] Switched light to green\n", routeId);
            trafficChannel? _ ;
            printf("[Controller] [Route %d] Cars passed\n", routeId);
            trafficLights[routeId] = red;
            printf("[Controller] [Route %d] Switched light to red\n", routeId);
            nextChannel! true;
        ::  empty(trafficChannel) ->
            nextChannel! true;
        fi;
        printf("[Controller] [Route %d] Pass turn\n", routeId);
    od
}

active proctype main()
{
    int routeId = 0;
    do
    ::  routeId < ROUTES_NUMBER ->
        run TrafficGenerator(routeId, trafficChannels[routeId])
        int nextRouteId = (routeId + 1) % ROUTES_NUMBER;
        run Controller(routeId, turnChannel[routeId], turnChannel[nextRouteId], trafficChannels[routeId]);
        routeId++;
    ::  routeId == ROUTES_NUMBER ->
        break;
    od;
    turnChannel[0]! true; // start traffic processing
}


ltl safety { [] !(trafficLights[0] == green && trafficLights[1] == green && trafficLights[2] == green)}

#define traffic_present_0 (len(trafficChannels[0]) > 0)
#define traffic_present_1 (len(trafficChannels[1]) > 0)
#define traffic_present_2 (len(trafficChannels[2]) > 0)

// Check if buffered channel is not empty for liveness and then expect green light to appear
ltl liveness_0 {[] (traffic_present_0 -> <> (trafficLights[0] == green))}
ltl liveness_1 {[] (traffic_present_1 -> <> (trafficLights[1] == green))}
ltl liveness_2 {[] (traffic_present_2 -> <> (trafficLights[2] == green))}

ltl fairness_0 {[] <> !(trafficLights[0] == green && traffic_present_0)} // check if really need traffic_present_0
ltl fairness_1 {[] <> !(trafficLights[1] == green && traffic_present_1)}
ltl fairness_2 {[] <> !(trafficLights[2] == green && traffic_present_2)}


ltl check_no_traffic_possible {<> (traffic_present_0 || traffic_present_1 || traffic_present_2)}