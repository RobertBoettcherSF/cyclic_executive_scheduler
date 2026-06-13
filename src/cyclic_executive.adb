--  Cyclic Executive Scheduler - Simple RTOS-like task scheduler
--  
--  Copyright (c) 2026 Sternenfisch
--  
--  Implementation of the cyclic executive scheduler.
--  
--  License: MIT (see LICENSE file)

with Ada.Real_Time; use Ada.Real_Time;
with Ada.Text_IO; use Ada.Text_IO;

package body Cyclic_Executive is

   --  Internal task record
   type Internal_Task is record
      Config      : Task_Config;
      Status      : Task_Status;
      Next_Release : Time;  -- Next scheduled release time
      Is_Active   : Boolean := False;
   end record;

   --  Array to hold all registered tasks
   type Task_Array is array (Task_ID) of Internal_Task;

   --  Scheduler state type
   type Scheduler_State_Type is (UNINITIALIZED, INITIALIZED, RUNNING, STOPPED);

   --  Global scheduler state variable
   Current_State : Scheduler_State_Type := UNINITIALIZED;

   --  Array of all tasks
   Tasks : Task_Array;

   --  Current number of registered tasks
   Task_Count : Natural := 0;

   --  Flag to indicate if scheduler should stop
   Stop_Requested : Boolean := False;

   --  Flag to indicate if any tasks are registered
   Has_Registered_Tasks : Boolean := False;

   --  Initialize the cyclic executive scheduler
   procedure Initialize is
   begin
      if Current_State /= UNINITIALIZED then
         raise Scheduler_Already_Running with "Scheduler already initialized or running";
      end if;

      --  Reset all tasks
      for I in Task_ID loop
         Tasks(I).Is_Active := False;
         Tasks(I).Status.State := IDLE;
         Tasks(I).Status.Execution_Count := 0;
         Tasks(I).Status.Missed_Deadlines := 0;
      end loop;

      Task_Count := 0;
      Stop_Requested := False;
      Current_State := INITIALIZED;

      Put_Line("Cyclic Executive Scheduler initialized");
   end Initialize;

   --  Register a new task with the scheduler
   function Register_Task (Config : Task_Config) return Boolean is
   begin
      if Current_State = UNINITIALIZED then
         raise Scheduler_Not_Initialized with "Scheduler not initialized";
      end if;

      if Current_State = RUNNING then
         raise Scheduler_Already_Running with "Cannot register tasks while scheduler is running";
      end if;

      if Task_Count >= MAX_TASKS then
         raise Too_Many_Tasks with "Maximum number of tasks exceeded";
      end if;

      if Tasks(Config.ID).Is_Active then
         raise Duplicate_Task_ID with "Task ID already registered";
      end if;

      --  Register the task
      Tasks(Config.ID).Config := Config;
      Tasks(Config.ID).Is_Active := True;
      Tasks(Config.ID).Status.State := IDLE;
      Tasks(Config.ID).Status.Execution_Count := 0;
      Tasks(Config.ID).Status.Missed_Deadlines := 0;
      Tasks(Config.ID).Next_Release := Clock + Config.Period;

      Task_Count := Task_Count + 1;

      Put_Line("Task " & Task_ID'Image(Config.ID) & " registered with period " & 
                Time_Span'Image(Config.Period));

      return True;
   end Register_Task;

   --  Check if the scheduler is currently running
   function Is_Running return Boolean is
   begin
      return Current_State = RUNNING;
   end Is_Running;

   --  Get the current status of a task
   function Get_Task_Status (T_ID : Task_ID) return Task_Status is
   begin
      if Current_State = UNINITIALIZED then
         raise Scheduler_Not_Initialized with "Scheduler not initialized";
      end if;

      return Tasks(T_ID).Status;
   end Get_Task_Status;

   --  Stop the cyclic executive scheduler
   procedure Stop is
   begin
      if Current_State /= RUNNING then
         return;  -- Scheduler is not running, nothing to do
      end if;

      Stop_Requested := True;
      Put_Line("Scheduler stop requested");
   end Stop;

   --  Execute a single task
   procedure Execute_Task (The_Task : in out Internal_Task) is
      Start_Time : Time;
      End_Time : Time;
      Deadline_Missed : Boolean := False;
   begin
      Start_Time := Clock;
      The_Task.Status.State := RUNNING;
      The_Task.Status.Last_Start := Start_Time;

      --  Execute the task procedure
      begin
         The_Task.Config.Proc.all;
      exception
         when others =>
            The_Task.Status.State := ERROR;
            Put_Line("Error executing task " & Task_ID'Image(The_Task.Config.ID));
            return;
      end;

      End_Time := Clock;
      The_Task.Status.Last_End := End_Time;
      The_Task.Status.Execution_Count := The_Task.Status.Execution_Count + 1;

      --  Check if deadline was missed
      if (End_Time - Start_Time) > The_Task.Config.Deadline then
         The_Task.Status.Missed_Deadlines := The_Task.Status.Missed_Deadlines + 1;
         Deadline_Missed := True;
         Put_Line("Deadline missed for task " & Task_ID'Image(The_Task.Config.ID));
      end if;

      --  Calculate next release time
      The_Task.Next_Release := The_Task.Next_Release + The_Task.Config.Period;

      The_Task.Status.State := COMPLETED;

      if Deadline_Missed then
         The_Task.Status.State := ERROR;
      end if;
   end Execute_Task;

   --  Start the cyclic executive scheduler
   procedure Start is
      Next_Wakeup : Time;
      Current_Time : Time;
      Has_Tasks : Boolean := False;
   begin
      if Current_State /= INITIALIZED then
         raise Scheduler_Not_Initialized with "Scheduler not initialized";
      end if;

      if Current_State = RUNNING then
         raise Scheduler_Already_Running with "Scheduler already running";
      end if;

      Current_State := RUNNING;
      Stop_Requested := False;

      Put_Line("Cyclic Executive Scheduler started with " & 
                Natural'Image(Task_Count) & " tasks");

      --  Initialize next release times for all tasks
      for I in Task_ID loop
         if Tasks(I).Is_Active then
            Tasks(I).Next_Release := Clock + Tasks(I).Config.Period;
         end if;
      end loop;

      --  Main scheduler loop
      while not Stop_Requested loop
         Current_Time := Clock;

         --  Find the task with the earliest next release time
         Has_Tasks := False;
         Next_Wakeup := Current_Time;

         for I in Task_ID loop
            if Tasks(I).Is_Active then
               if not Has_Tasks or else Tasks(I).Next_Release < Next_Wakeup then
                  Next_Wakeup := Tasks(I).Next_Release;
                  Has_Tasks := True;
               end if;
            end if;
         end loop;

         --  If no tasks are scheduled, wait a bit
         if not Has_Tasks then
            delay 0.1;  -- Wait 100ms if no tasks
         elsif Current_Time < Next_Wakeup then
            --  Wait until the next task should be released
            delay until Next_Wakeup;
         end if;

         --  Execute all tasks that are due
         for I in Task_ID loop
            if Tasks(I).Is_Active and then Tasks(I).Next_Release <= Clock then
               --  Check if task is not already running (shouldn't happen in cyclic executive)
               if Tasks(I).Status.State /= RUNNING then
                  Execute_Task(The_Task => Tasks(I));
               end if;
            end if;
         end loop;
      end loop;

      Current_State := STOPPED;
      Put_Line("Cyclic Executive Scheduler stopped");
   end Start;

end Cyclic_Executive;
