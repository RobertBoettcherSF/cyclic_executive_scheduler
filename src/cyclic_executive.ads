--  Cyclic Executive Scheduler - Simple RTOS-like task scheduler
--  
--  Copyright (c) 2026 Sternenfisch
--  
--  This package provides a simple cyclic executive scheduler for real-time
--  embedded systems. It implements a time-triggered scheduling algorithm
--  where tasks are executed at fixed time intervals.
--  
--  License: MIT (see LICENSE file)

with Ada.Real_Time; use Ada.Real_Time;

package Cyclic_Executive is

   --  Maximum number of tasks that can be registered with the scheduler
   MAX_TASKS : constant := 16;

   --  Task identifier type
   type Task_ID is range 1 .. MAX_TASKS;

   --  Task state type
   type Task_State is (IDLE, RUNNING, COMPLETED, ERROR);

   --  Task procedure type - the actual task function
   type Task_Procedure is access procedure;

   --  Task configuration record
   type Task_Config is record
      ID          : Task_ID;
      Period      : Time_Span;       -- Execution period in milliseconds
      Deadline    : Time_Span;       -- Relative deadline
      Priority    : Integer;         -- Task priority (higher = more important)
      Proc        : Task_Procedure;  -- Task function to execute
      Stack_Size  : Integer;         -- Stack size in bytes
   end record;

   --  Task status record
   type Task_Status is record
      State       : Task_State;
      Last_Start  : Time;
      Last_End    : Time;
      Execution_Count : Natural;
      Missed_Deadlines : Natural;
   end record;

   --  Initialize the cyclic executive scheduler
   --  Must be called before any other scheduler operations
   procedure Initialize;

   --  Register a new task with the scheduler
   --  
   --  Parameters:
   --    Config - Task configuration
   --  
   --  Returns:
   --    True if task was successfully registered, False otherwise
   function Register_Task (Config : Task_Config) return Boolean;

   --  Start the cyclic executive scheduler
   --  This is a blocking call that runs the scheduler main loop
   procedure Start;

   --  Stop the cyclic executive scheduler
   procedure Stop;

   --  Get the current status of a task
   --  
   --  Parameters:
   --    Task_ID - The task identifier
   --  
   --  Returns:
   --    The current status of the specified task
   function Get_Task_Status (Task_ID : Task_ID) return Task_Status;

   --  Check if the scheduler is currently running
   --  
   --  Returns:
   --    True if scheduler is running, False otherwise
   function Is_Running return Boolean;

   --  Exception raised when scheduler operations are attempted
   --  when the scheduler is not initialized
   Scheduler_Not_Initialized : exception;

   --  Exception raised when maximum number of tasks is exceeded
   Too_Many_Tasks : exception;

   --  Exception raised when attempting to register a duplicate task ID
   Duplicate_Task_ID : exception;

   --  Exception raised when scheduler is already running
   Scheduler_Already_Running : exception;

end Cyclic_Executive;
