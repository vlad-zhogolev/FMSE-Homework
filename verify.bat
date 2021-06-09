spin -search -a -m1000000 -ltl safety_0_1 crossroads_round.pml
spin -search -a -m1000000 -ltl safety_0_2 crossroads_round.pml
spin -search -a -m1000000 -ltl safety_0_3 crossroads_round.pml
spin -search -a -m1000000 -ltl safety_1_3 crossroads_round.pml
spin -search -a -m1000000 -ltl safety_2_3 crossroads_round.pml
spin -search -a -m1000000 -ltl safety_2_4 crossroads_round.pml
spin -search -a -m1000000 -ltl safety_2_5 crossroads_round.pml
spin -search -a -m1000000 -ltl safety_3_5 crossroads_round.pml
spin -search -a -m1000000 -ltl safety_4_5 crossroads_round.pml

@REM spin -search -a -m1000000 -ltl liveness_0 crossroads_round.pml

spin -search -a -b -m1000000 -w27 -DMA=197 -DNOREDUCE -ltl liveness_0 crossroads_round.pml
spin -search -a -b -m1000000 -w27 -DMA=197 -DNOREDUCE -ltl liveness_1 crossroads_round.pml
spin -search -a -b -m1000000 -w27 -DMA=197 -DNOREDUCE -ltl liveness_2 crossroads_round.pml
spin -search -a -b -m1000000 -w27 -DMA=197 -DNOREDUCE -ltl liveness_3 crossroads_round.pml
spin -search -a -b -m1000000 -w27 -DMA=197 -DNOREDUCE -ltl liveness_4 crossroads_round.pml
spin -search -a -b -m1000000 -w27 -DMA=197 -DNOREDUCE -ltl liveness_5 crossroads_round.pml


spin -search -a -b -m1000000 -w27 -DCOLLAPSE -ltl fairness_0 crossroads_round.pml
spin -search -a -b -m1000000 -w27 -DCOLLAPSE -ltl fairness_1 crossroads_round.pml
spin -search -a -b -m1000000 -w27 -DCOLLAPSE -ltl fairness_2 crossroads_round.pml
spin -search -a -b -m1000000 -w27 -DCOLLAPSE -ltl fairness_3 crossroads_round.pml
spin -search -a -b -m1000000 -w27 -DCOLLAPSE -ltl fairness_4 crossroads_round.pml
spin -search -a -b -m1000000 -w27 -DCOLLAPSE -ltl fairness_5 crossroads_round.pml