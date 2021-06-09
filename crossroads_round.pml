
#define INTERSECTIONS_NUMBER 9
#define ROUTES_NUMBER 6
#define MAX_INTERSECTIONS_NUMBER 4

typedef RouteConfig
{
    byte intersectionIds[MAX_INTERSECTIONS_NUMBER];
    byte intersectionIdsLength;
}

typedef Intersection
{
    byte owner;
    byte firstRouteId;
    byte secondRouteId;
}

mtype = {green, red};


mtype trafficLights [ROUTES_NUMBER] = {red, red, red, red, red, red};
Intersection Intersections [INTERSECTIONS_NUMBER];
RouteConfig RouteConfigs [ROUTES_NUMBER];

chan trafficChannels [ROUTES_NUMBER] = [1] of {bool};
chan turnChannel [ROUTES_NUMBER] = [0] of {bool};
bool isAcquisitionSucceded = false;


inline InitIntersection(i)
{
    Intersections[i].owner = ROUTES_NUMBER;
    Intersections[i].firstRouteId = ROUTES_NUMBER;
    Intersections[i].secondRouteId = ROUTES_NUMBER;
}

inline InitRouteConfig(routeId)
{
    if
    ::  routeId == 0 ->
        RouteConfigs[routeId].intersectionIds[0] = 2;
        RouteConfigs[routeId].intersectionIds[1] = 4;
        RouteConfigs[routeId].intersectionIds[2] = 6;
        RouteConfigs[routeId].intersectionIdsLength = 3;

    ::  routeId == 1 ->
        RouteConfigs[routeId].intersectionIds[0] = 0;
        RouteConfigs[routeId].intersectionIds[1] = 6;
        RouteConfigs[routeId].intersectionIdsLength = 2;

    ::  routeId == 2 ->
        RouteConfigs[routeId].intersectionIds[0] = 1;
        RouteConfigs[routeId].intersectionIds[1] = 4;
        RouteConfigs[routeId].intersectionIds[2] = 7;
        RouteConfigs[routeId].intersectionIds[3] = 8;
        RouteConfigs[routeId].intersectionIdsLength = 4;

    ::  routeId == 3 ->
        RouteConfigs[routeId].intersectionIds[0] = 0;
        RouteConfigs[routeId].intersectionIds[1] = 1;
        RouteConfigs[routeId].intersectionIds[2] = 2;
        RouteConfigs[routeId].intersectionIds[3] = 3;
        RouteConfigs[routeId].intersectionIdsLength = 4;

    ::  routeId == 4 ->
        RouteConfigs[routeId].intersectionIds[0] = 5;
        RouteConfigs[routeId].intersectionIds[1] = 7;
        RouteConfigs[routeId].intersectionIdsLength = 2;

    ::  routeId == 5 ->
        RouteConfigs[routeId].intersectionIds[0] = 3;
        RouteConfigs[routeId].intersectionIds[1] = 5;
        RouteConfigs[routeId].intersectionIds[2] = 8;
        RouteConfigs[routeId].intersectionIdsLength = 3;
    fi;
}


// Can't call twice in sequence by the same route without calling ReleaseIntersection(...).
inline TryAcquireIntersection(index, routeId)
{
    // printf("[TryAcquireIntersection] [Route %d] Intersection %d, firstRouteId: %d, secondRouteId: %d, owner: %d, \n", routeId, index, Intersections[index].firstRouteId, Intersections[index].secondRouteId, Intersections[index].owner);
    if
    ::  Intersections[index].owner != ROUTES_NUMBER
        isAcquisitionSucceded = false;
        if
        ::  Intersections[index].firstRouteId == ROUTES_NUMBER -> //process is first in queue
            Intersections[index].firstRouteId = routeId;
            // printf("[TryAcquireIntersection] [Route %d] Intersection already acquired, 1 in queue , firstRouteId: %d, secondRouteId: %d, owner: %d, \n", routeId, Intersections[index].firstRouteId, Intersections[index].secondRouteId, Intersections[index].owner);

        ::  Intersections[index].firstRouteId != ROUTES_NUMBER && Intersections[index].firstRouteId != routeId ->
            Intersections[index].secondRouteId = routeId;
            // printf("[TryAcquireIntersection] [Route %d] Intersection already acquired, 2 in queue , firstRouteId: %d, secondRouteId: %d, owner: %d, \n", routeId, Intersections[index].firstRouteId, Intersections[index].secondRouteId, Intersections[index].owner);

        // ::  else ->
        //     // can't be since resource is acquired by other route
        //     printf("[TryAcquireIntersection] [Route %d] Error during intersection acquisition 1, firstRouteId: %d, secondRouteId: %d, owner: %d, \n", routeId, Intersections[index].firstRouteId, Intersections[index].secondRouteId, Intersections[index].owner);
        fi;
    ::  else ->
        if
        ::  Intersections[index].firstRouteId == ROUTES_NUMBER || Intersections[index].firstRouteId == routeId ->
            isAcquisitionSucceded = true;
            Intersections[index].firstRouteId = routeId;

            // printf("[TryAcquireIntersection] [Route %d] Can acquire intersection, firstRouteId: %d, secondRouteId: %d, owner: %d, \n", routeId, Intersections[index].firstRouteId, Intersections[index].secondRouteId, Intersections[index].owner);

        ::  Intersections[index].firstRouteId != routeId && Intersections[index].firstRouteId != ROUTES_NUMBER
            isAcquisitionSucceded = false;
            Intersections[index].secondRouteId = routeId;
            // printf("[TryAcquireIntersection] [Route %d] Can't acquire intersection, 2 in queue , firstRouteId: %d, secondRouteId: %d, owner: %d, \n", routeId, Intersections[index].firstRouteId, Intersections[index].secondRouteId, Intersections[index].owner);
        
        // ::  else ->
        //     // can't be since the other route had to move us to first position
        //     printf("[TryAcquireIntersection] [Route %d] Error during intersection acquisition 2, firstRouteId: %d, secondRouteId: %d, owner: %d, \n", routeId, Intersections[index].firstRouteId, Intersections[index].secondRouteId, Intersections[index].owner);
        fi;
    fi
}

inline SetAsOwner(index, routeId)
{
    Intersections[index].owner = routeId;
    // printf("[SetAsOwner] [Route %d] Set as owner for intersection %d\n", routeId, index);
}

inline ReleaseIntersection(index, routeId)
{
    // printf("[ReleaseIntersection] [Route %d] Try release intersection %d\n", routeId, index);
    if
    ::  routeId == Intersections[index].owner ->
        Intersections[index].owner = ROUTES_NUMBER;
        Intersections[index].firstRouteId = Intersections[index].secondRouteId;
        Intersections[index].secondRouteId = ROUTES_NUMBER;
        // printf("[ReleaseIntersection] [Route %d] Release intersection %d\n", routeId, index);
    ::  else ->
        skip;
        // printf("[ReleaseIntersection] [Route %d] Release skip %d\n", routeId, index);
    fi
}

proctype TrafficGenerator(byte routeId; chan trafficChannel)
{
    do
    ::  trafficChannel! true;
        // printf("[TrsafficGenerator] [Route %d] New traffic\n", routeId);
    od
}

proctype Controller(byte routeId; chan prevChannel, nextChannel, trafficChannel)
{
    do
    ::  prevChannel? _ ->
        // printf("[Controller] [Route %d] My turn:\n", routeId);
        byte i = 0;
        do
        ::  (i < RouteConfigs[routeId].intersectionIdsLength) ->
            ReleaseIntersection(RouteConfigs[routeId].intersectionIds[i], routeId);
            i++;
        ::  else ->
            break;
        od;

        // printf("[Controller] [Route %d] Released resources:\n", routeId);

        if
        ::  empty(trafficChannel) ->
            nextChannel! true;
        ::  nempty(trafficChannel) ->
            bool isAllIntersectionsAcquired = true;
            // Try get all required intersections
            i = 0;
            do
            ::  i < RouteConfigs[routeId].intersectionIdsLength ->
                TryAcquireIntersection(RouteConfigs[routeId].intersectionIds[i], routeId);
                isAllIntersectionsAcquired = isAllIntersectionsAcquired && isAcquisitionSucceded;
                isAcquisitionSucceded = false;
                i++;
            ::  else ->
                break;
            od;
            
            if
            ::  !isAllIntersectionsAcquired -> // Failed to get all of them but stepped into queue
                nextChannel! true;
            ::  else ->
                i = 0;
                do
                ::  i < RouteConfigs[routeId].intersectionIdsLength ->
                    SetAsOwner(RouteConfigs[routeId].intersectionIds[i], routeId);
                    i++;
                ::  else ->
                    break;
                od;
                nextChannel! true;

                // Pass cars
                trafficLights[routeId] = green;
                // printf("[Controller] [Route %d] Switched light to green\n", routeId);
                trafficChannel? _ ;
                // printf("[Controller] [Route %d] Cars passed\n", routeId);
                trafficLights[routeId] = red;
                // printf("[Controller] [Route %d] Switched light to red\n", routeId);
            fi
        fi;
    od
}

active proctype main()
{
    byte intersectionId = 0;
    do
    ::  intersectionId < INTERSECTIONS_NUMBER ->
        InitIntersection(intersectionId);
        intersectionId++;
    ::  else ->
        break;
    od;

    byte routeId = 0;
    do
    ::  routeId < ROUTES_NUMBER ->
        InitRouteConfig(routeId);
        run TrafficGenerator(routeId, trafficChannels[routeId])
        byte nextRouteId = (routeId + 1) % ROUTES_NUMBER;
        run Controller(routeId, turnChannel[routeId], turnChannel[nextRouteId], trafficChannels[routeId]);
        routeId++;
    ::  else ->
        break;
    od;

    turnChannel[0]! true; // start traffic processing
}

#define tl_green_0 (trafficLights[0] == green)
#define tl_green_1 (trafficLights[1] == green)
#define tl_green_2 (trafficLights[2] == green)
#define tl_green_3 (trafficLights[3] == green)
#define tl_green_4 (trafficLights[4] == green)
#define tl_green_5 (trafficLights[5] == green)


#define traffic_present_0 (len(trafficChannels[0]) > 0)
#define traffic_present_1 (len(trafficChannels[1]) > 0)
#define traffic_present_2 (len(trafficChannels[2]) > 0)
#define traffic_present_3 (len(trafficChannels[3]) > 0)
#define traffic_present_4 (len(trafficChannels[4]) > 0)
#define traffic_present_5 (len(trafficChannels[5]) > 0)


ltl safety_0_1 { [] !(tl_green_0 && tl_green_1)}
ltl safety_0_2 { [] !(tl_green_0 && tl_green_2)}
ltl safety_0_3 { [] !(tl_green_0 && tl_green_3)}
ltl safety_1_3 { [] !(tl_green_1 && tl_green_3)}
ltl safety_2_3 { [] !(tl_green_2 && tl_green_3)}
ltl safety_2_4 { [] !(tl_green_2 && tl_green_4)}
ltl safety_2_5 { [] !(tl_green_2 && tl_green_5)}
ltl safety_3_5 { [] !(tl_green_3 && tl_green_5)}
ltl safety_4_5 { [] !(tl_green_4 && tl_green_5)}


// Check if buffered channel is not empty for liveness and then expect green light to appear
ltl liveness_0 {[] (traffic_present_0 -> <> tl_green_0)}
ltl liveness_1 {[] (traffic_present_1 -> <> tl_green_1)}
ltl liveness_2 {[] (traffic_present_2 -> <> tl_green_2)}
ltl liveness_3 {[] (traffic_present_3 -> <> tl_green_3)}
ltl liveness_4 {[] (traffic_present_4 -> <> tl_green_4)}
ltl liveness_5 {[] (traffic_present_5 -> <> tl_green_5)}


ltl fairness_0 {[] <> !(tl_green_0 && traffic_present_0)} // check if really need traffic_present_0
ltl fairness_1 {[] <> !(tl_green_1 && traffic_present_1)}
ltl fairness_2 {[] <> !(tl_green_2 && traffic_present_2)}
ltl fairness_3 {[] <> !(tl_green_3 && traffic_present_3)}
ltl fairness_4 {[] <> !(tl_green_4 && traffic_present_4)}
ltl fairness_5 {[] <> !(tl_green_5 && traffic_present_5)}


ltl check_no_traffic_possible {<> (traffic_present_0 || traffic_present_1 || traffic_present_2 || traffic_present_3 || traffic_present_4 || traffic_present_5)}
ltl check_both_green_0_4 {[] !(tl_green_0 && tl_green_4)}