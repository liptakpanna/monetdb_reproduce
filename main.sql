-- STEP 1
call update_lookup(1,-2,-1,5);

-- STEP 2
select use_lookup(id1, id2, 1, -2, -1) from (
        select distinct s.id id1, x.id id2 from seq_data s, seq_data x where s.id < x.id
) as tmp;