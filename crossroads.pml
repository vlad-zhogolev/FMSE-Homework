
#define INTERSECTION_NUMBER 3
#define ROUTES_NUMBER 3
#define BUFSIZE 0
#define MAX_INTERSECTIONS_NUMBER INTERSECTION_NUMBER

bool isIntersectionOccupied [INTERSECTION_NUMBER] = {false, false, false};
bool request [ROUTES_NUMBER] = {false, false, false};
chan trafficChannels [ROUTES_NUMBER] = [0] of {byte};
chan controllerChannels [ROUTES_NUMBER] = [0] of {byte};


typedef RouteConfig
{
    byte routeId;
    byte intersectionIds[MAX_INTERSECTIONS_NUMBER];
    byte intersectionIdsLength;
}

proctype TrafficGenerator(int routeId; chan trafficChannel)
{
    do
    ::  if
        :: true ->
            printf("[TrafficGenerator] New traffic for route: %d\n", routeId)
            trafficChannel! 1 //just dummy
        :: true ->
            printf("[TrafficGenerator] No new traffic for route: %d\n", routeId)
            // skip // no new object
        fi
    od
}

proctype Sensor(int routeId; /*chan controllerChannel,*/ chan trafficChannel)
{
    byte object;
    do
    ::  true ->
        bool isObjectDetedcted = false;
        if
        :: trafficChannel? object ->
            printf("[Sensor] Object appeared for route: %d:\n", routeId);
            isObjectDetedcted = true;
        fi;
        if
        :: !request[routeId] && isObjectDetedcted ->
            printf("[Sensor] Make request for route: %d:\n", routeId);
            request[routeId] = true; // need sync
        fi
    od
}

proctype Controller(int routeId)
{
    do
    ::  request[routeId] ->
        printf("[Controller] Handle request for route: %d:\n", routeId);
        request[routeId] = false; // need sync
    od
}

active proctype main()
{
    run Sensor(0, trafficChannels[0]);
    run TrafficGenerator(0, trafficChannels[0])
    run Controller(0);
}