# Codename Mainframe

You are a virus!
Infect the mainframe and control the whole Universe! MWAHAHAHA

## The project

7DRL (7 days rogue-like) project.

### The story

You control a virus roaming inside the system trying to infect the mainframe.

### The system

The system the virus is exploring is a procedurally generated tiled terrain of
connected rooms.

### The virus

The virus has an HD space, CPU speed and an embedded script.

- HD space determines how many files the virus can carry at the same time.
- CPU speed determines the clock frequency of the virus.
- Script is a unique skill the virus can use (it consumes files).

### The movement

Everything in the system is running on CPU clocks. Faster CPUs can act faster
than slower CPUs (soft turn based: when time passes the unit can act).

### The anti-malware software

Anti-malware software (AMS) roams around the system searching for the virus or
protecting some important parts (doors, scripts, files, etc).

- AMS roams in specific patterns (depending of its type).
- AMS can scan for virus (an action of its pattern) in a square region around it
(scan region should be visually appealing for the player).
- AMS can be in alert or passive state.

In case a scan detects the virus and the AMS is in passive state, it enters
active state and triggers an alert where it detected the virus.

In case a scan detects the virus and the AMS is in alert state, it annihilate
the virus (game over).

(Idea) Instead of alert/passive mode and annihilating the virus, it could slow
down the virus CPU. After some maximum it would be annihilated.

### The mainframe

The mainframe sits behind a protected door.

The virus must activate the sequence in the correct order to gain access to the
mainframe.

- (Future) Every level has a root access (mainframe is just the last one). Root
access room has files and scripts (the virus can take it), and gives the virus
access to the next security level.

### (Future) Deep web

Secret shop.

The virus can trade files for scripts or updates.

Similar locked system as root access to unlock it.

(Idea) Pay files to unlock it

### (Idea) Closed doors

Doors that separate different rooms.

On unlocking it triggers an alert for AMS.

(Idea) Virus could have to pay files to unlock it (must guarantee you can get to
the mainframe with files available. Or have a system to steal files for AMS)

### The scripts

- [ ] (Future: requires root access) Backdoor: gives direct access to root room.
