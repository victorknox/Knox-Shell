# Assignment-4 Operating Systems and Networks (IIIT Hyderabad)
# Report

# Specification 1: Syscalls
## `strace`
The `proc.h` file was modified to add a new field, `int strace_m`, to the `proc` structure. This field stores the mask that indicates which syscalls are to be traced; it is initialised to 0 by default in `freeproc()`.

Now, the `sys_trace()` syscall, when called, sets the `strace_m` field of the calling process `p` to its first argument, the mask.

All syscalls have been modified to check the corresponding bit of the `strace_m` field of the calling process and print accordingly, just before they `return`. For example, in the case of `sbrk()`, we have added
```c
if (p->strace_m & (1 << SYS_sbrk))
  printf("%d: syscall sbrk (%d) -> %d\n", p->pid, n, addr);
```

## `sigalarm` (buggy)
`sigalarm()` proceeds by first saving the frequency `n` and the handler `periodic_fn_ptr`, and then saving the trapframe of the calling process. It then acquires the lock of the process, and if its runtime is a multiple of `n`, it changes the instruction pointer of the trapframe to the pointer of the handler.

`sigreturn()`, correspondingly, restores the saved trapframe and increments the instruction pointer so it can continue where it left off.

# Specification 2: Scheduling Algorithms
## First Come First Served
If the `FCFS` macro is defined, the scheduler first makes a pass through the `proc` list to determine the runnable process with the earliest creation time. If no process is runnable, here `to_be_run` remains at its initial value 0 and the function skips all the following steps (effectively, it continues to search `proc[]` for runnable processes).

Once the process is identified, the scheduler acquires its lock and checks if it is still runnable. If it is, it runs it until it stops. At this point, it resets the `proc` field of the CPU and goes back to searching `proc[]` for runnable processes.

Additionally, we ensure that timer-interrupts (in `trap.c`) are checked for *only* when `FCFS` is not the scheduler. This is to avoid preemption.

## Lottery-Based Scheduler
This scheduler also works in a straightforward way. First, it passes over `proc[]` to find the total number of tickets assigned to all runnable processes, and then finds a random ticket in the range `[0, total_tickets)`.

Then, it finds which process this ticket belongs to in another pass over the runnable processes in `proc[]`. This is where `to_be_run` is assigned. The last part of the function, as in the other algorithms, acquires the lock, checks the state, and runs it. Since clock interrupts are checked for in this algorithm, it is preemptive.

Additionally, the `sys_settickets()` syscall has been implemented, to set the number of tickets of the calling process. The `allocproc()` function has been modified to initialise the `tickets` field of the `proc` structure to 1, and the `fork()` function to initialise the `tickets` field of `np` (the child process) from that of `p` (the parent process).

## Priority Based Scheduling 
This scheduler works on the basis of assigning priorities to each process. It runs over `proc[]` and selects the process with the highest priority. 

The `get_priority` function helps assigning a priority to a process based on the static priority, dynamic priority and niceness score as mentioned in the specifications. Ties are broken by seeing the number of times a process is scheduled, and the start time of a process. 

The `set_priority` syscall is also implemented which also resets niceness score to 5, it returns the old static priority of a process . There is also a `setpriority` user program which uses the syscall to change the priority. It can be used by calling `setpriority <priority> <pid>`.

The code in the files that constitute xv6 is
Copyright 2006-2022 Frans Kaashoek, Robert Morris, and Russ Cox.