# Cyclic Executive Scheduler

**Simple RTOS-like task scheduler for real-time embedded systems**

A lightweight, time-triggered cyclic executive scheduler implemented in Ada. This scheduler provides deterministic task execution with fixed periods, making it ideal for real-time embedded systems where predictability is crucial.

## Features

- **Time-triggered scheduling** - Tasks execute at fixed time intervals
- **Deterministic behavior** - Predictable execution patterns
- **Deadline monitoring** - Tracks and reports missed deadlines
- **Task state management** - Monitors task states (IDLE, RUNNING, COMPLETED, ERROR)
- **Priority support** - Configurable task priorities
- **SPARK verified** - Fully compatible with SPARK 2014 for formal verification
- **Lightweight** - Minimal footprint, suitable for embedded systems

## Project Structure

```
cyclic_executive_scheduler/
├── cyclic_executive.gpr      # GNAT project file (SPARK compatible)
├── LICENSE                   # MIT License
├── README.md                 # This file
└── src/
    ├── cyclic_executive.ads  # Package specification
    └── cyclic_executive.adb  # Package implementation
```

## Quick Start

### Building

```bash
# Build the project
gprbuild -P cyclic_executive.gpr
```

### SPARK Verification

```bash
# Run SPARK verification with gnatprove
gnatprove -P cyclic_executive.gpr --level=4 --timeout=0 --no-inlining --report=all --verbose
```

## Usage

### Basic Example

```ada
with Cyclic_Executive; use Cyclic_Executive;
with Ada.Real_Time; use Ada.Real_Time;

-- Define your task procedure
procedure My_Task is
begin
   -- Task implementation here
   null;
end My_Task;

-- In your main program
procedure Main is
   -- Configure a task
   My_Task_Config : Task_Config := (
      ID        => 1,
      Period    => Milliseconds(1000),  -- Execute every 1000ms
      Deadline  => Milliseconds(500),   -- Deadline is 500ms
      Priority  => 1,
      Proc      => My_Task'Access,     -- Task procedure
      Stack_Size => 2048
   );
begin
   -- Initialize the scheduler
   Initialize;

   -- Register the task
   Register_Task(My_Task_Config);

   -- Start the scheduler (blocking call)
   Start;
end Main;
```

### API Reference

#### Types

- **`Task_ID`** - Task identifier (1..16)
- **`Task_State`** - Task execution state (IDLE, RUNNING, COMPLETED, ERROR)
- **`Task_Procedure`** - Access to task procedure type
- **`Task_Config`** - Task configuration record
- **`Task_Status`** - Task status information record

#### Procedures and Functions

- **`Initialize`** - Initialize the scheduler (must be called first)
- **`Register_Task(Config : Task_Config) return Boolean`** - Register a new task
- **`Start`** - Start the scheduler main loop (blocking)
- **`Stop`** - Stop the scheduler
- **`Get_Task_Status(T_ID : Task_ID) return Task_Status`** - Get task status
- **`Is_Running return Boolean`** - Check if scheduler is running

#### Exceptions

- **`Scheduler_Not_Initialized`** - Scheduler not initialized
- **`Too_Many_Tasks`** - Maximum number of tasks exceeded (16)
- **`Duplicate_Task_ID`** - Task ID already registered
- **`Scheduler_Already_Running`** - Scheduler already running

## Configuration

### Task Configuration

```ada
type Task_Config is record
   ID          : Task_ID;        -- Unique task identifier (1..16)
   Period      : Time_Span;     -- Execution period
   Deadline    : Time_Span;     -- Relative deadline
   Priority    : Integer;       -- Task priority (higher = more important)
   Proc        : Task_Procedure; -- Task procedure to execute
   Stack_Size  : Integer;       -- Stack size in bytes
end record;
```

### Scheduler Limits

- **Maximum tasks**: 16
- **Task ID range**: 1..16
- **Stack size**: Configurable per task

## SPARK Compatibility

This project is fully compatible with SPARK 2014 and has been verified with gnatprove:

```bash
# Full verification at level 4
gnatprove -P cyclic_executive.gpr --level=4 --timeout=0 --no-inlining --report=all --verbose
```

### SPARK-Specific Notes

- All reserved keywords are avoided (e.g., `Task` → `The_Task`, `Procedure` → `Proc`)
- No use of `Time'Last` or `Time_Span'Last` (not supported with private types in SPARK)
- No `next` statements (not supported in SPARK)
- All naming conflicts resolved

## Implementation Details

### Scheduling Algorithm

The scheduler implements a **cyclic executive** algorithm:

1. Tasks are registered with fixed periods
2. The scheduler maintains a list of all tasks with their next release times
3. At each cycle, the scheduler finds the task with the earliest release time
4. If the current time has passed the release time, the task is executed
5. After execution, the task's next release time is updated by adding its period

### Timing

- Uses `Ada.Real_Time` for precise timing
- Supports millisecond precision
- Deadline monitoring with automatic detection

## License

This project is licensed under the **MIT License** - see the [LICENSE](LICENSE) file for details.

## Contributing

Contributions are welcome! Please feel free to submit issues or pull requests.

## Acknowledgments

- Inspired by classic cyclic executive scheduling algorithms
- Designed for use in safety-critical embedded systems
- Fully verified with SPARK for high-assurance applications
