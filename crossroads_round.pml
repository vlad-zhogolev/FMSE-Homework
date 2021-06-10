
#define INTERSECTIONS_NUMBER 9
#define ROUTES_NUMBER 6
#define MAX_INTERSECTIONS_NUMBER 4

#define for(I,low,high) \
    byte I = low; \
    do \
    :: ( I >= high ) -> \
        break; \
    :: else ->

#define rof(I) \
    ; I++ \
    od

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
    isAcquisitionSucceded = false;
    // printf("[TryAcquireIntersection %d] [Route %d] firstRouteId: %d, secondRouteId: %d, owner: %d, \n", index, routeId, Intersections[index].firstRouteId, Intersections[index].secondRouteId, Intersections[index].owner);
    if
    ::  Intersections[index].owner != ROUTES_NUMBER // there is owner
        Intersections[index].secondRouteId = routeId; // owner is also in queue, so take 2nd place
    ::  else -> // no owner
        if
        ::  Intersections[index].firstRouteId == ROUTES_NUMBER -> // no one in queue
            isAcquisitionSucceded = true;
            Intersections[index].firstRouteId = routeId;
        ::  Intersections[index].firstRouteId == routeId -> // the process is already waiting to become an owner
            isAcquisitionSucceded = true;
        ::  else -> // someone already waiting, so take 2nd place
            Intersections[index].secondRouteId = routeId;
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

        for (i, 0, RouteConfigs[routeId].intersectionIdsLength)
            ReleaseIntersection(RouteConfigs[routeId].intersectionIds[i], routeId);
        rof (i);

        if
        ::  empty(trafficChannel) ->
            nextChannel! true;

        ::  nempty(trafficChannel) ->

            bool isAllAcquired = true;
            for (j, 0, RouteConfigs[routeId].intersectionIdsLength)
                TryAcquireIntersection(RouteConfigs[routeId].intersectionIds[j], routeId);
                isAllAcquired = isAllAcquired && isAcquisitionSucceded;
            rof (j);
            
            if
            ::  !isAllAcquired ->
                nextChannel! true;
            ::  else ->
                for (k, 0, RouteConfigs[routeId].intersectionIdsLength)
                    SetAsOwner(RouteConfigs[routeId].intersectionIds[k], routeId);
                rof (k);
                nextChannel! true;

                // Pass cars
                trafficLights[routeId] = green;
                trafficChannel? _ ;
                trafficLights[routeId] = red;
            fi
        fi;
    od
}

active proctype main()
{
    for (intersectionId, 0, INTERSECTIONS_NUMBER)
        InitIntersection(intersectionId);
    rof (intersectionId);

    for (routeId, 0, ROUTES_NUMBER)
        InitRouteConfig(routeId);
        run TrafficGenerator(routeId, trafficChannels[routeId])
        byte nextRouteId = (routeId + 1) % ROUTES_NUMBER;
        run Controller(routeId, turnChannel[routeId], turnChannel[nextRouteId], trafficChannels[routeId]);
    rof (routeId);

    turnChannel[0]! true; // start traffic processing
}

#define tl_green(i) (trafficLights[i] == green)
#define traffic_present(i) (len(trafficChannels[i]) > 0)


ltl safety_0_1 { [] !(tl_green(0) && tl_green(1))}
ltl safety_0_2 { [] !(tl_green(0) && tl_green(2))}
ltl safety_0_3 { [] !(tl_green(0) && tl_green(3))}
ltl safety_1_3 { [] !(tl_green(1) && tl_green(3))}
ltl safety_2_3 { [] !(tl_green(2) && tl_green(3))}
ltl safety_2_4 { [] !(tl_green(2) && tl_green(4))}
ltl safety_2_5 { [] !(tl_green(2) && tl_green(5))}
ltl safety_3_5 { [] !(tl_green(3) && tl_green(5))}
ltl safety_4_5 { [] !(tl_green(4) && tl_green(5))}


// Check if buffered channel is not empty for liveness and then expect green light to appear
ltl liveness_0 {[] (traffic_present(0) -> <> tl_green(0)}
ltl liveness_1 {[] (traffic_present(1) -> <> tl_green(1)}
ltl liveness_2 {[] (traffic_present(2) -> <> tl_green(2)}
ltl liveness_3 {[] (traffic_present(3) -> <> tl_green(3)}
ltl liveness_4 {[] (traffic_present(4) -> <> tl_green(4)}
ltl liveness_5 {[] (traffic_present(5) -> <> tl_green(5)}


ltl fairness_0 {[] <> !(tl_green(0) && traffic_present(0))} // check if really need traffic_present_0
ltl fairness_1 {[] <> !(tl_green(1) && traffic_present(1))}
ltl fairness_2 {[] <> !(tl_green(2) && traffic_present(2))}
ltl fairness_3 {[] <> !(tl_green(3) && traffic_present(3))}
ltl fairness_4 {[] <> !(tl_green(4) && traffic_present(4))}
ltl fairness_5 {[] <> !(tl_green(5) && traffic_present(5))}


ltl check_no_traffic_possible {<> (traffic_present(0) || traffic_present(1) || traffic_present(2) || traffic_present(3) || traffic_present(4) || traffic_present(5))}
ltl check_both_green_0_4 {[] !(tl_green(0) && tl_green(4))}