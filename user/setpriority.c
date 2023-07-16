#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"

int main(int argc, char *argv[])
{
  if (argc != 3)
  {
    printf("setpriority(): failed, correct usage: setpriority <priority> <pid>\n");
    exit(1);
  }

  int priority = atoi(argv[1]);
  int pid = atoi(argv[2]);

  set_priority(priority, pid);

  printf("set priority of %d to %d", pid, priority);
  exit(0);  
}