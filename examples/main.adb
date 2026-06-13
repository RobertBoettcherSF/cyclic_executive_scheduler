--  Example usage of Cyclic Executive Scheduler
--  
--  Copyright (c) 2026 Sternenfisch
--  
--  This example demonstrates how to use the Cyclic Executive Scheduler
--  to create and run periodic tasks.
--  
--  License: MIT (see LICENSE file)

with Cyclic_Executive; use Cyclic_Executive;
with Ada.Real_Time; use Ada.Real_Time;
with Ada.Text_IO; use Ada.Text_IO;

--  Example task procedures

--  Task 1: Blink LED (simulated)
procedure Blink_Task is
   Counter : Natural := 0;
begin
   Counter := Counter + 1;
   Put_Line("Blink Task executed (" & Natural'Image(Counter) & ")");
end Blink_Task;

--  Task 2: Sensor Read (simulated)
procedure Sensor_Task is
   Counter : Natural := 0;
begin
   Counter := Counter + 1;
   Put_Line("Sensor Task executed (" & Natural'Image(Counter) & ")");
end Sensor_Task;

--  Task 3: Data Processing (simulated)
procedure Data_Processing_Task is
   Counter : Natural := 0;
begin
   Counter := Counter + 1;
   Put_Line("Data Processing Task executed (" & Natural'Image(Counter) & ")");
end Data_Processing_Task;

procedure Main is
   --  Task configurations
   Blink_Config : Task_Config := (
      ID        => 1,
      Period    => Milliseconds(500),    -- Every 500ms
      Deadline  => Milliseconds(100),    -- Deadline 100ms
      Priority  => 1,
      Procedure => Blink_Task'Access,
      Stack_Size => 1024
   );

   Sensor_Config : Task_Config := (
      ID        => 2,
      Period    => Milliseconds(1000),   -- Every 1000ms
      Deadline  => Milliseconds(200),    -- Deadline 200ms
      Priority  => 2,
      Procedure => Sensor_Task'Access,
      Stack_Size => 2048
   );

   Processing_Config : Task_Config := (
      ID        => 3,
      Period    => Milliseconds(2000),   -- Every 2000ms
      Deadline  => Milliseconds(500),    -- Deadline 500ms
      Priority  => 3,
      Procedure => Data_Processing_Task'Access,
      Stack_Size => 4096
   );

begin
   Put_Line("Cyclic Executive Scheduler Example");
   Put_Line("====================================");

   --  Initialize the scheduler
   Initialize;

   --  Register tasks
   if not Register_Task(Blink_Config) then
      Put_Line("Failed to register Blink task");
      return;
   end if;

   if not Register_Task(Sensor_Config) then
      Put_Line("Failed to register Sensor task");
      return;
   end if;

   if not Register_Task(Processing_Config) then
      Put_Line("Failed to register Processing task");
      return;
   end if;

   Put_Line("All tasks registered. Starting scheduler...");
   Put_Line("Press Ctrl+C to stop");

   --  Start the scheduler (this is a blocking call)
   Start;

   Put_Line("Scheduler stopped. Exiting...");

exception
   when Scheduler_Not_Initialized =>
      Put_Line("Error: Scheduler not initialized");
   when Too_Many_Tasks =>
      Put_Line("Error: Too many tasks registered");
   when Duplicate_Task_ID =>
      Put_Line("Error: Duplicate task ID");
   when Scheduler_Already_Running =>
      Put_Line("Error: Scheduler already running");
   when others =>
      Put_Line("Unexpected error: " & Ada.Exceptions.Exception_Message(Ada.Exceptions.Current_Error));
end Main;
