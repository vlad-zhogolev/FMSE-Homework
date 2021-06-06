
#define INTERSECTIONS_NUMBER 3
#define ROUTES_NUMBER 3
#define BUFSIZE 0
#define MAX_INTERSECTIONS_NUMBER INTERSECTIONS_NUMBER

typedef RouteConfig
{
    int routeId;
    int intersectionIds[MAX_INTERSECTIONS_NUMBER];
    int intersectionIdsLength;
}

typedef Intersection
{
    bool isAcquired;
    bool isAcquisitionSucceded;
    int owner;
    int firstRouteId;
    int secondRouteId;
}

mtype = {green, red};


bool isIntersectionOccupied [INTERSECTIONS_NUMBER] = {false, false, false};
mtype trafficLights [ROUTES_NUMBER] = {red, red, red, red, red};
Intersection Intersections [ROUTES_NUMBER];
RouteConfig RouteConfigs [ROUTES_NUMBER];

int flag [ROUTES_NUMBER] = {0, 0, 0, 0, 0};
int turn [ROUTES_NUMBER] = {0, 0, 0, 0, 0};

chan trafficChannels [ROUTES_NUMBER] = [1] of {bool};
chan turnChannel [ROUTES_NUMBER] = [0] of {bool};

bool locked = false;

inline InitIntersection(int index)
{
    Intersections[i].isAcquired = false;
    Intersections[i].isAcquisitionSucceded = false;
    Intersections[i].owner = ROUTES_NUMBER;
    Intersections[i].firstRouteId = ROUTES_NUMBER;
    Intersections[i].secondRouteId = ROUTES_NUMBER;
}

inline InitRouteConfig(int index)
{
    if
    ::  index == 0 ->
        RouteConfigs[0].routeId = 0;
        RouteConfigs[0].intersectionIds = {0, 2};
        RouteConfigs[0].intersectionIdsLength = 2;
    ::  index == 1 ->
        RouteConfigs[1].routeId = 1;
        RouteConfigs[1].intersectionIds = {1, 0};
        RouteConfigs[1].intersectionIdsLength = 2;
    ::  index == 2 ->
        RouteConfigs[2].routeId = 2;
        RouteConfigs[2].intersectionIds = {2, 1};
        RouteConfigs[2].intersectionIdsLength = 2;
    fi
}

// Can't call twice in sequence by the same route without calling ReleaseIntersection(...).
inline TryAcquireIntersection(int index, int routeId)
{
    if
    ::  Intersections[index].isAcquired ->
        Intersections[index].isAcquisitionSucceded = false;
        if
        ::  Intersections[index].firstRouteId == ROUTES_NUMBER -> //process is first in queue
            Intersections[index].firstRouteId = routeId;

        ::  Intersections[index].firstRouteId != routeId && Intersections[index].firstRouteId != ROUTES_NUMBER ->
            Intersections[index].secondRouteId = routeId;

        ::  else ->
            // can't be since resource is acquired by other route
            printf("[TryAcquireIntersection] [Route %d] Error during intersection acquisition 1\n", routeId);
        fi;
    ::  else ->
        if
        ::  Intersections[index].firstRouteId == ROUTES_NUMBER ->
            Intersections[index].isAcquired = true;
            Intersections[index].isAcquisitionSucceded = true;
            Intersections[index].owner = routeId;

        ::  Intersections[index].firstRouteId == routeId ->
            Intersections[index].isAcquired = true;
            Intersections[index].isAcquisitionSucceded = true;
            Intersections[index].owner = routeId;
            Intersections[index].firstRouteId = Intersections[index].secondRouteId;
            Intersections[index].secondRouteId = ROUTES_NUMBER;

        ::  Intersections[index].firstRouteId != routeId && Intersections[index].firstRouteId != ROUTES_NUMBER
            Intersections[index].isAcquisitionSucceded = false;
            Intersections[index].secondRouteId = routeId;
        
        ::  else ->
            // can't be since the other route had to move us to first position
            printf("[TryAcquireIntersection] [Route %d] Error during intersection acquisition 2\n", routeId);
        fi
    fi
}

inline ReleaseIntersection(int index)
{
    if
    ::  routeId == Intersections[index].owner ->
        Intersections[index].isAcquired = false;
        Intersections[index].owner = ROUTES_NUMBER;
    fi
}

proctype TrafficGenerator(int routeId; chan trafficChannel)
{
    do
    ::  trafficChannel! true;
        printf("[TrafficGenerator] [Route %d] New traffic\n", routeId);
    od
}

proctype Controller(int routeId; RouteConfig config; chan prevChannel, nextChannel, trafficChannel)
{
    do
    ::  prevChannel? _ ->
        printf("[Controller] [Route %d] My turn:\n", routeId);
        int j = 0;
        do
        ::  j < config.intersectionIdsLength ->
            int id = config.intersectionIds[j];
            ReleaseIntersection(id, routeId);
            j++;
        ::  else ->
            break;
        od;

        if
        ::  nempty(trafficChannel) ->
            bool isAllIntersectionsAcquired = true;
            int i = 0;
            do
            ::  i < config.intersectionIdsLength ->
                int id = config.intersectionIds[i];
                TryAcquireIntersection(id, routeId);
                isAllIntersectionsAcquired = isAllIntersectionsAcquired && Intersections[id].isAcquisitionSucceded;
                Intersections[id].isAcquisitionSucceded = false;
                i++;
            ::  else ->
                break;
            od;
            
            if
            ::  !isAllIntersectionsAcquired ->
                nextChannel! true;
            ::  else ->
                nextChannel! true;

                // Pass cars
                trafficLights[routeId] = green;
                printf("[Controller] [Route %d] Switched light to green\n", routeId);
                trafficChannel? _ ;
                printf("[Controller] [Route %d] Cars passed\n", routeId);
                trafficLights[routeId] = red;
                printf("[Controller] [Route %d] Switched light to red\n", routeId);
                locked = false;
            fi
        ::  empty(trafficChannel) ->
            nextChannel! true;
        fi;
        printf("[Controller] [Route %d] Pass turn\n", routeId);
    od
}

active proctype main()
{
    int intersectionId = 0;
    do
    ::  intersectionId < INTERSECTIONS_NUMBER ->
        InitIntersection(intersectionId);
        intersectionId++;
    ::  else ->
        break;
    od;

    int routeId = 0;
    do
    ::  routeId < ROUTES_NUMBER ->
        InitRouteConfig(routeId);
        routeId++;
    ::  else ->
        break;
    od;

    routeId = 0;
    do
    ::  routeId < ROUTES_NUMBER ->
        run TrafficGenerator(routeId, trafficChannels[routeId])
        int nextRouteId = (routeId + 1) % ROUTES_NUMBER;
        run Controller(routeId, RouteConfigs[routeId], turnChannel[routeId], turnChannel[nextRouteId], trafficChannels[routeId]);
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