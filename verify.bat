spin -search -a -m1000000 -ltl safety_0_1 crossroads_round.pml
@REM spin -search -a -m1000000 -ltl safety_0_2 crossroads_round.pml
@REM spin -search -a -m1000000 -ltl safety_0_3 crossroads_round.pml
@REM spin -search -a -m1000000 -ltl safety_1_3 crossroads_round.pml
@REM spin -search -a -m1000000 -ltl safety_2_3 crossroads_round.pml

spin -search -a -m1000000 -ltl liveness_0 crossroads_round.pml

spin -search -a -m1000000 -ltl fairness_0 crossroads_round.pml