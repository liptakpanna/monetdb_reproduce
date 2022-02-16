# Code to reproduce MonetDB Segmentation Fault 

Script executing order:

create_tables.sql

create_func_proc.sql

insert_data.sql

main.sql

main.sql --> Segmentation fault:
```
Thread 30 "mserver5" received signal SIGSEGV, Segmentation fault.
	[Switching to Thread 0x7fffe3483700 (LWP 28220)]
	0x00007ffff1d6d763 in PyAPIeval (cntxt=0x5555555dfc70, mb=0x7fffc4068180, stk=0x7fffc40f2170, pci=0x7fffc40b1060, grouped=false, mapped=false) at /home/<...>/MonetDB-11.43.9/sql/backends/monet5/UDF/pyapi3/pyapi3.c:226
	226             varres = sqlfun ? sqlfun->varres : 0;
	(gdb) backtrace
	#0  0x00007ffff1d6d763 in PyAPIeval (cntxt=0x5555555dfc70, mb=0x7fffc4068180, stk=0x7fffc40f2170, pci=0x7fffc40b1060, grouped=false, mapped=false)
		at /home/<...>/MonetDB-11.43.9/sql/backends/monet5/UDF/pyapi3/pyapi3.c:226
	#1  0x00007ffff1d6d1c3 in PYAPI3PyAPIevalStd (cntxt=0x5555555dfc70, mb=0x7fffc4068180, stk=0x7fffc40f2170, pci=0x7fffc40b1060)
		at /home/<...>/MonetDB-11.43.9/sql/backends/monet5/UDF/pyapi3/pyapi3.c:95
	#2  0x00007ffff7cab01e in runMALsequence (cntxt=0x5555555dfc70, mb=0x7fffc4068180, startpc=1, stoppc=418, stk=0x7fffc40f2170, env=0x7fffc41191e0, pcicaller=0x7fffc4095410)
		at /home/<...>/MonetDB-11.43.9/monetdb5/mal/mal_interpreter.c:656
	#3  0x00007ffff7cab9eb in runMALsequence (cntxt=0x5555555dfc70, mb=0x7fffc4195b80, startpc=1, stoppc=0, stk=0x7fffc41191e0, env=0x0, pcicaller=0x0)
		at /home/<...>/MonetDB-11.43.9/monetdb5/mal/mal_interpreter.c:780
	#4  0x00007ffff7ca97d0 in runMAL (cntxt=0x5555555dfc70, mb=0x7fffc4195b80, mbcaller=0x0, env=0x0) at /home/<...>/MonetDB-11.43.9/monetdb5/mal/mal_interpreter.c:335
	#5  0x00007ffff1e5eb5e in SQLrun (c=0x5555555dfc70, m=0x7fffc4068590) at /home/<...>/MonetDB-11.43.9/sql/backends/monet5/sql_execute.c:253
	#6  0x00007ffff1e60418 in SQLengineIntern (c=0x5555555dfc70, be=0x7fffc40aa2a0) at /home/<...>/MonetDB-11.43.9/sql/backends/monet5/sql_execute.c:699
	#7  0x00007ffff1e5da81 in SQLengine (c=0x5555555dfc70) at /home/<...>/MonetDB-11.43.9/sql/backends/monet5/sql_scenario.c:1316
	#8  0x00007ffff7cca41c in runPhase (c=0x5555555dfc70, phase=4) at /home/<...>/MonetDB-11.43.9/monetdb5/mal/mal_scenario.c:451
	#9  0x00007ffff7cca58a in runScenarioBody (c=0x5555555dfc70, once=0) at /home/<...>/MonetDB-11.43.9/monetdb5/mal/mal_scenario.c:477
	#10 0x00007ffff7cca79a in runScenario (c=0x5555555dfc70, once=0) at /home/<...>/MonetDB-11.43.9/monetdb5/mal/mal_scenario.c:508
	#11 0x00007ffff7ccc71a in MSserveClient (c=0x5555555dfc70) at /home/<...>/MonetDB-11.43.9/monetdb5/mal/mal_session.c:531
	#12 0x00007ffff7ccbfc7 in MSscheduleClient (command=0x7fffc41191e0 "", challenge=0x7fffe3482b23 "wvMWIbgRo", fin=0x7fffc4119150, fout=0x7fffec003e30, protocol=PROTOCOL_9, blocksize=8190)
		at /home/<...>/MonetDB-11.43.9/monetdb5/mal/mal_session.c:388
	#13 0x00007ffff7da6660 in doChallenge (data=0x7fffec000b70) at /home/<...>/MonetDB-11.43.9/monetdb5/modules/mal/mal_mapi.c:220
	#14 0x00007ffff77ae364 in THRstarter (a=0x7fffec006330) at /home/<...>/MonetDB-11.43.9/gdk/gdk_utils.c:1638
	#15 0x00007ffff782a50b in thread_starter (arg=0x5555741bfba0) at /home/<...>/MonetDB-11.43.9/gdk/gdk_system.c:833
	#16 0x00007ffff6f74609 in start_thread (arg=<optimized out>) at pthread_create.c:477
	#17 0x00007ffff6e9b293 in clone () at ../sysdeps/unix/sysv/linux/x86_64/clone.S:95
 ```
